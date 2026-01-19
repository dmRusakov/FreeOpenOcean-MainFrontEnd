import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pbgrpc.dart' show StatusClient;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart' show GetRequest;

class StatusInfo {
  final bool ok;
  final String serverName;
  final String message;

  const StatusInfo({required this.ok, this.serverName = '', this.message = ''});
}

class Api {
  static const String statusGetPath = '/status.v1.Status/Get';

  /// Fetch status. Returns [StatusInfo]:
  /// - ok: true when backend returned success
  /// - serverName: parsed name from response if available
  /// - message: human readable message or error
  Future<StatusInfo> getStatus() async {
    try {
      if (kIsWeb) {
        final url = Uri.parse('http://localhost:8081$statusGetPath');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        );

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            final id = data['id']?.toString() ?? '';
            final name = data['name']?.toString() ?? '';
            final loads = data['loads']?.toString() ?? '';
            final message = 'ID: $id, Name: $name, Loads: $loads%';
            return StatusInfo(ok: true, serverName: name, message: message);
          } catch (e) {
            return StatusInfo(ok: true, serverName: '', message: response.body);
          }
        } else {
          return StatusInfo(ok: false, serverName: '', message: 'HTTP ${response.statusCode}');
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
        try {
          final client = StatusClient(channel);
          final request = GetRequest();
          final response = await client.get(request);
          final message = 'ID: ${response.id}, Name: ${response.name}, Loads: ${response.loads}%';
          return StatusInfo(ok: true, serverName: response.name ?? '', message: message);
        } finally {
          await channel.shutdown();
        }
      }
    } catch (e) {
      return StatusInfo(ok: false, serverName: '', message: e.toString());
    }
  }
}
