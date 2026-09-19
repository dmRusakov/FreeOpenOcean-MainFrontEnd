import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_open_ocean/services/app.dart';
import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/models/endpoint.dart';
// The contracts package only exposes generated files.
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pbgrpc.dart'
    as status;
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pbgrpc.dart'
    as pages;

class StatusService extends status.StatusServiceBase {
  Map<String, String>? metadata;
  @override
  Future<status.GetResponse> get(
    ServiceCall call,
    status.GetRequest request,
  ) async {
    metadata = call.clientMetadata;
    return status.GetResponse(id: 'native', key: 'native-key', name: 'Native');
  }
}

class PagesService extends pages.PageServiceBase {
  Map<String, String>? metadata;
  @override
  Future<pages.Page> get(ServiceCall call, pages.GetRequest request) async {
    metadata = call.clientMetadata;
    return pages.Page(title: 'Native page');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native gRPC discovery and page requests propagate session and key',
    () async {
      SharedPreferences.setMockInitialValues({'sessionId': 'native-session'});
      final app = App();
      final statusService = StatusService();
      final pagesService = PagesService();
      final server = Server.create(services: [statusService, pagesService]);
      await server.serve(address: '127.0.0.1', port: 0);
      final ep = Endpoint(
        id: 'local',
        grpcHost: '127.0.0.1',
        grpcPort: server.port!,
        httpHost: 'http://localhost',
        httpPort: 1,
        country: 'USA',
      );
      final api = Api(
        app: app,
        endpoints: [ep],
        useHttp: false,
        autoStart: false,
      );
      try {
        await api.refresh();
        expect(app.connectionStatus, ConnectionStatus.online);
        expect(statusService.metadata?['x-app-session'], 'native-session');
        final page = await api.grpc(
          ep,
          (channel, options) => pages.PageServiceClient(
            channel,
          ).get(pages.GetRequest(slug: 'style-guide'), options: options),
        );
        expect(page.title, 'Native page');
        expect(pagesService.metadata?['x-app-session'], 'native-session');
        expect(pagesService.metadata?['x-app-key'], 'native-key');
      } finally {
        api.dispose();
        await server.shutdown();
        app.dispose();
      }
    },
  );
}
