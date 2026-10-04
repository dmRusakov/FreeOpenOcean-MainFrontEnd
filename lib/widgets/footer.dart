import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'page_width.dart';

import 'package:free_open_ocean/common/element/app_button.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/provider/app_provider.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.getTheme('footer');
    final localizations = AppLocalizations.of(context)!;
    final app = AppProvider.of(context)?.app;
    final themeProvider = AppThemeProvider.of(context)!;

    final surface = Theme.of(context).colorScheme.surface;

    return Container(
      height: theme.sizes['height'],
      // Same trick as the header: a scrim rather than a bar, so the chart
      // keeps running under the attribution line.
      decoration: BoxDecoration(
        color: theme.color['background'],
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            surface.withValues(alpha: 0.85),
            surface.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: PageWidth(
        child: Padding(
          padding: theme.sizes['padding'],
          child: Row(
            children: [
              if (app != null)
                ListenableBuilder(
                  listenable: app,
                  builder: (context, child) =>
                      AppProvider.buildFooterConnectionStatusIcon(context),
                )
              else
                AppProvider.buildFooterConnectionStatusIcon(context),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '@ 2024 - ${DateTime.now().year} ${localizations.translate('footer_text')} (v$_version)',
                  style: TextStyle(
                    fontSize: theme.sizes['fontSize'],
                    color: theme.color['text'],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              PointerInterceptor(
                child: AppThemeProvider.buildThemeModeDropdown(
                  context,
                  themeProvider.themeMode,
                  themeProvider.onThemeModeChanged,
                  size: 's',
                  showTextAlways: false,
                ),
              ),
              const SizedBox(width: 8),
              PointerInterceptor(
                child: AppLocalizations.buildLanguageDropdown(
                  context,
                  themeProvider.locale,
                  (locale) => themeProvider.onLocaleChanged(locale, true),
                  size: 's',
                  showTextAlways: false,
                ),
              ),
              ListenableBuilder(
                listenable: Listenable.merge([
                  topBarNotifier,
                  contentDockedRight,
                ]),
                builder: (context, _) {
                  final showDock =
                      topBarNotifier.value.ownerId != 'ocean_charts' &&
                      contentDockAvailable(
                        context,
                        MediaQuery.sizeOf(context).width,
                        fullScreen: false,
                      );
                  if (!showDock) return const SizedBox.shrink();
                  final docked = contentDockedRight.value;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PointerInterceptor(
                      child: Tooltip(
                        message: localizations.translate(
                          docked ? 'content_dock_center' : 'content_dock_right',
                        ),
                        child: AppButton(
                          onPressed: () => contentDockedRight.value = !docked,
                          icon: docked
                              ? Icons.view_column
                              : Icons.keyboard_double_arrow_right,
                          size: 's',
                          theme: 'secondary',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
