import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart' as theme_interface;
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:free_open_ocean/common/element/appButon.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:free_open_ocean/services/page_service.dart';
import 'dart:convert';

enum SettingSection { general, theme, language, style }

class SettingsPage extends StatefulWidget {
  final Map<String, String>? params;

  const SettingsPage({super.key, this.params});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingSection _selectedSection = SettingSection.general;

  @override
  void initState() {
    super.initState();
    if (widget.params != null && widget.params!.containsKey('section')) {
      String section = widget.params!['section']!;
      switch (section) {
        case 'general':
          _selectedSection = SettingSection.general;
          break;
        case 'theme':
          _selectedSection = SettingSection.theme;
          break;
        case 'language':
          _selectedSection = SettingSection.language;
          break;
        case 'style':
          _selectedSection = SettingSection.style;
          break;
        default:
          _selectedSection = SettingSection.general;
      }
    }
  }

  void _selectSection(SettingSection section) {
    final currentUri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
    final newUri = currentUri.replace(queryParameters: {'section': section.name});
    GoRouter.of(context).go(newUri.toString());
    setState(() => _selectedSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = theme_interface.AppThemeProvider.of(context)!;
    if (kIsWeb) {
      final localizations = AppLocalizations.of(context)!;
      html.document.title = localizations.translate('settings_page_title');
      html.document.head?.querySelectorAll('meta[name="description"]').forEach((element) => element.remove());
      var meta = html.MetaElement()
        ..name = 'description'
        ..content = localizations.translate('settings_page_description');
      html.document.head?.append(meta);
    }
    return PageTemplate(
      body: Column(
        children: [
          // Horizontal sub-menu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.settings),
                    const SizedBox(width: 8.0),
                    Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    AppButton(
                      icon: Icons.settings,
                      text: 'General',
                      onPressed: () => _selectSection(SettingSection.general),
                      theme: _selectedSection == SettingSection.general ? 'primary' : 'secondary',
                      showTextOnBigScreen: true,
                    ),
                    const SizedBox(width: 8.0),
                    AppButton(
                      icon: Icons.palette,
                      text: 'Theme',
                      onPressed: () => _selectSection(SettingSection.theme),
                      theme: _selectedSection == SettingSection.theme ? 'primary' : 'secondary',
                      showTextOnBigScreen: true,
                    ),
                    const SizedBox(width: 8.0),
                    AppButton(
                      icon: Icons.language,
                      text: 'Language',
                      onPressed: () => _selectSection(SettingSection.language),
                      theme: _selectedSection == SettingSection.language ? 'primary' : 'secondary',
                      showTextOnBigScreen: true,
                    ),
                    const SizedBox(width: 8.0),
                    AppButton(
                      icon: Icons.text_fields,
                      text: 'Style Guide',
                      onPressed: () => _selectSection(SettingSection.style),
                      theme: _selectedSection == SettingSection.style ? 'primary' : 'secondary',
                      showTextOnBigScreen: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildSectionContent(themeProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(theme_interface.AppThemeProvider themeProvider) {
    final localizations = AppLocalizations.of(context)!;
    switch (_selectedSection) {

    // general settings
      case SettingSection.general:
        return const Text('General settings placeholder');

    // theme settings
      case SettingSection.theme:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.translate('app_theme_label'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 16),
                theme_interface.AppThemeProvider.buildAppThemeDropdown(context, themeProvider.appTheme, themeProvider.onAppThemeChanged),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.translate('theme_mode_label'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 16),
                theme_interface.AppThemeProvider.buildThemeModeDropdown(context, themeProvider.themeMode, themeProvider.onThemeModeChanged),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.translate('device_type_override_label'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 16),
                theme_interface.AppThemeProvider.buildDeviceTypeOverrideDropdown(context, themeProvider.deviceTypeOverride, themeProvider.onDeviceTypeOverrideChanged),
              ],
            ),
          ],
        );

    // language settings
      case SettingSection.language:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.translate('language_label'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 16),
                AppLocalizations.buildLanguageDropdown(context, themeProvider.locale, (locale) => themeProvider.onLocaleChanged(locale, true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.translate('country_label'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 16),
                AppLocalizations.buildCountryDropdown(context, themeProvider.country, themeProvider.onCountryChanged),
              ],
            ),
          ],
        );

    // typography
      case SettingSection.style:
        return FutureBuilder(
          future: PageService(themeProvider.api).get('style-guide', themeProvider.locale.languageCode, themeProvider.country),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final page = snapshot.data!;

              // test seo title and description of the page by page.seoTitle and page.seoDescription
              if (kIsWeb) {
                html.document.title = page.seoTitle ?? page.title;
                html.document.head?.querySelectorAll('meta[name="description"]').forEach((element) => element.remove());
                var meta = html.MetaElement()
                  ..name = 'description'
                  ..content = page.seoDescription ?? 'Description for ${page.title}';
                html.document.head?.append(meta);
              }

              return SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(page.title, style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 20),
                        Html(
                          data: page.content,
                          style: {
                            "p": Style(textAlign: TextAlign.justify),
                            "li": Style(textAlign: TextAlign.justify),
                            "div": Style(textAlign: TextAlign.justify),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return const Text('No data');
            }
          },
        );
    }
  }
}
