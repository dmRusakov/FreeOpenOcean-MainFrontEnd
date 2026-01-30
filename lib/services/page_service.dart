import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pbgrpc.dart' show PageServiceClient;
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pb.dart' as pages_pb;
import 'package:free_open_ocean/services/api.dart';

class PageService {
  static const String pageGetPath = '/pages.v1.PageService/Get';

  final Api api;

  PageService(this.api);

  /// Get page data by slug, with required language and country.
  Future<pages_pb.Page> get(String slug, String language, String country) async {
    final request = pages_pb.GetRequest()
      ..slug = slug;

    final ep = api.selectedEndpoint;
    if (ep == null) {
      throw Exception('No endpoint available');
    }

    try {
      if (kIsWeb) {
        final url = Uri.parse('http://${ep.httpHost}:${ep.httpPort}$pageGetPath');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toProto3Json()),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final pageResponse = pages_pb.Page()..mergeFromProto3Json(data);
          return pageResponse;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } else {
        final channel = ClientChannel(
          ep.grpcHost,
          port: ep.grpcPort,
          options: ChannelOptions(credentials: ChannelCredentials.insecure()),
        );

        try {
          final client = PageServiceClient(channel);
          final response = await client.get(request).timeout(const Duration(seconds: 10));
          return response;
        } finally {
          await channel.shutdown();
        }
      }
    } catch (e) {
      throw Exception('Failed to get page data: $e');
    }
  }
}
