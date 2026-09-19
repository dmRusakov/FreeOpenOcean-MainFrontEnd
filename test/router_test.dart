import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_open_ocean/core/router/app_router.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';

void main() {
  test('locale resolution accepts language-only and regional deep links', () {
    const supported = [Locale('en', ''), Locale('fr', '')];
    expect(
      AppLocalizations.resolveLocale(const Locale('fr'), supported),
      supported.last,
    );
    expect(
      AppLocalizations.resolveLocale(const Locale('fr', 'CA'), supported),
      supported.last,
    );
    expect(
      AppLocalizations.resolveLocale(const Locale('de'), supported),
      supported.first,
    );
  });

  test('changing region preserves page, query and fragment', () {
    final uri = Uri.parse(
      '/USA/en/settings?section=language&filter=a%20b#details',
    );
    final changed = AppRouter.withRegion(uri, country: 'FRA', language: 'fr');
    expect(changed.path, '/FRA/fr/settings');
    expect(changed.query, uri.query);
    expect(changed.fragment, 'details');
  });
  testWidgets('deep link synchronizes country and language together', (
    tester,
  ) async {
    final changes = <String>[];
    final appRouter = AppRouter(
      onRegionChanged: (country, locale) =>
          changes.add('$country/${locale.languageCode}'),
    );
    addTearDown(appRouter.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    appRouter.router.go('/FRA/fr/settings?section=language');
    await appRouter.router.routeInformationParser
        .parseRouteInformationWithDependencies(
          appRouter.router.routeInformationProvider.value,
          context,
        );
    await tester.pump();
    expect(changes, ['FRA/fr']);
  });
  testWidgets(
    'root uses saved region and invalid deep links normalize safely',
    (tester) async {
      final appRouter = AppRouter(
        initialCountry: 'PRT',
        initialLocale: const Locale('pt'),
        onRegionChanged: (_, _) {},
      );
      addTearDown(appRouter.dispose);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      appRouter.router.go('/?section=theme');
      var matches = await appRouter.router.routeInformationParser
          .parseRouteInformationWithDependencies(
            appRouter.router.routeInformationProvider.value,
            context,
          );
      expect(matches.uri.toString(), '/PRT/pt?section=theme');
      appRouter.router.go('/bad/de/settings?section=language');
      matches = await appRouter.router.routeInformationParser
          .parseRouteInformationWithDependencies(
            appRouter.router.routeInformationProvider.value,
            context,
          );
      expect(matches.uri.toString(), '/USA/en/settings?section=language');
      await tester.pump();
    },
  );
}
