import 'dart:convert';

import 'package:free_open_ocean/widgets/selectable_web_article.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:universal_html/html.dart' as html;

import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/services/markdown_page_cache.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/pages/page_template.dart';

/// Cloudflare Images variant for a 16:4 banner. Width is the box in device
/// pixels, rounded up to 64 so nearby layouts share one cached file.
String imageVariantUrl(
  String url,
  double logicalWidth,
  double devicePixelRatio,
) {
  if (!logicalWidth.isFinite || logicalWidth <= 0) return url;
  final ratio = devicePixelRatio.isFinite && devicePixelRatio > 0
      ? devicePixelRatio
      : 1.0;
  var width = (logicalWidth * ratio / 64).ceil() * 64;
  if (width < 64) width = 64;
  if (width > 1920) width = 1920;
  final uri = Uri.parse(url);
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'w': '$width',
          'h': '${width ~/ 4}',
          'f': 'auto',
        },
      )
      .toString();
}

class MarkdownContentPage extends StatefulWidget {
  final String slug;
  final Map<String, String>? params;

  /// When true, this page is the body of another screen. It does not set the
  /// header or wrap itself in the page shell.
  final bool embed;

  /// Wide image shown above the title. Omitted on a low-data connection.
  final String? bannerUrl;

  /// Pad the text when the page panel itself has no side padding, so a
  /// banner can run to the panel edges.
  final bool insetContent;

  const MarkdownContentPage({
    super.key,
    required this.slug,
    this.params,
    this.embed = false,
    this.bannerUrl,
    this.insetContent = false,
  });

  @override
  State<MarkdownContentPage> createState() => _MarkdownContentPageState();
}

class _MarkdownContentPageState extends State<MarkdownContentPage> {
  String get _ownerId => '${widget.slug}_page';
  final _pageCache = MarkdownPageCache();
  MarkdownPage? _page;
  String? _language;
  bool? _lowData;
  bool _loadFailed = false;

  Future<void> _loadPage(String language) async {
    final mode = AppThemeProvider.of(context)!.connectionMode;
    final lowData =
        mode == ConnectionMode.silent || mode == ConnectionMode.disable;
    try {
      final page = await _pageCache.load(
        widget.slug,
        language,
        lowData: lowData,
      );
      if (!mounted || _language != language) return;
      setState(() => _page = page);
      _applySeo();
    } catch (_) {
      if (!mounted || _language != language) return;
      setState(() => _loadFailed = true);
    }
  }

  void _updateHeader() {
    if (!mounted) return;
    if (!widget.embed) {
      final localizations = AppLocalizations.of(context)!;
      setTopBar(
        title: localizations.translate(widget.slug),
        ownerId: _ownerId,
        submenu: [],
      );
    }
    _applySeo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = AppThemeProvider.of(context)!;
    final language = theme.locale.languageCode;
    final lowData =
        theme.connectionMode == ConnectionMode.silent ||
        theme.connectionMode == ConnectionMode.disable;
    if (_language != language || _lowData != lowData) {
      _language = language;
      _lowData = lowData;
      _page = null;
      _loadFailed = false;
      _loadPage(language);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateHeader();
    });
  }

  void _applySeo() {
    if (!kIsWeb || _page == null) return;
    final page = _page!;
    final seo = page.seo;
    html.document.title = page.seoTitle;
    html.document.documentElement?.setAttribute('lang', _language!);
    html.document.head
        ?.querySelectorAll(
          '[data-page-seo], meta[name="description"], meta[name="robots"], '
          'meta[property^="og:"], meta[name^="twitter:"], link[rel="canonical"], '
          'link[rel="alternate"], script[type="application/ld+json"]',
        )
        .forEach((element) => element.remove());
    void meta(String name, String value, {bool property = false}) {
      final element = html.MetaElement()..content = value;
      element.setAttribute(property ? 'property' : 'name', name);
      element.setAttribute('data-page-seo', 'true');
      html.document.head?.append(element);
    }

    void link(String rel, String href, {String? language, String? type}) {
      final element = html.LinkElement()
        ..rel = rel
        ..href = href;
      element.setAttribute('data-page-seo', 'true');
      if (language != null) element.setAttribute('hreflang', language);
      if (type != null) element.type = type;
      html.document.head?.append(element);
    }

    meta('description', page.seoDescription);
    meta('robots', seo['robots'] as String? ?? 'index, follow');
    meta('og:type', 'website', property: true);
    meta('og:title', page.seoTitle, property: true);
    meta('og:description', page.seoDescription, property: true);
    meta('twitter:card', seo['twitterCard'] as String? ?? 'summary');
    meta('twitter:title', page.seoTitle);
    meta('twitter:description', page.seoDescription);
    for (final entry in {
      'canonicalUrl': 'og:url',
      'siteName': 'og:site_name',
      'socialImage': 'og:image',
      'socialImageAlt': 'og:image:alt',
    }.entries) {
      if (seo[entry.key] is String) {
        meta(entry.value, seo[entry.key], property: true);
      }
    }
    if (seo['socialImage'] is String) meta('twitter:image', seo['socialImage']);
    if (seo['canonicalUrl'] is String) link('canonical', seo['canonicalUrl']);
    if (seo['markdownUrl'] is String) {
      link('alternate', seo['markdownUrl'], type: 'text/markdown');
    }
    final alternatives = seo['alternateLanguages'];
    if (alternatives is Map) {
      for (final entry in alternatives.entries) {
        link('alternate', entry.value as String, language: entry.key as String);
      }
      if (alternatives['en'] is String) {
        link('alternate', alternatives['en'], language: 'x-default');
      }
    }
    final structured = html.ScriptElement()
      ..type = 'application/ld+json'
      ..text = jsonEncode({
        '@context': 'https://schema.org',
        '@type': seo['schemaType'] ?? 'MarkdownContentPage',
        'name': page.title,
        'description': page.seoDescription,
        'url': seo['canonicalUrl'],
        'inLanguage': _language,
      });
    structured.setAttribute('data-page-seo', 'true');
    html.document.head?.append(structured);
  }

  @override
  void dispose() {
    if (kIsWeb) {
      html.document.head
          ?.querySelectorAll('[data-page-seo]')
          .forEach((element) => element.remove());
    }
    if (!widget.embed) clearTopBar(ownerId: _ownerId);
    super.dispose();
  }

  Widget _banner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 16 / 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final url = imageVariantUrl(
                widget.bannerUrl!,
                constraints.maxWidth,
                MediaQuery.devicePixelRatioOf(context),
              );
              return Image.network(
                url,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                semanticLabel: _page!.title,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = AppThemeProvider.of(context)!;
    final maxWidth = themeProvider.theme.maxWidth;
    final textTheme = Theme.of(context).textTheme;
    final textColor =
        context.getThemeColor('text') as Color? ??
        Theme.of(context).colorScheme.onSurface;
    final bannerFirst = widget.bannerUrl != null && _lowData != true;
    final sideInset = widget.insetContent
        ? (context.getThemeSizes('pageLayout')['contentHorizontalPadding']
                  as double? ??
              30.0)
        : 0.0;

    final content = _page == null
        ? Center(
            child: _loadFailed
                ? TextButton(
                    onPressed: () {
                      setState(() => _loadFailed = false);
                      _loadPage(_language!);
                    },
                    child: const Text('Unable to load page. Retry'),
                  )
                : const CircularProgressIndicator(),
          )
        : ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              primary: true,
              padding: EdgeInsets.only(top: bannerFirst ? 0 : 20, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.bannerUrl != null && _lowData != true) _banner(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _page!.title,
                          style: textTheme.headlineLarge?.copyWith(
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth * 0.5),
                          child: Text(
                            _page!.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Html(
                          data: _page!.html,
                          onLinkTap: (url, attributes, element) {
                            if (url == null) return;
                            if (url.startsWith('mailto:')) {
                              if (kIsWeb) {
                                html.window.location.href = url;
                              }
                            } else if (url.startsWith('http://') ||
                                url.startsWith('https://')) {
                              if (kIsWeb) {
                                html.window.open(url, '_blank');
                              }
                            } else if (url.startsWith('/')) {
                              final route = url.replaceFirst(RegExp(r'^/'), '');
                              context.routerGoTo(route);
                            } else {
                              context.routerGoTo(url);
                            }
                          },
                          style: {
                            ...themeProvider.theme.pageStyles,
                            'body': Style(
                              color: textColor,
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            'p': Style(
                              color: textColor,
                              textAlign: TextAlign.justify,
                            ),
                            'li': Style(
                              color: textColor,
                              textAlign: TextAlign.justify,
                            ),
                            'h2': Style(
                              color: textColor,
                              margin: Margins.only(top: 28, bottom: 10),
                            ),
                            'h3': Style(
                              color: textColor,
                              margin: Margins.only(top: 18, bottom: 8),
                            ),
                            'a': Style(
                              color: Theme.of(context).colorScheme.primary,
                              textDecoration: TextDecoration.none,
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
                ],
              ),
            ),
          );
    final Widget selectableContent;
    if (kIsWeb && _page != null) {
      selectableContent = LayoutBuilder(
        builder: (context, constraints) {
          return SelectableWebArticle(
            title: _page!.title,
            description: _page!.description,
            body: _page!.html,
            language: _language!,
            color: textColor,
            linkColor: Theme.of(context).colorScheme.primary,
            inset: sideInset,
            bannerUrl: bannerFirst
                ? imageVariantUrl(
                    widget.bannerUrl!,
                    constraints.maxWidth,
                    MediaQuery.devicePixelRatioOf(context),
                  )
                : null,
            onNavigate: (url) =>
                context.routerGoTo(url.replaceFirst(RegExp(r'^/'), '')),
          );
        },
      );
    } else {
      selectableContent = SelectionArea(child: content);
    }
    if (widget.embed) return selectableContent;
    return PageTemplate(body: selectableContent);
  }
}
