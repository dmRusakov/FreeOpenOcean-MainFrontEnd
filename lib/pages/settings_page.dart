import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart' as theme_interface;
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';

class SettingsPage extends StatelessWidget {
  final Map<String, String>? params;

  const SettingsPage({super.key, this.params});

  @override
  Widget build(BuildContext context) {
    final themeProvider = theme_interface.AppThemeProvider.of(context)!;
    return PageTemplate(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            theme_interface.AppThemeProvider.buildAppThemeDropdown(context, themeProvider.appTheme, themeProvider.onAppThemeChanged),
            theme_interface.AppThemeProvider.buildThemeModeDropdown(context, themeProvider.themeMode, themeProvider.onThemeModeChanged),
            AppLocalizations.buildLanguageDropdown(context, themeProvider.locale, (locale) => themeProvider.onLocaleChanged(locale, true)),
            AppLocalizations.buildCountryDropdown(context, themeProvider.country, themeProvider.onCountryChanged),
            theme_interface.AppThemeProvider.buildDeviceTypeOverrideDropdown(context, themeProvider.deviceTypeOverride, themeProvider.onDeviceTypeOverrideChanged),
          ],
        ),
      ),
    );
  }
}
