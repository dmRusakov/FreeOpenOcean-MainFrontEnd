import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_open_ocean/config/config.dart';

void main() {
  test('release never silently targets localhost', () {
    expect(
      Config.buildEndpoints(
        httpUrls: '',
        grpcUrls: '',
        isWeb: true,
        isRelease: true,
        platform: TargetPlatform.android,
      ),
      isEmpty,
    );
    expect(
      Config.buildEndpoints(
        httpUrls: '',
        grpcUrls: '',
        isWeb: false,
        isRelease: true,
        platform: TargetPlatform.iOS,
      ),
      isEmpty,
    );
  });
  test('development hosts distinguish Android emulator and desktop', () {
    final android = Config.buildEndpoints(
      httpUrls: '',
      grpcUrls: '',
      isWeb: false,
      isRelease: false,
      platform: TargetPlatform.android,
    );
    final desktop = Config.buildEndpoints(
      httpUrls: '',
      grpcUrls: '',
      isWeb: false,
      isRelease: false,
      platform: TargetPlatform.macOS,
    );
    expect(android.first.grpcHost, '10.0.2.2');
    expect(desktop.first.grpcHost, 'localhost');
  });
  test('HTTPS base path, explicit ports and TLS settings survive parsing', () {
    final endpoints = Config.buildEndpoints(
      httpUrls:
          'https://api.example.com:8443/backend/,https://other.example.com',
      grpcUrls: 'grpcs://native.example.com:7443,grpcs://other.example.com',
      isWeb: true,
      isRelease: true,
      platform: TargetPlatform.macOS,
    );
    expect(
      endpoints.first.httpStatusUri('/pages.v1.PageService/Get').toString(),
      'https://api.example.com:8443/backend/pages.v1.PageService/Get',
    );
    expect(endpoints.first.grpcSecure, isTrue);
    expect(endpoints.first.grpcPort, 7443);
    expect(endpoints.last.httpPort, 443);
    expect(endpoints.last.grpcPort, 443);
  });
  test('invalid or credential-bearing URLs are rejected', () {
    expect(
      () => Config.buildEndpoints(
        httpUrls: 'https://user:password@example.com',
        grpcUrls: '',
        isWeb: true,
        isRelease: true,
        platform: TargetPlatform.macOS,
      ),
      throwsFormatException,
    );
    expect(
      () => Config.buildEndpoints(
        httpUrls: '',
        grpcUrls: 'https://example.com',
        isWeb: false,
        isRelease: true,
        platform: TargetPlatform.macOS,
      ),
      throwsFormatException,
    );
  });
}
