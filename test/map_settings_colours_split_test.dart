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

  Future<void> pumpMapSettings(
    WidgetTester tester, {
    double width = 800,
  }) async {
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
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 2400,
            child: const MapSettingsSection(),
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
    expect(find.text('The land fill.'), findsOneWidget);
    expect(find.text('Highways and other main roads.'), findsOneWidget);
    expect(find.text('Smaller roads, including local streets.'), findsOneWidget);
    expect(find.text('The darker edge under a road.'), findsOneWidget);
    expect(find.text('Names written on the roads.'), findsOneWidget);
    expect(find.text('Sand along the shore.'), findsOneWidget);
    expect(find.text('Buildings'), findsOneWidget);
    expect(find.text('Houses and other buildings.'), findsOneWidget);
    expect(
      find.text('Island fill, and the dots for islands too small to see.'),
      findsOneWidget,
    );
    expect(
      find.text('The shore. Dam fills and pier lines use this colour.'),
      findsOneWidget,
    );
    expect(find.text('Elevation lines on land.'), findsOneWidget);
    expect(find.text('Height numbers on the land contours.'), findsOneWidget);
    expect(find.text('The shaded side of the land relief.'), findsOneWidget);
    expect(find.text('The lit side of the land relief.'), findsOneWidget);
    expect(find.text('The mid-tone of the land relief.'), findsOneWidget);
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
    expect(find.text('Boundaries'), findsOneWidget);
    expect(
      find.text('Country, state, and local administrative borders.'),
      findsOneWidget,
    );
    expect(titleWidth('Boundaries'), closeTo(mainRoads, 0.5));
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
    expect(find.text('Latitude and longitude every 10 degrees.'), findsOneWidget);
    expect(
      find.text('Latitude 0, drawn apart from the 10° grid.'),
      findsOneWidget,
    );
    expect(find.text('Where the sun is overhead right now.'), findsOneWidget);
    expect(find.text('The sun\'s path across the wide chart.'), findsOneWidget);
    expect(
      find.text('The line of the sun\'s current latitude.'),
      findsOneWidget,
    );
    expect(find.text('Where the moon is overhead right now.'), findsOneWidget);
    expect(
      find.text('The moon\'s path for one pass around the Earth.'),
      findsOneWidget,
    );

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

  testWidgets('Sea is one detail section without subgroup headers', (tester) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    expect(find.text('Rivers and streams'), findsNothing);
    expect(find.text('Depth'), findsNothing);
    expect(find.text('Streams'), findsOneWidget);
    expect(find.text('Rivers'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Rivers')).dy,
      lessThan(tester.getTopLeft(find.text('Streams')).dy),
    );
    expect(find.text('Shallow water'), findsOneWidget);
    expect(find.text('Ferry track'), findsOneWidget);
    expect(find.text('Bridge'), findsOneWidget);
    expect(
      find.text('The water fill. The line is where the sea meets the land.'),
      findsOneWidget,
    );
    expect(
      find.text('River centre lines, drawn in the sea colour.'),
      findsOneWidget,
    );
    expect(
      find.text('Stream centre lines, drawn in the coastline colour.'),
      findsOneWidget,
    );
    expect(find.text('Depth contours shallower than 5 m.'), findsOneWidget);
    expect(find.text('Depth contours from 5 m to 20 m.'), findsOneWidget);
    expect(find.text('Depth contours from 20 m to 50 m.'), findsOneWidget);
    expect(find.text('Depth contours from 50 m to 200 m.'), findsOneWidget);
    expect(find.text('Depth contours of 200 m and deeper.'), findsOneWidget);
    expect(find.text('Sounding numbers on the depth contours.'), findsOneWidget);
    expect(find.text('The line of a ferry route.'), findsOneWidget);
    expect(find.text('Names along the ferry routes.'), findsOneWidget);
    expect(find.text('Names of bridges.'), findsOneWidget);

    double titleWidth(String label) {
      final matches = find.text(label);
      final boxes = matches.evaluate().toList();
      final widths = [
        for (final box in boxes)
          tester.getSize(find.byWidget(box.widget)).width,
      ]..sort();
      return widths.first;
    }

    expect(titleWidth('Streams'), closeTo(titleWidth('Main roads'), 0.5));
    expect(titleWidth('Shallow water'), closeTo(titleWidth('Bridge'), 0.5));
  });

  testWidgets('Marine objects is one detail section without subgroup headers', (
    tester,
  ) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    expect(find.text('Marine objects'), findsOneWidget);
    expect(find.text('Marinas'), findsNothing);
    expect(find.text('Harbour places'), findsNothing);
    expect(find.text('Docks and canals'), findsNothing);
    expect(find.text('Offshore platforms'), findsNothing);
    expect(find.text('Lighthouses'), findsNothing);
    expect(find.text('Icon'), findsOneWidget);
    expect(find.text('Border'), findsOneWidget);

    expect(find.text('Marina'), findsOneWidget);
    expect(find.text('Anchorage'), findsOneWidget);
    expect(find.text('Port'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Dock'), findsOneWidget);
    expect(find.text('Slipway'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Slipway')).dy,
      greaterThan(tester.getTopLeft(find.text('Marine objects')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Slipway')).dy,
      lessThan(tester.getTopLeft(find.text('Hazard')).dy),
    );
    expect(find.text('Hazard'), findsOneWidget);
    expect(find.text('Offshore platform'), findsOneWidget);
    expect(find.text('Platform names'), findsNothing);
    expect(find.text('Platform safety zones'), findsNothing);
    expect(find.text('Navigation light'), findsOneWidget);
    expect(find.text('Lighthouse names'), findsNothing);
    expect(find.text('Yacht harbours and marina berths.'), findsOneWidget);
    expect(
      find.text('Designated and informal anchoring spots.'),
      findsOneWidget,
    );
    expect(find.text('Fuel docks and water-fuel stations.'), findsOneWidget);
    expect(find.text('Customs and immigration offices.'), findsOneWidget);
    expect(
      find.text('Harbourmaster, naval bases, and other port offices.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Boat repair, chandlers, storage, and related shore services.',
      ),
      findsOneWidget,
    );
    expect(find.text('Docks, piers, and canal basins.'), findsOneWidget);
    expect(
      find.text('Boat ramps for launching and hauling out.'),
      findsOneWidget,
    );
    expect(find.text('Seamarks and other charted hazards.'), findsOneWidget);
    expect(find.text('Oil and gas platforms.'), findsOneWidget);
    expect(find.text('Lighthouses and beacons.'), findsOneWidget);

    double titleWidth(String label) {
      final matches = find.text(label);
      final boxes = matches.evaluate().toList();
      final widths = [
        for (final box in boxes)
          tester.getSize(find.byWidget(box.widget)).width,
      ]..sort();
      return widths.first;
    }

    expect(titleWidth('Marina'), closeTo(titleWidth('Main roads'), 0.5));
    expect(
      titleWidth('Offshore platform'),
      closeTo(titleWidth('Navigation light'), 0.5),
    );
  });

  testWidgets('Labels is its own detail tile', (tester) async {
    await pumpMapSettings(tester);
    await expandAll(tester);

    expect(find.text('Labels'), findsOneWidget);
    expect(find.text('Font size'), findsOneWidget);
    expect(find.text('Capitalize'), findsOneWidget);
    expect(find.text('Water names'), findsOneWidget);
    expect(find.text('Country names'), findsOneWidget);
    expect(find.text('Region names'), findsOneWidget);
    expect(find.text('City names'), findsOneWidget);
    expect(find.text('Object names'), findsOneWidget);
    expect(find.text('Island names'), findsOneWidget);
    expect(find.text('Basemap island names'), findsOneWidget);
    expect(find.text('Name outline'), findsOneWidget);
    expect(
      find.text('Rivers, lakes, and other water names on the chart.'),
      findsOneWidget,
    );
    expect(
      find.text('Country names from the basemap tiles.'),
      findsOneWidget,
    );
    expect(
      find.text('Region and state names from the basemap tiles.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'City and town names. When Local streets are off, only larger cities stay.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Marina, port, seamark, and other object names on the chart.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Custom island and island-group names, separate from basemap tile labels.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Island names from basemap tiles, separate from Islands and Island names.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Outline behind chart text so names stay readable on land and water.',
      ),
      findsOneWidget,
    );

    double titleWidth(String label) {
      final matches = find.text(label);
      final boxes = matches.evaluate().toList();
      final widths = [
        for (final box in boxes)
          tester.getSize(find.byWidget(box.widget)).width,
      ]..sort();
      return widths.first;
    }

    expect(titleWidth('Water names'), closeTo(titleWidth('Main roads'), 0.5));
    expect(titleWidth('Name outline'), closeTo(titleWidth('Water names'), 0.5));
    expect(
      titleWidth('Basemap island names'),
      closeTo(titleWidth('Water names'), 0.5),
    );
  });

  testWidgets('narrow panels put the zoom under the name', (tester) async {
    await pumpMapSettings(tester, width: 480);
    await expandAll(tester);

    expect(find.text('Zoom'), findsNothing);
    final name = tester.getRect(find.text('Water names'));
    final blurb = tester.getRect(
      find.text('Rivers, lakes, and other water names on the chart.'),
    );
    Rect? zoom;
    for (final element in find.text('12 - 22').evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      if (rect.top >= name.bottom - 1 &&
          (zoom == null || rect.top < zoom.top)) {
        zoom = rect;
      }
    }
    expect(zoom, isNotNull);
    expect(zoom!.top, greaterThan(name.bottom));
    expect(zoom.bottom, lessThan(blurb.top + 1));
  });
}
