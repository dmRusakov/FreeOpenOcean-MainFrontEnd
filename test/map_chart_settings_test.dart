import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_open_ocean/services/map_chart_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final settings = MapChartSettings.instance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await settings.reset();
  });

  test(
    'old thresholds become independent levels without changing neighbours',
    () async {
      await settings.setZoom('marinaIcon', 10);
      await settings.setZoomEnabled('marinaIcon', 11, false);
      expect(settings.zoomEnabled('marinaIcon', 9), false);
      expect(settings.zoomEnabled('marinaIcon', 10), true);
      expect(settings.zoomEnabled('marinaIcon', 11.9), false);
      expect(settings.zoomEnabled('marinaIcon', 12), true);
      final expression = settings.zoomExpression('marinaIcon', 1, 0);
      expect(expression[3 + (11 - 2) * 2 + 1], 0);
      expect(expression[3 + (12 - 2) * 2 + 1], 1);
    },
  );

  test('zoom choices persist and reload, including empty selections', () async {
    for (var z = 2; z <= 22; z++) {
      await settings.setZoomEnabled('streams', z, false);
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mapChartSettings')!;
    expect((jsonDecode(stored)['zoomLevels']['streams'] as List), isEmpty);
    await settings.reset();
    await prefs.setString('mapChartSettings', stored);
    await settings.load();
    expect(settings.zoom('streams'), 24);
    expect(settings.zoomEnabled('streams', 22), false);
    await settings.setZoomEnabled('streams', 8, true);
    expect(settings.zoom('streams'), 8);
    expect(settings.zoomEnabled('streams', 9), false);
  });

  test('a zoom range fills every level from the first to the last', () async {
    await settings.setZoomRange('bridges', 14, 18);
    expect(settings.zoomRange('bridges'), (14, 18));
    expect(settings.zoom('bridges'), 14);
    expect(settings.zoomEnabled('bridges', 13), false);
    expect(settings.zoomEnabled('bridges', 14), true);
    expect(settings.zoomEnabled('bridges', 18), true);
    expect(settings.zoomEnabled('bridges', 19), false);
  });

  test('reset restores default zooms and rejects unsupported levels', () async {
    await settings.setZoomEnabled('marinaIcon', 4, true);
    await settings.reset();
    expect(settings.zoom('marinaIcon'), 11);
    expect(settings.zoomEnabled('marinaIcon', 4), false);
    expect(settings.setZoomEnabled('marinaIcon', 23, true), throwsRangeError);
  });

  test('marine object icons persist and reload', () async {
    expect(settings.objectIcon('marina').codePoint, Icons.sailing.codePoint);
    await settings.setObjectIcon('marina', Icons.anchor);
    expect(settings.objectIcon('marina').codePoint, Icons.anchor.codePoint);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mapChartSettings')!;
    expect(jsonDecode(stored)['objectIcons']['marina']['codePoint'], Icons.anchor.codePoint);
    await settings.reset();
    expect(settings.objectIcon('marina').codePoint, Icons.sailing.codePoint);
    await prefs.setString('mapChartSettings', stored);
    await settings.load();
    expect(settings.objectIcon('marina').codePoint, Icons.anchor.codePoint);
  });

  test('marine object zooms use three stops for two zones', () async {
    expect(
      settings.objectZoomStops('marinaIcon'),
      (small: 11, full: 13, end: 22),
    );
    expect(
      settings.objectZoomStops('anchorageIcon'),
      (small: 11, full: 13, end: 22),
    );
    await settings.setObjectZoomStops('marinaIcon', 10, 14, 18);
    expect(
      settings.objectZoomStops('marinaIcon'),
      (small: 10, full: 14, end: 18),
    );
    expect(
      settings.objectZoomStops('anchorageIcon'),
      (small: 11, full: 13, end: 22),
    );
    expect(settings.zoom('marinaIcon'), 10);
    expect(settings.zoom('marinaName'), 14);
    expect(settings.zoomRange('marinaIcon'), (10, 18));
    expect(settings.zoomRange('marinaName'), (14, 18));
    await settings.setObjectZoomStops('anchorageIcon', 12, 15, 20);
    expect(
      settings.objectZoomStops('anchorageIcon'),
      (small: 12, full: 15, end: 20),
    );
    expect(settings.zoom('anchorageName'), 15);
    expect(
      settings.objectZoomStops('portIcon'),
      (small: 12, full: 14, end: 22),
    );
    await settings.setObjectZoomStops('places', 9, 11, 16);
    expect(
      settings.objectZoomStops('fuelIcon'),
      (small: 9, full: 11, end: 16),
    );
    await settings.setObjectZoomStops('fuelIcon', 10, 12, 18);
    expect(
      settings.objectZoomStops('fuelIcon'),
      (small: 10, full: 12, end: 18),
    );
    expect(
      settings.objectZoomStops('customsIcon'),
      (small: 9, full: 11, end: 16),
    );
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mapChartSettings')!;
    expect(jsonDecode(stored)['zoomStops']['marinaIcon'], [10, 14, 18]);
    expect(jsonDecode(stored)['zoomStops']['anchorageIcon'], [12, 15, 20]);
    expect(jsonDecode(stored)['zoomStops']['fuelIcon'], [10, 12, 18]);
    await settings.reset();
    expect(
      settings.objectZoomStops('marinaIcon'),
      (small: 11, full: 13, end: 22),
    );
    expect(
      settings.objectZoomStops('anchorageIcon'),
      (small: 11, full: 13, end: 22),
    );
    expect(
      settings.objectZoomStops('fuelIcon'),
      (small: 12, full: 14, end: 22),
    );
    await prefs.setString('mapChartSettings', stored);
    await settings.load();
    expect(
      settings.objectZoomStops('marinaIcon'),
      (small: 10, full: 14, end: 18),
    );
    expect(
      settings.objectZoomStops('anchorageIcon'),
      (small: 12, full: 15, end: 20),
    );
    expect(
      settings.objectZoomStops('fuelIcon'),
      (small: 10, full: 12, end: 18),
    );
  });
}
