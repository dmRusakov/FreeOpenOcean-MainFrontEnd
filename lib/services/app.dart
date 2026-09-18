import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:async';
import '../core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import '../models/endpoint.dart';
import 'api.dart';
import '../models/connection_exception.dart';

class App extends ChangeNotifier {
  static const String _appThemeKey = 'appTheme';
  static const String _themeModeKey = 'themeMode';
  static const String _localeKey = 'locale';
  static const String _deviceTypeOverrideKey = 'deviceTypeOverride';
  static const String _countryKey = 'country';
  static const String _sessionIdKey = 'sessionId';
  static const String _endpointIdKey = 'endpointId';
  static const String _connectionModeKey = 'connectionMode';
  Endpoint? endpoint;
  late ConnectionStatus connectionStatus = ConnectionStatus.connecting;
  // Default to `normal` so on first run (or when preference missing) app uses normal mode.
  late ConnectionMode connectionMode = ConnectionMode.normal;
  Completer<Endpoint>? _endpointCompleter;
  final StreamController<Map<String, dynamic>> _connectionController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get connectionStream =>
      _connectionController.stream;

  // theme
  Future<void> setTheme(AppThemeEnum theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, theme.storageKey);
  }

  Future<AppThemeEnum> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_appThemeKey);
    return AppThemeEnum.values.firstWhere(
      (e) => e.storageKey == themeName,
      orElse: () => AppThemeEnum.mainTheme,
    );
  }

  // theme mode (color scheme)
  Future<void> setThemeMode(ThemeModeOptionEnum mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<ThemeModeOptionEnum> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_themeModeKey);
    return ThemeModeOptionEnum.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeModeOptionEnum.auto,
    );
  }

  // locale (language)
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.toLanguageTag());
  }

  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageTag = prefs.getString(_localeKey);
    if (languageTag != null && languageTag.isNotEmpty) {
      final parts = languageTag.split('-');
      if (parts.length > 1) {
        return Locale(parts[0], parts[1]);
      } else {
        return Locale(parts[0], '');
      }
    }
    return const Locale('en', '');
  }

  // device type
  Future<void> setDevice(DeviceTypeOverride deviceTypeOverride) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTypeOverrideKey, deviceTypeOverride.name);
  }

  Future<DeviceTypeOverride> getDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceTypeOverrideName = prefs.getString(_deviceTypeOverrideKey);
    return DeviceTypeOverride.values.firstWhere(
      (e) => e.name == deviceTypeOverrideName,
      orElse: () => DeviceTypeOverride.auto,
    );
  }

  // country
  Future<void> setCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, country);
  }

  Future<String> getCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_countryKey) ?? 'USA';
  }

  // session ID
  Future<void> setSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
  }

  Future<String>? _sessionIdFuture;

  Future<String> getSessionId() => _sessionIdFuture ??= _loadSessionId();

  Future<String> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_sessionIdKey);
    if (sessionId != null && sessionId.isNotEmpty) {
      return sessionId;
    } else {
      final uuid = Uuid();
      final newSessionId = uuid.v4();
      await setSessionId(newSessionId);
      return newSessionId;
    }
  }

  // endpoint ID
  Future<void> setEndpointId(String? endpointId) async {
    final prefs = await SharedPreferences.getInstance();
    if (endpointId != null) {
      await prefs.setString(_endpointIdKey, endpointId);
    } else {
      await prefs.remove(_endpointIdKey);
    }
  }

  Future<String?> getEndpointId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_endpointIdKey);
  }

  // Endpoint
  Future<void> setEndpoint(Endpoint? ep) async {
    endpoint = ep;
    if (ep != null) {
      final pending = _endpointCompleter;
      _endpointCompleter = null;
      if (pending != null && !pending.isCompleted) pending.complete(ep);
    }
    notifyListeners();
    await setEndpointId(ep?.id);
  }

  Future<Endpoint> getEndpoint({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (connectionMode == ConnectionMode.disable) {
      throw const ConnectionUnavailable('Backend connection is disabled.');
    }
    if (endpoint != null) return endpoint!;
    if (connectionStatus == ConnectionStatus.offline) {
      throw const ConnectionUnavailable();
    }
    _endpointCompleter ??= Completer<Endpoint>();
    return _endpointCompleter!.future.timeout(
      timeout,
      onTimeout: () =>
          throw const ConnectionUnavailable('Connection timed out.'),
    );
  }

  void _failEndpointWaiters() {
    final pending = _endpointCompleter;
    _endpointCompleter = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const ConnectionUnavailable());
    }
  }

  @override
  void dispose() {
    _failEndpointWaiters();
    _connectionController.close();
    super.dispose();
  }

  // connection mode
  Future<void> setConnectionMode(ConnectionMode mode) async {
    connectionMode = mode;
    if (mode == ConnectionMode.disable) {
      endpoint = null;
      connectionStatus = ConnectionStatus.offline;
      _failEndpointWaiters();
    }
    notifyListeners();
    _connectionController.add({
      'status': connectionStatus.name,
      'mode': connectionMode.name,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectionModeKey, mode.name);
  }

  Future<ConnectionMode> getConnectionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_connectionModeKey);
    connectionMode = ConnectionMode.values.firstWhere(
      (e) => e.name == modeName,
      // default to normal if nothing was saved previously
      orElse: () => ConnectionMode.normal,
    );
    _connectionController.add({
      'status': connectionStatus.name,
      'mode': connectionMode.name,
    });
    return connectionMode;
  }

  // connection status
  Future<void> setConnectionStatus(ConnectionStatus status) async {
    connectionStatus = status;
    if (status == ConnectionStatus.offline) {
      endpoint = null;
      _failEndpointWaiters();
    }
    notifyListeners();
    _connectionController.add({
      'status': connectionStatus.name,
      'mode': connectionMode.name,
    });
  }

  Future<ConnectionStatus> getConnectionStatus() async {
    return connectionStatus;
  }
}
