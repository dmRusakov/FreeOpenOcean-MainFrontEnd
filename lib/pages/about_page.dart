import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:free_open_ocean/common/element/app_button.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/pages/markdown_content_page.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/services/api.dart';

const _aboutBannerUrl =
    'https://images.freeopenocean.com/about/ship-cbb05d59cd4d.webp';

enum AboutSection { about, mapSectors }

class AboutPage extends StatefulWidget {
  final Map<String, String>? params;

  const AboutPage({super.key, this.params});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  AboutSection _selectedSection = AboutSection.about;

  void _readSection() {
    _selectedSection = widget.params?['section'] == 'map_sectors'
        ? AboutSection.mapSectors
        : AboutSection.about;
  }

  @override
  void initState() {
    super.initState();
    _readSection();
  }

  @override
  void didUpdateWidget(AboutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readSection();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTopBar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTopBar());
  }

  @override
  void dispose() {
    clearTopBar(ownerId: 'about');
    super.dispose();
  }

  void _selectSection(AboutSection section) {
    final currentUri = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri;
    final query = Map<String, String>.from(currentUri.queryParameters);
    if (section == AboutSection.about) {
      query.remove('section');
    } else {
      query['section'] = 'map_sectors';
    }
    GoRouter.of(context).go(currentUri.replace(queryParameters: query).toString());
    setState(() => _selectedSection = section);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTopBar());
  }

  void _updateTopBar() {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    setTopBar(
      title: localizations.translate('about'),
      ownerId: 'about',
      submenu: [
        AppButton(
          icon: Icons.info_outline,
          size: 's',
          text: localizations.translate('about'),
          onPressed: () => _selectSection(AboutSection.about),
          theme: _selectedSection == AboutSection.about ? 'secondary' : 'info',
          showTextOnBigScreen: true,
        ),
        const SizedBox(width: 8),
        AppButton(
          icon: Icons.grid_on,
          size: 's',
          text: localizations.translate('map_sectors'),
          onPressed: () => _selectSection(AboutSection.mapSectors),
          theme: _selectedSection == AboutSection.mapSectors
              ? 'secondary'
              : 'info',
          showTextOnBigScreen: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = AppThemeProvider.of(context)!.connectionMode;
    final bannerFirst = _selectedSection == AboutSection.about &&
        mode != ConnectionMode.silent &&
        mode != ConnectionMode.disable;
    return PageTemplate(
      // The banner is the first element, so it fills the panel: no space
      // on the sides or above it. Text keeps the usual side inset.
      contentHorizontalPadding: bannerFirst ? 0 : null,
      contentTopPadding: bannerFirst ? 0 : null,
      body: _selectedSection == AboutSection.about
          ? MarkdownContentPage(
              slug: 'about',
              params: widget.params,
              embed: true,
              bannerUrl: _aboutBannerUrl,
              insetContent: true,
            )
          : _mapSectors(),
    );
  }

  Widget _mapSectors() {
    final localizations = AppLocalizations.of(context)!;
    final textColor =
        context.getThemeColor('text') as Color? ??
        Theme.of(context).colorScheme.onSurface;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.translate('map_sectors'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localizations.translate('map_sectors_lead'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          SvgPicture.asset(
            'assets/maps/map-sectors.svg',
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
