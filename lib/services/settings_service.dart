import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../core/theme/AppTheme.dart';

class SettingsService {
  static const String _appThemeKey = 'appTheme';
  static const String _themeModeKey = 'themeMode';
  static const String _localeKey = 'locale';
  static const String _deviceTypeOverrideKey = 'deviceTypeOverride';
  static const String _countryKey = 'country';
  static const String _selectedEndpointKey = 'selectedEndpoint';

  Future<void> saveAppTheme(AppThemeEnum theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, theme.name);
  }

  Future<AppThemeEnum> loadAppTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_appThemeKey);
    return AppThemeEnum.values.firstWhere(
          (e) => e.name == themeName,
      orElse: () => AppThemeEnum.main_theme,
    );
  }

  Future<void> saveThemeModeOption(ThemeModeOptionEnum mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<ThemeModeOptionEnum> loadThemeModeOption() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_themeModeKey);
    return ThemeModeOptionEnum.values.firstWhere(
          (e) => e.name == modeName,
      orElse: () => ThemeModeOptionEnum.auto,
    );
  }

  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.toLanguageTag());
  }

  Future<Locale> loadLocale() async {
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

  Future<void> saveDeviceTypeOverride(DeviceTypeOverride deviceTypeOverride) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTypeOverrideKey, deviceTypeOverride.name);
  }

  Future<DeviceTypeOverride> loadDeviceTypeOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceTypeOverrideName = prefs.getString(_deviceTypeOverrideKey);
    return DeviceTypeOverride.values.firstWhere(
          (e) => e.name == deviceTypeOverrideName,
      orElse: () => DeviceTypeOverride.auto,
    );
  }

  Future<void> saveCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, country);
  }

  Future<String> loadCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_countryKey) ?? 'USA';
  }

  /// Save the selected endpoint name into preferences.
  Future<void> saveSelectedEndpointName(String endpointName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedEndpointKey, endpointName);
  }

  /// Load the saved endpoint name, or null if not saved.
  Future<String?> loadSelectedEndpointName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedEndpointKey);
  }
}
