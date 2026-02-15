import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../core/theme/AppTheme.dart';
import 'package:uuid/uuid.dart';
import '../models/endpoint.dart';

enum ConnectionMode {
  disabled,
  connected,
  offline,
  silent,
  normal,
  unlimited,
}

class App {
  static const String _appThemeKey = 'appTheme';
  static const String _themeModeKey = 'themeMode';
  static const String _localeKey = 'locale';
  static const String _deviceTypeOverrideKey = 'deviceTypeOverride';
  static const String _countryKey = 'country';
  static const String _sessionIdKey = 'sessionId';
  static const String _endpointIdKey = 'endpointId';
  static const String _connectionModeKey = 'connectionMode';
  late Endpoint? endpoint;

  // theme
  Future<void> setTheme(AppThemeEnum theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, theme.name);
  }

  Future<AppThemeEnum> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_appThemeKey);
    return AppThemeEnum.values.firstWhere(
          (e) => e.name == themeName,
      orElse: () => AppThemeEnum.main_theme,
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

  Future<String> getSessionId() async {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointIdKey, ep?.id ?? '');
    endpoint = ep;
  }

  Future<Endpoint?> getEndpoint() async {
    return endpoint;
  }

  // connection mode
  Future<void> setConnectionMode(ConnectionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectionModeKey, mode.name);
  }

  Future<ConnectionMode> getConnectionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_connectionModeKey);
    return ConnectionMode.values.firstWhere(
          (e) => e.name == modeName,
      orElse: () => ConnectionMode.normal,
    );
  }
}
