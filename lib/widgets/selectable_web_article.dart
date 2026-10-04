import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

/// A visible DOM article: browser selection, keyboard navigation and readable
/// content remain available after Flutter has painted its surrounding shell.
class SelectableWebArticle extends StatefulWidget {
  const SelectableWebArticle({
    super.key,
    required this.title,
    required this.description,
    required this.body,
    required this.language,
    required this.color,
    required this.linkColor,
    required this.inset,
    required this.onNavigate,
    this.bannerUrl,
  });

  final String title, description, body, language;
  final Color color, linkColor;
  final double inset;
  final String? bannerUrl;
  final ValueChanged<String> onNavigate;

  @override
  State<SelectableWebArticle> createState() => _SelectableWebArticleState();
}

class _SelectableWebArticleState extends State<SelectableWebArticle> {
  html.Element? _element;
  StreamSubscription<html.MouseEvent>? _clicks;
  String _cssColor(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  void _render() {
    final root = _element;
    if (root == null) return;
    const escape = HtmlEscape();
    root.setAttribute('lang', widget.language);
    root.setAttribute('tabindex', '0');
    root.setAttribute('aria-label', widget.title);
    root.style.cssText =
        'width:100%;height:100%;overflow:auto;box-sizing:border-box;'
        'pointer-events:auto;user-select:text;-webkit-user-select:text;'
        'font-family:Arial,sans-serif;font-size:16px;line-height:1.65;'
        'color:${_cssColor(widget.color)};';
    // The default DOM sanitizer rejects script, event handlers and unsafe URLs
    // from downloaded Markdown. Never use NodeTreeSanitizer.trusted here.
    root.setInnerHtml(
      '<article class="native-page-article">'
      '${widget.bannerUrl == null ? '' : '<img class="page-banner" src="${escape.convert(widget.bannerUrl!)}" alt="">'}'
      '<div class="article-copy"><h1>${escape.convert(widget.title)}</h1>'
      '<p class="article-description">${escape.convert(widget.description)}</p>'
      '${widget.body}</div></article>',
      validator: html.NodeValidatorBuilder.common()
        ..allowNavigation(_ArticleUriPolicy())
        ..allowImages(_ArticleUriPolicy(imagesOnly: true)),
    );
    final style = html.StyleElement()
      ..text =
          '''
.native-page-article {padding:0 0 32px;}
.native-page-article .article-copy {padding:20px ${widget.inset}px 0;}
.native-page-article h1 {font-size:32px;line-height:1.2;font-weight:400;text-align:center;margin:0 0 10px;}
.native-page-article .article-description {max-width:600px;margin:0 auto 30px;text-align:center;font-size:14px;}
.native-page-article h2 {font-size:24px;line-height:1.3;margin:28px 0 10px;}
.native-page-article h3 {font-size:20px;margin:18px 0 8px;}
.native-page-article a {color:${_cssColor(widget.linkColor)};text-decoration:none;}
.native-page-article a:hover {filter:brightness(1.15);}
.native-page-article a:focus-visible {outline:2px solid currentColor;outline-offset:4px;}
.native-page-article img {max-width:100%;height:auto;}
.native-page-article .page-banner {display:block;width:100%;aspect-ratio:4;object-fit:cover;margin:0 0 4px;}
.native-page-article pre {overflow:auto;}
.native-page-article table {border-collapse:collapse;max-width:100%;}
.native-page-article td,.native-page-article th {padding:8px;border:1px solid currentColor;}
''';
    root.append(style);
    final segments = Uri.base.pathSegments;
    if (segments.length >= 2) {
      for (final anchor in root.querySelectorAll('a')) {
        final href = anchor.getAttribute('href');
        if (href == '/contact' || href == '/about') {
          anchor.setAttribute('data-app-route', href!);
          anchor.setAttribute(
            'href',
            '/${segments[0]}/${widget.language}$href',
          );
        }
      }
    }
    // Replace the initial static article only when its visible DOM replacement
    // exists, rather than deleting readable content on Flutter's first frame.
    html.document.getElementById('page-content')?.remove();
    html.document.body?.style.overflow = 'hidden';
  }

  @override
  void didUpdateWidget(covariant SelectableWebArticle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _render();
  }

  @override
  void dispose() {
    _clicks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'section',
    onElementCreated: (element) {
      _element = element as html.Element;
      _render();
      _clicks = _element!.onClick.listen((event) {
        final target = event.target;
        final anchor = target is html.Element ? target.closest('a') : null;
        final href = anchor?.getAttribute('href');
        if (href == null) return;
        final keysDown = (event.ctrlKey ?? false) ||
            (event.metaKey ?? false) ||
            (event.shiftKey ?? false) ||
            (event.altKey ?? false);
        if (keysDown) {
          return;
        }
        final uri = Uri.tryParse(href);
        if (uri == null ||
            uri.hasScheme ||
            uri.hasAuthority ||
            href.startsWith('#')) {
          return;
        }
        event.preventDefault();
        widget.onNavigate(anchor?.getAttribute('data-app-route') ?? href);
      });
    },
  );
}

class _ArticleUriPolicy implements html.UriPolicy {
  _ArticleUriPolicy({this.imagesOnly = false});
  final bool imagesOnly;

  @override
  bool allowsUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return !uri.hasScheme ||
        uri.scheme == 'https' ||
        uri.scheme == 'http' ||
        (!imagesOnly && (uri.scheme == 'mailto' || uri.scheme == 'tel'));
  }
}
