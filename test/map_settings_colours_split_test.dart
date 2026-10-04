import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/pages/map_settings_section.dart';
import 'package:free_open_ocean/services/map_chart_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MapChartSettings.instance.reset();
  });

  Future<void> pumpMapSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: MapSettingsSection()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the Colours tile is gone and layer tiles keep their colours', (
    tester,
  ) async {
    await pumpMapSettings(tester);

    expect(find.text('Colours'), findsNothing);

    // Land is the first tile.
    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    expect(find.text('Beach'), findsOneWidget);
    expect(find.text('Coastline'), findsOneWidget);
    expect(find.text('Hillshade shadow'), findsOneWidget);

    expect(find.text('Island'), findsOneWidget);
    expect(find.text('Islands'), findsNothing);

    expect(find.text('Local streets'), findsOneWidget);
    expect(find.text('Road names'), findsOneWidget);
    expect(find.text('Main roads'), findsOneWidget);
    expect(find.text('Minor roads'), findsOneWidget);
    expect(find.text('Road casing'), findsOneWidget);
    expect(find.text('Road labels'), findsOneWidget);
    // Zoom headers stay together; road colours follow, above hillshade.
    expect(
      tester.getTopLeft(find.text('Local streets')).dy,
      lessThan(tester.getTopLeft(find.text('Road names')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Road names')).dy,
      lessThan(tester.getTopLeft(find.text('Main roads')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Main roads')).dy,
      lessThan(tester.getTopLeft(find.text('Hillshade accent')).dy),
    );
  });
}
