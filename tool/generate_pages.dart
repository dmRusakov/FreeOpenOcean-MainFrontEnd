import 'dart:convert';
import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'package:yaml/yaml.dart';

/// Run before flutter run, or AFTER flutter build web with build/web as argument.
void main(List<String> args) {
  final output = args.isEmpty ? 'web' : args.single;
  final template = File('$output/index.html').readAsStringSync();
  const escape = HtmlEscape(HtmlEscapeMode.attribute);
  String e(Object? value) => escape.convert(value.toString());
  final urls = <String>[];
  final links = <String>[];
  for (final slug in ['about', 'contact']) {
    for (final language in ['en', 'es', 'fr', 'pt', 'ru']) {
      final name = 'pages_${slug}_$language.md';
      final source = File('app/cache/$name').readAsStringSync();
      final match = RegExp(r'^---\n([\s\S]*?)\n---\n').firstMatch(source)!;
      final data = loadYaml(match.group(1)!) as YamlMap;
      final canonical = data['canonicalUrl'] as String;
      final markdownUrl = data['markdownUrl'] as String;
      final alternatives = data['alternateLanguages'] as YamlMap;
      final body = md
          .markdownToHtml(
            source.substring(match.end),
            extensionSet: md.ExtensionSet.gitHubWeb,
          )
          .replaceAll('href="/contact"', 'href="/USA/$language/contact"');
      final schema = {
        '@context': 'https://schema.org',
        '@type': data['schemaType'],
        'name': data['title'],
        'description': data['seoDescription'],
        'url': canonical,
        'inLanguage': language,
        'isPartOf': {
          '@type': 'WebSite',
          'name': data['siteName'],
          'url': 'https://freeopenocean.com',
        },
        'associatedMedia': {
          '@type': 'DigitalDocument',
          'url': markdownUrl,
          'encodingFormat': 'text/markdown',
        },
      };
      final head =
          '''
<title>${e(data['seoTitle'])}</title>
<meta name="description" content="${e(data['seoDescription'])}">
<meta name="robots" content="${e(data['robots'])}">
<link rel="canonical" href="${e(canonical)}">
<link rel="alternate" type="text/markdown" href="${e(markdownUrl)}" title="Markdown">
${alternatives.entries.map((a) => '<link rel="alternate" hreflang="${e(a.key)}" href="${e(a.value)}">').join('\n')}
<link rel="alternate" hreflang="x-default" href="${e(alternatives['en'])}">
<meta property="og:type" content="website">
<meta property="og:title" content="${e(data['seoTitle'])}">
<meta property="og:description" content="${e(data['seoDescription'])}">
<meta property="og:url" content="${e(canonical)}">
<meta property="og:site_name" content="${e(data['siteName'])}">
<meta property="og:image" content="${e(data['socialImage'])}">
<meta property="og:image:alt" content="${e(data['socialImageAlt'])}">
<meta name="twitter:card" content="${e(data['twitterCard'])}">
<meta name="twitter:title" content="${e(data['seoTitle'])}">
<meta name="twitter:description" content="${e(data['seoDescription'])}">
<meta name="twitter:image" content="${e(data['socialImage'])}">
<script type="application/ld+json">${jsonEncode(schema).replaceAll('<', r'\u003c')}</script>
<style>
body {overflow:auto; color:#d3dce0; font-family:system-ui,sans-serif;}
#loading {display:none;}
#page-content {max-width:900px;margin:40px auto;padding:24px;line-height:1.65;}
#page-content a {color:#79c5df;text-decoration:none;}
#page-content h1 {line-height:1.2;}
</style>
''';
      final article =
          '''<main id="page-content" lang="$language">
<nav>${alternatives.entries.map((a) => '<a href="${e(a.value)}" hreflang="${e(a.key)}">${e(a.key)}</a>').join(' · ')}</nav>
<article><h1>${e(data['title'])}</h1><p>${e(data['description'])}</p>$body</article>
<p><a href="${e(markdownUrl)}" type="text/markdown">Markdown</a></p>
</main>
<!-- The app replaces this article only after mounting its native HTML article. -->''';
      final html = template
          .replaceFirst('<html>', '<html lang="$language">')
          .replaceFirst(RegExp(r'<base href="[^"]*">'), '<base href="/">')
          .replaceAll(RegExp(r'<title>[^<]*</title>'), '')
          .replaceAll(RegExp(r'<meta name="description"[^>]*>'), '')
          .replaceFirst('</head>', '$head</head>')
          .replaceFirst('<body>', '<body>\n$article');
      final path = Uri.parse(canonical).path;
      final file = File('$output$path/index.html');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(html);
      final markdown = File('$output/pages/$name');
      markdown.parent.createSync(recursive: true);
      markdown.writeAsStringSync(source);
      urls.add(
        '<url><loc>${e(canonical)}</loc>${alternatives.entries.map((a) => '<xhtml:link rel="alternate" hreflang="${e(a.key)}" href="${e(a.value)}"/>').join()}</url>',
      );
      links.add('- [${data['title']}]($canonical) — [Markdown]($markdownUrl)');
    }
  }
  File('$output/sitemap.xml').writeAsStringSync(
    '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">${urls.join('\n')}</urlset>',
  );
  File('$output/robots.txt').writeAsStringSync(
    'User-agent: *\nAllow: /\n\nSitemap: https://freeopenocean.com/sitemap.xml\n',
  );
  File('$output/llms.txt').writeAsStringSync(
    '# FreeOpenOcean\n\n> Public marine information and nautical charting project.\n\n## Pages in five languages\n${links.join('\n')}\n',
  );
}
