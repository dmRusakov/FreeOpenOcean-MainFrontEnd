import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:free_open_ocean/services/app.dart';
import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/models/endpoint.dart';
import 'package:free_open_ocean/models/connection_exception.dart';
// The contracts package only exposes generated files.
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart'
    as status;

Endpoint endpoint() => Endpoint(
  id: 'test',
  grpcHost: 'localhost',
  grpcPort: 50051,
  httpHost: 'http://localhost',
  httpPort: 8081,
  country: 'USA',
);
http.Response healthy() => http.Response.bytes(
  status.GetResponse(id: 'server', name: 'Server', key: 'key').writeToBuffer(),
  200,
);

class TrackedClient extends MockClient {
  bool closed = false;
  TrackedClient(super.handler);
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late App app;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    app = App();
  });
  tearDown(() => app.dispose());

  test('cold startup waits and resolves all endpoint consumers', () async {
    final first = app.getEndpoint();
    final second = app.getEndpoint();
    final ep = endpoint();
    await app.setEndpoint(ep);
    expect(await first, same(ep));
    expect(await second, same(ep));
    expect(await app.getEndpoint(), same(ep));
  });
  test('endpoint wait is bounded', () async {
    await expectLater(
      app.getEndpoint(timeout: const Duration(milliseconds: 5)),
      throwsA(isA<ConnectionUnavailable>()),
    );
  });
  test(
    'offline discovery fails pending waits and later recovery resolves new waits',
    () async {
      final failed = expectLater(
        app.getEndpoint(),
        throwsA(isA<ConnectionUnavailable>()),
      );
      await app.setConnectionStatus(ConnectionStatus.offline);
      await failed;
      await app.setConnectionStatus(ConnectionStatus.connecting);
      final pending = app.getEndpoint();
      final ep = endpoint();
      await app.setEndpoint(ep);
      expect(await pending, same(ep));
    },
  );
  test(
    'disabling clears a cached endpoint and fails pending/future requests',
    () async {
      final pending = expectLater(
        app.getEndpoint(),
        throwsA(isA<ConnectionUnavailable>()),
      );
      await app.setConnectionMode(ConnectionMode.disable);
      await pending;
      expect(app.endpoint, isNull);
      await expectLater(
        app.getEndpoint(),
        throwsA(isA<ConnectionUnavailable>()),
      );
    },
  );
  test('parallel requests share one persisted session', () async {
    final ids = await Future.wait(List.generate(8, (_) => app.getSessionId()));
    expect(ids.toSet(), hasLength(1));
    expect(
      (await SharedPreferences.getInstance()).getString('sessionId'),
      ids.first,
    );
  });
  test('disabled startup and explicit probes send no HTTP requests', () async {
    await app.setConnectionMode(ConnectionMode.disable);
    var calls = 0;
    final api = Api(
      app: app,
      endpoints: [endpoint()],
      useHttp: true,
      clientFactory: () => MockClient((_) async {
        calls++;
        return healthy();
      }),
    );
    addTearDown(api.dispose);
    await api.refresh();
    expect(await api.checkEndpoint(endpoint()), isFalse);
    expect(await api.getFastestEndpoint([endpoint()]), isNull);
    await expectLater(
      api.post(endpoint(), '/page', []),
      throwsA(isA<ConnectionUnavailable>()),
    );
    expect(calls, 0);
  });
  test('failed discovery becomes offline; explicit retry recovers', () async {
    var online = false;
    final api = Api(
      app: app,
      endpoints: [endpoint()],
      useHttp: true,
      autoStart: false,
      clientFactory: () =>
          MockClient((_) async => online ? healthy() : http.Response('', 503)),
    );
    addTearDown(api.dispose);
    await api.refresh();
    expect(app.connectionStatus, ConnectionStatus.offline);
    expect(app.endpoint, isNull);
    online = true;
    await api.refresh();
    expect(app.connectionStatus, ConnectionStatus.online);
    expect(app.endpoint?.id, 'server');
  });
  test('HTTP probes obey their deadline and close the transport', () async {
    final client = TrackedClient((_) => Completer<http.Response>().future);
    final api = Api(
      app: app,
      endpoints: [endpoint()],
      useHttp: true,
      autoStart: false,
      clientFactory: () => client,
      probeTimeout: const Duration(milliseconds: 5),
    );
    addTearDown(api.dispose);
    await api.refresh().timeout(const Duration(seconds: 1));
    expect(app.connectionStatus, ConnectionStatus.offline);
    expect(client.closed, isTrue);
  });
  test(
    'disable cancels active transport and rejects its late response',
    () async {
      final response = Completer<http.Response>();
      final sent = Completer<void>();
      final client = TrackedClient((_) {
        sent.complete();
        return response.future;
      });
      final api = Api(
        app: app,
        endpoints: [endpoint()],
        useHttp: true,
        autoStart: false,
        clientFactory: () => client,
      );
      addTearDown(api.dispose);
      final discovery = api.refresh();
      await sent.future;
      await app.setConnectionMode(ConnectionMode.disable);
      expect(client.closed, isTrue);
      response.complete(healthy());
      await discovery;
      expect(app.endpoint, isNull);
      expect(app.connectionStatus, ConnectionStatus.offline);
    },
  );
  test('reenabling immediately restarts discovery', () async {
    await app.setConnectionMode(ConnectionMode.disable);
    var calls = 0;
    final api = Api(
      app: app,
      endpoints: [endpoint()],
      useHttp: true,
      clientFactory: () => MockClient((_) async {
        calls++;
        return healthy();
      }),
    );
    addTearDown(api.dispose);
    await app.setConnectionMode(ConnectionMode.normal);
    await api.refresh();
    expect(calls, 1);
    expect(app.connectionStatus, ConnectionStatus.online);
  });
  testWidgets('offline retry timer recovers without restarting the app', (
    tester,
  ) async {
    var online = false;
    final api = Api(
      app: app,
      endpoints: [endpoint()],
      useHttp: true,
      autoStart: false,
      retryInterval: const Duration(seconds: 2),
      clientFactory: () =>
          MockClient((_) async => online ? healthy() : http.Response('', 503)),
    );
    addTearDown(api.dispose);
    final first = api.refresh();
    await tester.pump();
    await first;
    expect(app.connectionStatus, ConnectionStatus.offline);
    online = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(app.connectionStatus, ConnectionStatus.online);
    api.dispose();
  });
  test(
    'page and probe requests use the saved session and selected app key',
    () async {
      await app.setSessionId('saved-session');
      http.Request? captured;
      final api = Api(
        app: app,
        endpoints: [],
        useHttp: true,
        autoStart: false,
        clientFactory: () => MockClient((request) async {
          captured = request;
          return healthy();
        }),
      );
      addTearDown(api.dispose);
      final ep = endpoint()..appKey = 'selected-key';
      await api.post(ep, '/page', [1, 2]);
      expect(captured!.headers['X-App-Session'], 'saved-session');
      expect(captured!.headers['X-App-Key'], 'selected-key');
    },
  );
}
