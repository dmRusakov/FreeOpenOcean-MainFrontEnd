import 'package:flutter/foundation.dart';
import 'package:free_open_ocean/services/app.dart';
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart' as status_pb;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import '../models/endpoint.dart';

class Api {
  static const String statusGetPath = '/status.v1.Status/Get';

  static final List<Endpoint> endpoints = [
    Endpoint(id: 'foo-central-1', country: 'USA', httpHost: 'http://localhost', httpPort: 8081, grpcHost: '10.0.2.2', grpcPort: 50051),
    Endpoint(id: 'foo-central-2', country: 'USA', httpHost: 'http://localhost', httpPort: 8082, grpcHost: '10.0.2.2', grpcPort: 50052),
  ];

  late Endpoint? selectedEndpoint = null;

  final App? app;
  final Duration retryInterval;

  // Get fasts endpoint
  //
  // Returns the endpoint that responds OK and have lowest duration
  Future<Endpoint?>getFastestEndpoint(List<Endpoint> endpoints, {Duration timeout = const Duration(seconds: 5)}) async {
    Endpoint? fastest;
    for (final ep in endpoints) {
      final isOk = await checkEndpoint(ep, timeout: timeout);
      if (isOk) {
        if (fastest == null || ep.durations < fastest.durations) {
          fastest = ep;
        }
      }
    }
    return fastest;
  }

  // Check endpoint
  // Checks if the given endpoint is reachable by making a status request. Updates the endpoint's info if successful.
  //
  // Returns true if endpoint is reachable and updates its info (id, name, loads, appKey) from the response
  Future<bool> checkEndpoint(Endpoint ep, {Duration timeout = const Duration(seconds: 5)}) async {
    // load sessionId
    final sessionId = await app!.getSessionId();

    // make request
    final request = status_pb.GetRequest();

    // grpc
    ep.isGrpc = !kIsWeb;

    // start time
    final startTime = DateTime.now();

    try {
      if (ep.isGrpc) {
        final channel = ClientChannel(
          ep.grpcHost,
          port: ep.grpcPort,
          options: ChannelOptions(credentials: ChannelCredentials.insecure()),
        );

        try {
          final client = StatusClient(channel);
          final request = status_pb.GetRequest();
          final response = await client.get(request, options: CallOptions(metadata: {
            'X-App-Session': sessionId,
            'X-App-Key': ep.appKey,
          })).timeout(timeout);

          ep.id = response.id.toString();
          ep.name = response.name.toString();
          ep.loads = int.tryParse(response.loads.toString()) ?? 0;
          ep.appKey = response.key.toString();
          ep.durations = DateTime.now().difference(startTime);

          return true;
        } catch (_) {
          return false;
        } finally {
          await channel.shutdown();
        }
      } else {
        // make URL
        final url = Uri.parse('${ep.httpHost}:${ep.httpPort}$statusGetPath');

        // get data from server
        final responseData = await http.post(
          url,
          headers: {
            'Content-Type': 'application/x-protobuf',
            'X-App-Session': sessionId,
            'X-App-Key': ep.appKey,
          },
          body: request.writeToBuffer(),
        ).timeout(const Duration(seconds: 20));

        // check status code
        if (responseData.statusCode == 200) {
          final response = status_pb.GetResponse()..mergeFromBuffer(responseData.bodyBytes);
          ep.id = response.id.toString();
          ep.name = response.name.toString();
          ep.loads = int.tryParse(response.loads.toString()) ?? 0;
          ep.appKey = response.key.toString();

          return true;
        } else {
          return false;
        }
      }
    } catch (_) {
      return false;
    }
  }

  // Constructor
  Api({this.app, this.retryInterval = const Duration(seconds: 20)}) {
    Future(() async {
      var sessionEndpointId = await app?.getEndpointId();
      late Endpoint? ep = null;

      // if sessionEndpointId is not null, try to find matching endpoint and check it
      if (sessionEndpointId != null) {
        ep = endpoints.firstWhere((e) => e.id == sessionEndpointId, orElse: () => endpoints.first);
        final isOk = await checkEndpoint(ep);
        if (!isOk) {
          ep = null;
        }
        await app?.setEndpoint(ep);
        selectedEndpoint = ep;
      }

      // if no valid session endpoint, check all endpoints and print results
      if (ep == null) {
        ep = await getFastestEndpoint(endpoints);
        await app?.setEndpoint(ep);
        selectedEndpoint = ep;
      }

      // make cron job getFastestEndpoint every 15 minutes to update selected endpoint if needed
      Future.doWhile(() async {
        await Future.delayed(const Duration(minutes: 15));
        final fastest = await getFastestEndpoint(endpoints);
        if (fastest != null && fastest.id != selectedEndpoint?.id) {
          selectedEndpoint = fastest;
          await app?.setEndpoint(selectedEndpoint);
        }
        return true; // continue the loop
      });
    });
  }
}
