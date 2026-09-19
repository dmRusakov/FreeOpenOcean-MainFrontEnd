import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:universal_html/html.dart' as html;

import 'package:free_open_ocean/content/about_temp_content.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/pages/page_template.dart';

class AboutPage extends StatefulWidget {
  final Map<String, String>? params;

  const AboutPage({super.key, this.params});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _ownerId = 'about_page';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;
      setTopBar(
        title: localizations.translate('about'),
        ownerId: _ownerId,
        submenu: [],
      );
      _applySeo();
    });
  }

  void _applySeo() {
    if (!kIsWeb) return;
    html.document.title = AboutTempContent.seoTitle;
    html.document.head
        ?.querySelectorAll('meta[name="description"]')
        .forEach((element) => element.remove());
    html.document.head?.append(
      html.MetaElement()
        ..name = 'description'
        ..content = AboutTempContent.seoDescription,
    );
  }

  @override
  void dispose() {
    clearTopBar(ownerId: _ownerId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = AppThemeProvider.of(context)!;
    final maxWidth = themeProvider.theme.maxWidth;
    final textTheme = Theme.of(context).textTheme;
    final textColor =
        context.getThemeColor('text') as Color? ??
        Theme.of(context).colorScheme.onSurface;

    return PageTemplate(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AboutTempContent.title,
              style: textTheme.headlineLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth * 0.5),
              child: Text(
                AboutTempContent.shortDescription,
                style: textTheme.bodySmall?.copyWith(color: textColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Html(
              data: AboutTempContent.html,
              style: {
                ...themeProvider.theme.pageStyles,
                'body': Style(color: textColor),
                'p': Style(color: textColor, textAlign: TextAlign.justify),
                'li': Style(color: textColor, textAlign: TextAlign.justify),
                'h2': Style(
                  color: textColor,
                  margin: Margins.only(top: 28, bottom: 10),
                ),
                'h3': Style(
                  color: textColor,
                  margin: Margins.only(top: 18, bottom: 8),
                ),
                'img': Style(
                  width: Width(100, Unit.percent),
                  margin: Margins.symmetric(vertical: 16),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
