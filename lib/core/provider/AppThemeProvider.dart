import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/core/router/app_router.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/common/element/appDropdown.dart';
import '../theme/AppTheme.dart';

class AppThemeProvider extends InheritedWidget {
  final AppTheme theme;
  final DeviceTypeOverride deviceTypeOverride;
  final void Function(DeviceTypeOverride?) onDeviceTypeOverrideChanged;

  final AppThemeEnum appTheme;
  final void Function(AppThemeEnum?) onAppThemeChanged;

  final ThemeModeOptionEnum themeMode;
  final void Function(ThemeModeOptionEnum?) onThemeModeChanged;

  final Locale locale;
  final void Function(Locale?, bool) onLocaleChanged;

  final String country;
  final void Function(String?) onCountryChanged;

  final Api api;

  const AppThemeProvider({
    super.key,
    required this.theme,
    required this.deviceTypeOverride,
    required this.onDeviceTypeOverrideChanged,
    required this.appTheme,
    required this.onAppThemeChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required this.country,
    required this.onCountryChanged,
    required this.api,
    required super.child,
  });

  static AppThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeProvider>();
  }

  @override
  bool updateShouldNotify(AppThemeProvider oldWidget) {
    return theme != oldWidget.theme ||
        deviceTypeOverride != oldWidget.deviceTypeOverride ||
        appTheme != oldWidget.appTheme ||
        themeMode != oldWidget.themeMode ||
        locale != oldWidget.locale ||
        country != oldWidget.country;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DeviceTypeOverride>('deviceTypeOverride', deviceTypeOverride));
    properties.add(DiagnosticsProperty<AppThemeEnum>('appTheme', appTheme));
    properties.add(DiagnosticsProperty<ThemeModeOptionEnum>('themeMode', themeMode));
    properties.add(DiagnosticsProperty<Locale>('locale', locale));
    properties.add(DiagnosticsProperty<String>('country', country));
  }

  static Widget buildAppThemeDropdown(BuildContext context, AppThemeEnum currentTheme, void Function(AppThemeEnum?) onChanged, {String color = 'secondary', String size = 'm'}) {
    final localizations = AppLocalizations.of(context)!;

    return AppDropdown<AppThemeEnum>(
      text: localizations.translate(currentTheme.name),
      onPressed: () => _showAppThemeSearchDialog(context, currentTheme, onChanged),
      theme: color,
      size: size,
      showTextAlways: true,
    );
  }

  static void _showAppThemeSearchDialog(BuildContext context, AppThemeEnum currentTheme, void Function(AppThemeEnum?) onChanged) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredThemes = AppThemeEnum.values.where((theme) => theme.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: Text(localizations.translate('select_theme')),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(hintText: localizations.translate('search_theme')),
                    ),
                    Expanded(
                      child: ListView(
                        children: filteredThemes.map((theme) {
                          return ListTile(
                            title: Text(localizations.translate(theme.name)),
                            selected: theme == currentTheme,
                            onTap: () {
                              onChanged(theme);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget buildThemeModeDropdown(BuildContext context, ThemeModeOptionEnum currentMode, void Function(ThemeModeOptionEnum?) onChanged, {String color = 'secondary', String size = 'm'}) {
    final localizations = AppLocalizations.of(context)!;

    return AppDropdown<ThemeModeOptionEnum>(
      text: localizations.translate('${currentMode.name}_theme'),
      onPressed: () => _showThemeModeSearchDialog(context, currentMode, onChanged),
      theme: color,
      size: size,
      showTextAlways: true,
    );
  }

  static void _showThemeModeSearchDialog(BuildContext context, ThemeModeOptionEnum currentMode, void Function(ThemeModeOptionEnum?) onChanged) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredModes = ThemeModeOptionEnum.values.where((mode) => mode.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            return AlertDialog(
              title: Text(localizations.translate('select_theme_mode')),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(hintText: localizations.translate('search_theme_mode')),
                    ),
                    Expanded(
                      child: ListView(
                        children: filteredModes.map((mode) {
                          return ListTile(
                            title: Text(localizations.translate('${mode.name}_theme')),
                            selected: mode == currentMode,
                            onTap: () {
                              onChanged(mode);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget buildDeviceTypeOverrideDropdown(BuildContext context, DeviceTypeOverride currentOverride, void Function(DeviceTypeOverride?) onChanged, {String color = 'secondary', String size = 'm'}) {
    final localizations = AppLocalizations.of(context)!;

    return AppDropdown<DeviceTypeOverride>(
      text: localizations.translate(currentOverride.name),
      onPressed: () => _showDeviceTypeOverrideSearchDialog(context, currentOverride, onChanged),
      theme: color,
      size: size,
      showTextAlways: true,
    );
  }

  static void _showDeviceTypeOverrideSearchDialog(BuildContext context, DeviceTypeOverride currentOverride, void Function(DeviceTypeOverride?) onChanged) {
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setState) {
            final filteredOverrides = DeviceTypeOverride.values.where((override) => override.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
            final localizations = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(localizations.translate('select_device_type_override')),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(hintText: localizations.translate('search_device_type_override')),
                    ),
                    Expanded(
                      child: ListView(
                        children: filteredOverrides.map((override) {
                          return ListTile(
                            title: Text(localizations.translate(override.name)),
                            selected: override == currentOverride,
                            onTap: () {
                              onChanged(override);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

extension AppThemeExtension on BuildContext {
  DeviceType getDeviceType() {
    final provider = AppThemeProvider.of(this);
    if (provider == null) {
      final width = MediaQuery.of(this).size.width;
      if (width >= 1920) return DeviceType.tv;
      if (width >= 1200) return DeviceType.desktop;
      if (width >= 600) return DeviceType.tablet;
      return DeviceType.mobile;
    }

    final override = provider.deviceTypeOverride;
    if (override != DeviceTypeOverride.auto) {
      switch (override) {
        case DeviceTypeOverride.mobile:
          return DeviceType.mobile;
        case DeviceTypeOverride.tablet:
          return DeviceType.tablet;
        case DeviceTypeOverride.desktop:
          return DeviceType.desktop;
        case DeviceTypeOverride.tv:
          return DeviceType.tv;
        case DeviceTypeOverride.auto:
          break;
      }
    }

    final width = MediaQuery.of(this).size.width;
    if (width >= 1920) return DeviceType.tv;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  ThemeValues getTheme(String key) {
    final provider = AppThemeProvider.of(this);
    if (provider == null) {
      return const ThemeValues(color: <String, dynamic>{}, sizes: <String, dynamic>{});
    }
    final brightness = Theme.of(this).brightness;
    final deviceType = getDeviceType();
    final sizeSet = provider.theme.getSizesForDevice(deviceType);

    return ThemeValues(
      color: provider.theme.getColor(key, brightness) ?? <String, dynamic>{},
      sizes: sizeSet[key] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  dynamic getThemeColor(String key) {
    final provider = AppThemeProvider.of(this);
    if (provider == null) return null;
    final brightness = Theme.of(this).brightness;
    return provider.theme.getColor(key, brightness);
  }

  dynamic getThemeSizes(String key) {
    final provider = AppThemeProvider.of(this);
    if (provider == null) return null;
    final deviceType = getDeviceType();
    final sizeSet = provider.theme.getSizesForDevice(deviceType);
    return sizeSet[key];
  }

  void routerGoTo(String pageName) {
    AppRouter.goTo(this, pageName);
  }
}
