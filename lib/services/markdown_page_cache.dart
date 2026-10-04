import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';

/// A Markdown page with YAML metadata for the page header and search engines.
class MarkdownPage {
  MarkdownPage(String source) {
    final match = RegExp(
      r'^---\r?\n([\s\S]*?)\r?\n---\r?\n',
    ).firstMatch(source);
    if (match == null) throw const FormatException('Page metadata is missing');
    final metadata = loadYaml(match.group(1)!);
    if (metadata is! YamlMap) throw const FormatException('Invalid metadata');
    String requiredText(String key) {
      final value = metadata[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing page metadata: $key');
      }
      return value;
    }

    seo = Map<String, dynamic>.from(metadata);
    title = requiredText('title');
    description = requiredText('description');
    seoTitle = requiredText('seoTitle');
    seoDescription = requiredText('seoDescription');
    final body = source.substring(match.end).trim();
    if (body.isEmpty) throw const FormatException('Page body is empty');
    html = md.markdownToHtml(body, extensionSet: md.ExtensionSet.gitHubWeb);
  }

  late final Map<String, dynamic> seo;
  late final String title;
  late final String description;
  late final String seoTitle;
  late final String seoDescription;
  late final String html;
}

/// Result of one request to the pages host. Status 304 keeps the saved body.
class PageFetchResult {
  const PageFetchResult({required this.status, this.body, this.etag});

  final int status;
  final String? body;
  final String? etag;
}

typedef PageFetcher = Future<PageFetchResult?> Function(
  Uri url, {
  String? etag,
});

/// Bundled seeds live in app/cache. Downloaded copies persist in
/// SharedPreferences on web and mobile.
class MarkdownPageCache {
  MarkdownPageCache({
    AssetBundle? bundle,
    PageFetcher? fetcher,
    DateTime Function()? clock,
    this.host = 'https://pages.freeopenocean.com',
  }) : _bundle = bundle ?? rootBundle,
       _fetcher = fetcher ?? _httpFetch,
       _clock = clock ?? DateTime.now;

  static const checkInterval = Duration(days: 1);
  static const maxAge = Duration(days: 30);

  final AssetBundle _bundle;
  final PageFetcher _fetcher;
  final DateTime Function() _clock;
  final String host;

  static String fileName(String pageUrl, String language) {
    final path = Uri.parse(pageUrl).path.replaceAll(RegExp(r'^/+|/+$'), '');
    final slug = path.isEmpty ? 'index' : path;
    return 'pages_${Uri.encodeComponent(slug)}_${Uri.encodeComponent(language.toLowerCase())}.md';
  }

  /// [lowData] is Silent or Disable connection mode. A saved copy is shown
  /// with no freshness check and may be kept past [maxAge].
  Future<MarkdownPage> load(
    String pageUrl,
    String language, {
    bool lowData = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    for (final locale in {language.toLowerCase(), 'en'}) {
      final name = fileName(pageUrl, locale);
      final key = 'app/cache/$name';
      final saved = await _read(preferences, key);
      if (saved != null && (lowData || _fresh(saved.checkedAt))) {
        return saved.page;
      }
      if (!lowData) {
        final remote = await _fetch(preferences, key, name, saved);
        if (remote != null) return remote;
      }
      if (saved != null && (lowData || !_expired(saved.checkedAt))) {
        return saved.page;
      }
      try {
        return MarkdownPage(await _bundle.loadString(key));
      } on FlutterError {
        continue;
      }
    }
    throw StateError('No Markdown page available for $pageUrl');
  }

  /// Store a downloaded document only after validation.
  Future<void> store(
    String pageUrl,
    String language,
    String source, {
    String? etag,
  }) async {
    MarkdownPage(source);
    final preferences = await SharedPreferences.getInstance();
    final key = 'app/cache/${fileName(pageUrl, language)}';
    final saved = await preferences.setString(key, source);
    if (!saved) throw StateError('Could not cache Markdown page');
    await preferences.setInt(key + '.checked', _clock().millisecondsSinceEpoch);
    if (etag == null) {
      await preferences.remove(key + '.etag');
    } else {
      await preferences.setString(key + '.etag', etag);
    }
  }

  Future<void> invalidate(String pageUrl, String language) async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'app/cache/${fileName(pageUrl, language)}';
    await preferences.remove(key);
    await preferences.remove(key + '.etag');
    await preferences.remove(key + '.checked');
  }

  bool _fresh(DateTime? checkedAt) =>
      checkedAt != null && _clock().difference(checkedAt) < checkInterval;

  bool _expired(DateTime? checkedAt) =>
      checkedAt == null || _clock().difference(checkedAt) >= maxAge;

  Future<_SavedPage?> _read(SharedPreferences preferences, String key) async {
    final cached = preferences.getString(key);
    if (cached == null) return null;
    try {
      final millis = preferences.getInt(key + '.checked');
      return _SavedPage(
        MarkdownPage(cached),
        preferences.getString(key + '.etag'),
        millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis),
      );
    } on FormatException {
      await preferences.remove(key);
      await preferences.remove(key + '.etag');
      await preferences.remove(key + '.checked');
      return null;
    }
  }

  Future<MarkdownPage?> _fetch(
    SharedPreferences preferences,
    String key,
    String name,
    _SavedPage? saved,
  ) async {
    final result = await _fetcher(
      Uri.parse('$host/pages/$name'),
      etag: saved == null || _expired(saved.checkedAt) ? null : saved.etag,
    );
    if (result == null) return null;
    if (result.status == 304 && saved != null) {
      await preferences.setInt(key + '.checked', _clock().millisecondsSinceEpoch);
      return saved.page;
    }
    if (result.status != 200 || result.body == null) return null;
    try {
      final page = MarkdownPage(result.body!);
      await preferences.setString(key, result.body!);
      await preferences.setInt(key + '.checked', _clock().millisecondsSinceEpoch);
      if (result.etag == null) {
        await preferences.remove(key + '.etag');
      } else {
        await preferences.setString(key + '.etag', result.etag!);
      }
      return page;
    } on FormatException {
      return null;
    }
  }
}

class _SavedPage {
  _SavedPage(this.page, this.etag, this.checkedAt);
  final MarkdownPage page;
  final String? etag;
  final DateTime? checkedAt;
}

Future<PageFetchResult?> _httpFetch(Uri url, {String? etag}) async {
  final headers = <String, String>{};
  if (etag != null) headers['if-none-match'] = etag;
  if (!kIsWeb) headers['origin'] = 'https://freeopenocean.com';
  try {
    final response = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 304) {
      return const PageFetchResult(status: 304);
    }
    if (response.statusCode != 200) return null;
    return PageFetchResult(
      status: 200,
      body: response.body,
      etag: response.headers['etag'],
    );
  } catch (_) {
    return null;
  }
}
