import 'package:flutter/foundation.dart';
import '../models/endpoint.dart';

class Config {
  static const apiKey = String.fromEnvironment(
    'MAP_API_KEY',
    defaultValue: '42f6ab2492a77fae',
  );
  static const _httpUrls = String.fromEnvironment('API_HTTP_URLS');
  static const _grpcUrls = String.fromEnvironment('API_GRPC_URLS');

  static List<Endpoint> get endpoints => buildEndpoints(
    httpUrls: _httpUrls,
    grpcUrls: _grpcUrls,
    isWeb: kIsWeb,
    isRelease: kReleaseMode,
    platform: defaultTargetPlatform,
  );

  /// Release builds have no implicit development backend. Supply matching,
  /// comma-separated HTTP(S) and grpc(s) URLs through --dart-define.
  static List<Endpoint> buildEndpoints({
    required String httpUrls,
    required String grpcUrls,
    required bool isWeb,
    required bool isRelease,
    required TargetPlatform platform,
  }) {
    List<String> split(String value) => value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final http = split(httpUrls);
    final grpc = split(grpcUrls);
    if (http.isEmpty && grpc.isEmpty && !isRelease) {
      final host = !isWeb && platform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';
      http.addAll(['http://$host:8082', 'http://$host:8081']);
      grpc.addAll(['grpc://$host:50061', 'grpc://$host:50051']);
    }
    final selected = isWeb ? http : grpc;
    return List.generate(selected.length, (i) {
      final httpUri = i < http.length ? Uri.parse(http[i]) : null;
      final grpcUri = i < grpc.length ? Uri.parse(grpc[i]) : null;
      if (httpUri != null &&
          (!['http', 'https'].contains(httpUri.scheme) ||
              httpUri.host.isEmpty ||
              httpUri.userInfo.isNotEmpty ||
              httpUri.hasQuery ||
              httpUri.hasFragment)) {
        throw const FormatException(
          'API_HTTP_URLS must contain HTTP(S) URLs without credentials, queries or fragments.',
        );
      }
      if (grpcUri != null &&
          (!['grpc', 'grpcs'].contains(grpcUri.scheme) ||
              grpcUri.host.isEmpty ||
              grpcUri.userInfo.isNotEmpty ||
              (grpcUri.path.isNotEmpty && grpcUri.path != '/') ||
              grpcUri.hasQuery ||
              grpcUri.hasFragment)) {
        throw const FormatException(
          'API_GRPC_URLS must contain grpc(s)://host:port URLs.',
        );
      }
      return Endpoint(
        id: 'configured-$i',
        country: 'USA',
        httpHost: httpUri?.toString() ?? '',
        httpPort: httpUri?.port ?? 443,
        grpcHost: grpcUri?.host ?? '',
        grpcPort: grpcUri == null
            ? 443
            : grpcUri.hasPort
            ? grpcUri.port
            : grpcUri.scheme == 'grpcs'
            ? 443
            : 50051,
        grpcSecure: grpcUri?.scheme == 'grpcs',
      );
    });
  }
}
