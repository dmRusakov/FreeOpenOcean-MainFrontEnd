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
        home: const Scaffold(
          body: SizedBox(
            width: 800,
            height: 2400,
            child: MapSettingsSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expandAll(WidgetTester tester) async {
    while (find.byIcon(Icons.expand_more).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.byIcon(Icons.expand_more).first);
      await tester.tap(find.byIcon(Icons.expand_more).first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('the Colours tile is gone and layer tiles keep their colours', (
    tester,
  ) async {
    await pumpMapSettings(tester);

    expect(find.text('Colours'), findsNothing);

    await expandAll(tester);
    expect(find.text('Beach'), findsOneWidget);
    expect(find.text('Coastline'), findsOneWidget);
    expect(find.text('Hillshade shadow'), findsOneWidget);

    expect(find.text('Island'), findsOneWidget);
    expect(find.text('Islands'), findsNothing);

    expect(find.text('Main roads'), findsOneWidget);
    expect(find.text('Minor roads'), findsOneWidget);
    expect(find.text('Road casing'), findsOneWidget);
    expect(find.text('Road labels'), findsOneWidget);
    // Land colour row sits with the other Land titles, above hillshade.
    expect(
      tester.getTopLeft(find.text('Main roads')).dy,
      lessThan(tester.getTopLeft(find.text('Hillshade accent')).dy),
    );
  });

  testWidgets('Land tile titles share an 18-character width', (tester) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    double titleWidth(String label) {
      // Prefer the parameter row (not the tile header) when both exist.
      final matches = find.text(label);
      expect(matches, findsWidgets);
      final boxes = matches.evaluate().toList();
      final widths = [
        for (final box in boxes) tester.getSize(find.byWidget(box.widget)).width,
      ]..sort();
      return widths.first;
    }

    final land = titleWidth('Land');
    final mainRoads = titleWidth('Main roads');
    final beach = titleWidth('Beach');
    final accent = titleWidth('Hillshade accent');
    // Same 18-character slot: short and longer names share one width.
    expect(land, closeTo(mainRoads, 0.5));
    expect(beach, closeTo(mainRoads, 0.5));
    expect(accent, closeTo(mainRoads, 0.5));
  });

  testWidgets('Land tile Fill columns keep the same width when empty', (
    tester,
  ) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    Offset rightOf(String label) {
      final matches = find.text(label);
      // Parameter row is the narrower title when Land appears twice.
      final boxes = matches.evaluate().toList();
      boxes.sort(
        (a, b) =>
            tester.getSize(find.byWidget(a.widget)).width.compareTo(
              tester.getSize(find.byWidget(b.widget)).width,
            ),
      );
      return tester.getTopRight(find.byWidget(boxes.first.widget));
    }

    // Line-only (Main roads) and fill rows share the same Fill column start.
    expect(rightOf('Land').dx, closeTo(rightOf('Main roads').dx, 0.5));
    expect(rightOf('Beach').dx, closeTo(rightOf('Coastline').dx, 0.5));
  });

  testWidgets('expanded tiles show input column titles under the header', (
    tester,
  ) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    expect(find.text('Name'), findsWidgets);
    expect(find.text('Zoom'), findsWidgets);
    expect(find.text('Line type'), findsWidgets);
    expect(find.text('Line width'), findsWidgets);
    expect(find.text('Fill'), findsWidgets);
    expect(find.text('Line'), findsWidgets);
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Dark'), findsWidgets);
  });

  testWidgets('Graticule uses the same detail row style as Land', (tester) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    expect(find.text('Graticule'), findsWidgets);
    expect(find.text('Equator'), findsOneWidget);
    expect(find.text('Sun and moon'), findsNothing);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('Sun track'), findsOneWidget);
    expect(find.text('Sun latitude'), findsOneWidget);
    expect(find.text('Moon'), findsOneWidget);
    expect(find.text('Moon track'), findsOneWidget);

    double titleWidth(String label) {
      final matches = find.text(label);
      final boxes = matches.evaluate().toList();
      final widths = [
        for (final box in boxes)
          tester.getSize(find.byWidget(box.widget)).width,
      ]..sort();
      return widths.first;
    }

    // Same 18-character name slot as Land rows.
    expect(titleWidth('Graticule'), closeTo(titleWidth('Equator'), 0.5));
    expect(titleWidth('Equator'), closeTo(titleWidth('Main roads'), 0.5));
    expect(titleWidth('Sun'), closeTo(titleWidth('Moon'), 0.5));
  });
}
