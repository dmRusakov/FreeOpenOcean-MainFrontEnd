import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/common/element/app_button.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:go_router/go_router.dart';
import 'package:free_open_ocean/core/provider/app_provider.dart';
import '../widgets/typography_content.dart';
import 'map_settings_section.dart';

enum SettingSection { general, style, map }

class SettingsPage extends StatefulWidget {
  final Map<String, String>? params;

  const SettingsPage({super.key, this.params});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingSection _selectedSection = SettingSection.general;

  void _readSection() {
    _selectedSection = switch (widget.params?['section']) {
      'style' => SettingSection.style,
      'map' => SettingSection.map,
      _ => SettingSection.general,
    };
  }

  @override
  void initState() {
    super.initState();
    _readSection();
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readSection();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTopBar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule top bar update after the first frame so localization delegates are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTopBar());
  }

  @override
  void dispose() {
    clearTopBar(ownerId: 'settings');
    super.dispose();
  }

  void _selectSection(SettingSection section) {
    final currentUri = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri;
    final newUri = currentUri.replace(
      queryParameters: {...currentUri.queryParameters, 'section': section.name},
    );
    GoRouter.of(context).go(newUri.toString());
    setState(() => _selectedSection = section);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTopBar());
  }

  void _updateTopBar() {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    setTopBar(
      title: localizations.translate('settings'),
      ownerId: 'settings',
      submenu: [
        AppButton(
          icon: Icons.settings,
          size: 's',
          text: localizations.translate('general'),
          onPressed: () => _selectSection(SettingSection.general),
          theme: _selectedSection == SettingSection.general
              ? 'secondary'
              : 'info',
          showTextOnBigScreen: true,
        ),
        const SizedBox(width: 8.0),
        AppButton(
          icon: Icons.map_outlined,
          size: 's',
          text: localizations.translate('map_chart'),
          onPressed: () => _selectSection(SettingSection.map),
          theme: _selectedSection == SettingSection.map ? 'secondary' : 'info',
          showTextOnBigScreen: true,
        ),
        const SizedBox(width: 8.0),
        AppButton(
          icon: Icons.text_fields,
          size: 's',
          text: localizations.translate('style_guide'),
          onPressed: () => _selectSection(SettingSection.style),
          theme: _selectedSection == SettingSection.style
              ? 'secondary'
              : 'info',
          showTextOnBigScreen: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = AppThemeProvider.of(context)!;
    if (kIsWeb) {
      final localizations = AppLocalizations.of(context)!;
      html.document.title = localizations.translate('settings_page_title');
      html.document.head
          ?.querySelectorAll('meta[name="description"]')
          .forEach((element) => element.remove());
      var meta = html.MetaElement()
        ..name = 'description'
        ..content = localizations.translate('settings_page_description');
      html.document.head?.append(meta);
    }
    return PageTemplate(
      body: Column(
        children: [
          // Content area — top bar (title + submenu) is rendered in the header now via setTopBar
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

  Widget _settingsColumn(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _prose(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _sectionHeading(String text, IconData icon) {
    final style = Theme.of(context).textTheme.headlineMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(icon, size: 28, color: style?.color),
            const SizedBox(width: 10),
            Text(text, style: style),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }

  Widget _buildSectionContent(AppThemeProvider themeProvider) {
    final localizations = AppLocalizations.of(context)!;
    switch (_selectedSection) {
      case SettingSection.general:
        return _settingsColumn([
          Text(
            localizations.translate('general'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          _sectionHeading(
            localizations.translate('connection_heading'),
            Icons.cloud_outlined,
          ),
          _prose(localizations.translate('connection_lead')),
          const SizedBox(height: 24),
          _settingRow(
            localizations.translate('connection_mode'),
            AppProvider.buildConnectionModeDropdown(
              context,
              themeProvider.connectionMode,
              themeProvider.onConnectionModeChanged,
              showTextAlways: true,
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeading(localizations.translate('theme'), Icons.palette_outlined),
          _prose(localizations.translate('appearance_lead')),
          const SizedBox(height: 24),
          _settingRow(
            localizations.translate('app_theme_label'),
            AppThemeProvider.buildAppThemeDropdown(
              context,
              themeProvider.appTheme,
              themeProvider.onAppThemeChanged,
            ),
          ),
          _settingRow(
            localizations.translate('theme_mode_label'),
            AppThemeProvider.buildThemeModeDropdown(
              context,
              themeProvider.themeMode,
              themeProvider.onThemeModeChanged,
            ),
          ),
          _settingRow(
            localizations.translate('device_type_override_label'),
            AppThemeProvider.buildDeviceTypeOverrideDropdown(
              context,
              themeProvider.deviceTypeOverride,
              themeProvider.onDeviceTypeOverrideChanged,
            ),
          ),
          const SizedBox(height: 20),
          _sectionHeading(localizations.translate('language'), Icons.language),
          _prose(localizations.translate('appearance_language')),
          const SizedBox(height: 24),
          _settingRow(
            localizations.translate('language_label'),
            AppLocalizations.buildLanguageDropdown(
              context,
              themeProvider.locale,
              (locale) => themeProvider.onLocaleChanged(locale, true),
            ),
          ),
          _settingRow(
            localizations.translate('country_label'),
            AppLocalizations.buildCountryDropdown(
              context,
              themeProvider.country,
              themeProvider.onCountryChanged,
            ),
          ),
        ]);

      // typography
      case SettingSection.map:
        return const MapSettingsSection();
      case SettingSection.style:
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: const SingleChildScrollView(
            primary: true,
            child: TypographyContent(),
          ),
        );
    }
  }
}
