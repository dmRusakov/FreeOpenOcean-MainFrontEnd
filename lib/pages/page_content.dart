import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_html/flutter_html.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart' as theme_interface;
import 'package:free_open_ocean/services/page_service.dart';

class PageContent extends StatelessWidget {
  final String slug;
  final String? language;
  final String? country;

  const PageContent({
    super.key,
    required this.slug,
    this.language,
    this.country,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = theme_interface.AppThemeProvider.of(context)!;
    final lang = language ?? themeProvider.locale.languageCode;
    final cnt = country ?? themeProvider.country;

    return FutureBuilder(
      future: PageService(themeProvider.api).get(slug, lang, cnt),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final page = snapshot.data!;

          print(page.shortDescription);

          // Make content visible for Google checks, bots, and analytics
          if (kIsWeb) {
            var hiddenDiv = html.DivElement()
              ..innerHtml = page.content
              ..style.display = 'none';
            html.document.body?.append(hiddenDiv);
          }

          // Set SEO title and description
          if (kIsWeb) {
            html.document.title = page.seoTitle ?? page.title;
            html.document.head?.querySelectorAll('meta[name="description"]').forEach((element) => element.remove());
            var meta = html.MetaElement()
              ..name = 'description'
              ..content = page.seoDescription ?? 'Description for ${page.title}';
            html.document.head?.append(meta);
          }

          final maxWidth = 1000.0;

          List<Widget> content = [
            const SizedBox(height: 10),
          ];

          // add title and short description if available
          if (page.title != '') {
            content.add(Text(page.title, style: Theme.of(context).textTheme.headlineLarge));

            if (page.shortDescription != '') {
              content.add(const SizedBox(height: 10));
              content.add(Container(
                constraints: BoxConstraints(maxWidth: maxWidth * 0.50),
                child: Text(page.shortDescription, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              ));
            }

            content.add(const SizedBox(height: 30));
          }

          // add content
          content.add(Html(
            data: page.content,
            style: {
              "p": Style(textAlign: TextAlign.justify),
              "li": Style(textAlign: TextAlign.justify),
              "div": Style(textAlign: TextAlign.justify),
            },
          ));

          return SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: content,
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
