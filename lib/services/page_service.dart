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

  /// Convert HTTP JSON response to proto3 JSON format
  Map<String, dynamic> _convertHttpJsonToProto3Json(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // Convert snake_case to camelCase
      final camelKey = _snakeToCamel(key);

      if (value is Map<String, dynamic> && value.containsKey('seconds') && value.containsKey('nanos')) {
        // Convert timestamp object to ISO string
        final seconds = value['seconds'] as int;
        final nanos = value['nanos'] as int;
        final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + nanos ~/ 1000000);
        converted[camelKey] = '${dateTime.toIso8601String()}Z';
      } else {
        converted[camelKey] = value;
      }
    }

    return converted;
  }

  /// Convert snake_case to camelCase
  String _snakeToCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length == 1) return snake;
    return parts[0] + parts.sublist(1).map((part) => part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : part).join('');
  }

  /// Get page data by slug, with required language and country.
  Future<pages_pb.Page> get(String slug, String language, String country) async {
    final request = pages_pb.GetRequest()
      ..slug = slug
      ..countryCode = country
      ..languageCode = language;

    Endpoint? ep = api.selectedEndpoint;
    if (ep == null) {
      await api.discoverBestEndpoint(force: true);
      ep = api.selectedEndpoint;
    }
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
          final convertedData = _convertHttpJsonToProto3Json(data);
          final pageResponse = pages_pb.Page()..mergeFromProto3Json(convertedData);
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
