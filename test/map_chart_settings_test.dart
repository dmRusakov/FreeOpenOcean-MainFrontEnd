import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_open_ocean/services/map_chart_settings.dart';

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
      await settings.setZoomEnabled('marinaIcon', z, false);
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('mapChartSettings')!;
    expect((jsonDecode(stored)['zoomLevels']['marinaIcon'] as List), isEmpty);
    await settings.reset();
    await prefs.setString('mapChartSettings', stored);
    await settings.load();
    expect(settings.zoom('marinaIcon'), 24);
    expect(settings.zoomEnabled('marinaIcon', 22), false);
    await settings.setZoomEnabled('marinaIcon', 8, true);
    expect(settings.zoom('marinaIcon'), 8);
    expect(settings.zoomEnabled('marinaIcon', 9), false);
  });

  test('a zoom range fills every level from the first to the last', () async {
    await settings.setZoomRange('slipway', 14, 18);
    expect(settings.zoomRange('slipway'), (14, 18));
    expect(settings.zoom('slipway'), 14);
    expect(settings.zoomEnabled('slipway', 13), false);
    expect(settings.zoomEnabled('slipway', 14), true);
    expect(settings.zoomEnabled('slipway', 18), true);
    expect(settings.zoomEnabled('slipway', 19), false);
  });

  test('reset restores default zooms and rejects unsupported levels', () async {
    await settings.setZoomEnabled('marinaIcon', 4, true);
    await settings.reset();
    expect(settings.zoom('marinaIcon'), 11);
    expect(settings.zoomEnabled('marinaIcon', 4), false);
    expect(settings.setZoomEnabled('marinaIcon', 23, true), throwsRangeError);
  });
}
