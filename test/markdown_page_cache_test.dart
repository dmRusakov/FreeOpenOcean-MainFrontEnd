import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_open_ocean/services/markdown_page_cache.dart';

const source = '''---
title: About
description: Intro
seoTitle: About site
seoDescription: Site description
---
## Heading

**Ocean** [Contact](/contact)
''';

class Seeds extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'app/cache/pages_about_en.md') throw FlutterError('Missing');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  MarkdownPageCache offline({AssetBundle? bundle, DateTime Function()? clock}) {
    return MarkdownPageCache(
      bundle: bundle,
      clock: clock,
      fetcher: (url, {etag}) async => null,
    );
  }

  test('all supported About translations load from bundled assets', () async {
    const titles = {
      'en': 'About FreeOpenOcean',
      'es': 'Acerca de FreeOpenOcean',
      'fr': 'À propos de FreeOpenOcean',
      'pt': 'Sobre o FreeOpenOcean',
      'ru': 'О проекте FreeOpenOcean',
    };
    final cache = offline();
    for (final entry in titles.entries) {
      final page = await cache.load('about', entry.key);
      expect(page.title, entry.value, reason: entry.key);
      expect(RegExp(r'<h2[ >]').allMatches(page.html).length, 8);
      expect(page.html, contains('href="/contact"'));
      expect(page.html, contains('mailto:data@freeopenocean.com'));
      expect(page.html, contains('mailto:contact@freeopenocean.com'));
      expect(page.seoTitle, contains('FreeOpenOcean'));
      expect(page.seoDescription, isNotEmpty);
    }
  });

  test('Contact translations load with metadata and email links', () async {
    final cache = offline();
    for (final language in ['en', 'es', 'fr', 'pt', 'ru']) {
      final page = await cache.load('contact', language);
      expect(page.seo['language'], language);
      expect(page.seo['schemaType'], 'ContactPage');
      expect(page.seo['canonicalUrl'], endsWith('/$language/contact'));
      expect(RegExp(r'<h2[ >]').allMatches(page.html).length, 3);
      expect(page.html, contains('mailto:data@freeopenocean.com'));
      expect(page.html, contains('mailto:contact@freeopenocean.com'));
    }
  });

  test('stable route filenames ignore query and encode nested paths', () {
    expect(
      MarkdownPageCache.fileName('/about/?section=x', 'EN'),
      'pages_about_en.md',
    );
    expect(
      MarkdownPageCache.fileName('/help/navigation', 'fr'),
      'pages_help%2Fnavigation_fr.md',
    );
  });
  test('metadata, headings, emphasis and links render', () {
    final page = MarkdownPage(source);
    expect(page.title, 'About');
    expect(page.html, contains('<h2 id="heading">Heading</h2>'));
    expect(page.html, contains('<strong>Ocean</strong>'));
    expect(page.html, contains('href="/contact"'));
  });
  test('missing translation falls back to bundled English', () async {
    expect(
      (await offline(bundle: Seeds()).load('about', 'fr')).title,
      'About',
    );
  });
  test(
    'persistent override wins and invalidation restores bundled seed',
    () async {
      final cache = offline(bundle: Seeds());
      await cache.store(
        'about',
        'en',
        source.replaceFirst('title: About', 'title: Updated'),
      );
      expect(
        (await offline(bundle: Seeds()).load('about', 'en')).title,
        'Updated',
      );
      await cache.invalidate('about', 'en');
      expect((await cache.load('about', 'en')).title, 'About');
    },
  );
  test(
    'corrupt cache falls back and invalid downloads cannot overwrite',
    () async {
      SharedPreferences.setMockInitialValues({
        'app/cache/pages_about_en.md': 'broken',
      });
      final cache = offline(bundle: Seeds());
      expect((await cache.load('about', 'en')).title, 'About');
      await expectLater(
        cache.store('about', 'en', 'broken'),
        throwsFormatException,
      );
      expect((await cache.load('about', 'en')).title, 'About');
    },
  );

  test('a copy checked today is reused without a request', () async {
    var calls = 0;
    final cache = MarkdownPageCache(
      bundle: Seeds(),
      fetcher: (url, {etag}) async {
        calls++;
        return null;
      },
    );
    await cache.store('about', 'en', source.replaceFirst('title: About', 'title: Saved'));
    expect((await cache.load('about', 'en')).title, 'Saved');
    expect(calls, 0);
  });

  test('a day-old copy is revalidated and a 304 renews it', () async {
    final now = DateTime.utc(2026, 10, 1);
    String? sentEtag;
    final cache = MarkdownPageCache(
      bundle: Seeds(),
      clock: () => now,
      fetcher: (url, {etag}) async {
        sentEtag = etag;
        return const PageFetchResult(status: 304);
      },
    );
    SharedPreferences.setMockInitialValues({
      'app/cache/pages_about_en.md': source.replaceFirst('title: About', 'title: Saved'),
      'app/cache/pages_about_en.md.etag': '"abc"',
      'app/cache/pages_about_en.md.checked':
          now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
    });
    expect((await cache.load('about', 'en')).title, 'Saved');
    expect(sentEtag, '"abc"');
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt('app/cache/pages_about_en.md.checked'),
      now.millisecondsSinceEpoch,
    );
  });

  test('a changed document replaces the saved copy', () async {
    final cache = MarkdownPageCache(
      bundle: Seeds(),
      fetcher: (url, {etag}) async => PageFetchResult(
        status: 200,
        body: source.replaceFirst('title: About', 'title: Remote'),
        etag: '"new"',
      ),
    );
    expect((await cache.load('about', 'en')).title, 'Remote');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('app/cache/pages_about_en.md.etag'), '"new"');
  });

  test('a copy older than a month is not shown when the host is down', () async {
    final now = DateTime.utc(2026, 10, 1);
    final cache = MarkdownPageCache(
      bundle: Seeds(),
      clock: () => now,
      fetcher: (url, {etag}) async => null,
    );
    SharedPreferences.setMockInitialValues({
      'app/cache/pages_about_en.md': source.replaceFirst('title: About', 'title: Stale'),
      'app/cache/pages_about_en.md.checked':
          now.subtract(const Duration(days: 31)).millisecondsSinceEpoch,
    });
    expect((await cache.load('about', 'en')).title, 'About');
  });

  test('low data keeps an old copy and skips the host', () async {
    var calls = 0;
    final now = DateTime.utc(2026, 10, 1);
    final cache = MarkdownPageCache(
      bundle: Seeds(),
      clock: () => now,
      fetcher: (url, {etag}) async {
        calls++;
        return null;
      },
    );
    SharedPreferences.setMockInitialValues({
      'app/cache/pages_about_en.md': source.replaceFirst('title: About', 'title: Kept'),
      'app/cache/pages_about_en.md.checked':
          now.subtract(const Duration(days: 40)).millisecondsSinceEpoch,
    });
    expect((await cache.load('about', 'en', lowData: true)).title, 'Kept');
    expect(calls, 0);
  });
}
