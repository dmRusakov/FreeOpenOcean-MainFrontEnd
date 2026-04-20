import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_html/flutter_html.dart';
import 'package:free_open_ocean/core/provider/AppThemeProvider.dart';
import 'package:free_open_ocean/services/page_service.dart';
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pb.dart' as pages_pb;
import 'package:free_open_ocean/pages/page_template.dart' show setTopBar, clearTopBar;

class PageContent extends StatefulWidget {
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
  State<PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<PageContent> {
  pages_pb.Page? _loadedPage;
  late final String _ownerId = 'page_${widget.slug}';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // load page and set top bar once
    if (_loadedPage == null) {
      final themeProvider = AppThemeProvider.of(context)!;
      final lang = widget.language ?? themeProvider.locale.languageCode;
      final cnt = widget.country ?? themeProvider.country;

      PageService(themeProvider.api).get(context, widget.slug, lang, cnt)
        .then((page) {
          if (mounted) {
            setState(() => _loadedPage = page);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setTopBar(title: page.title, ownerId: _ownerId, submenu: []);
            });
          }
        })
        .catchError((e) {
          // ignore
        });
    }
  }

  @override
  void dispose() {
    clearTopBar(ownerId: _ownerId);
    super.dispose();
  }

  List<Widget> _buildContent(pages_pb.Page page, double maxWidth, BuildContext context) {
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
      style: AppThemeProvider.of(context)!.theme.pageStyles,
    ));

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = AppThemeProvider.of(context)!;

    if (_loadedPage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final page = _loadedPage!;

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

    final maxWidth = themeProvider.theme.maxWidth;

    List<Widget> content = _buildContent(page, maxWidth, context);

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
  }
}