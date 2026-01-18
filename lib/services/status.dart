import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pbgrpc.dart' show StatusClient;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart' show GetRequest;

class StatusService {
  static const String statusGetPath = '/status.v1.Status/Get';

  /// Fetch status and return a user-friendly summary string.
  /// Uses HTTP JSON for web (kIsWeb) and gRPC for native (Android/Linux/macOS/etc).
  Future<String> getStatus() async {
    try {
      if (kIsWeb) {
        final url = Uri.parse('http://localhost:8081$statusGetPath');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final id = data['id'];
          final name = data['name'];
          final loads = data['loads'];
          return 'ID: $id, Name: $name, Loads: $loads%';
        } else {
          return 'Error: HTTP ${response.statusCode}';
        }
      } else {
        // native platforms use gRPC
        final host = '10.0.2.2';
        final port = 50051;
        final channel = ClientChannel(
          host,
          port: port,
          options: ChannelOptions(credentials: ChannelCredentials.insecure()),
        );
        final client = StatusClient(channel);
        final request = GetRequest();
        final response = await client.get(request);
        await channel.shutdown();
        return 'ID: ${response.id}, Name: ${response.name}, Loads: ${response.loads}%';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
