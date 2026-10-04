import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One zoom the chart uses. The stored value replaces the built-in default.
class MapZoomSetting {
  const MapZoomSetting(this.id, this.labelKey, this.fallback);

  final String id;
  final String labelKey;
  final double fallback;
}

/// A group of chart layers that can be turned off together.
class MapLayerSetting {
  const MapLayerSetting(this.id, this.labelKey);

  final String id;
  final String labelKey;
}

/// A day and night colour. [group] and [field] match the palette.
class MapColorSetting {
  const MapColorSetting(this.group, this.field, this.labelKey);

  final String group;
  final String field;
  final String labelKey;
}

/// Saved chart layers, zooms, and day/night colours.
class MapChartSettings extends ChangeNotifier {
  MapChartSettings._();

  static final instance = MapChartSettings._();

  static const _storageKey = 'mapChartSettings';

  static const zooms = <MapZoomSetting>[
    MapZoomSetting('iconFull', 'map_zoom_icon_full', 12),
    MapZoomSetting('roadNames', 'map_zoom_road_names', 14),
    MapZoomSetting('smallDetail', 'map_zoom_small_detail', 16),
    MapZoomSetting('marinaIcon', 'map_zoom_marina_icon', 11),
    MapZoomSetting('marinaName', 'map_zoom_marina_name', 13),
    MapZoomSetting('places', 'map_zoom_places', 12),
    MapZoomSetting('slipway', 'map_zoom_slipway', 14),
    MapZoomSetting('bridges', 'map_zoom_bridges', 13),
    MapZoomSetting('ferry', 'map_zoom_ferry', 6),
    MapZoomSetting('ferryNames', 'map_zoom_ferry_names', 9),
    MapZoomSetting('waterNames', 'map_zoom_water_names', 12),
    MapZoomSetting('streams', 'map_zoom_streams', 14),
    MapZoomSetting('rivers', 'map_zoom_rivers', 9),
    MapZoomSetting('seamarks', 'map_zoom_seamarks', 12),
    MapZoomSetting('platformIcon', 'map_zoom_platform_icon', 6),
    MapZoomSetting('platformName', 'map_zoom_platform_name', 12),
    MapZoomSetting('platformZone', 'map_zoom_platform_zone', 12),
    MapZoomSetting('lighthouseIcon', 'map_zoom_lighthouse_icon', 6),
    MapZoomSetting('lighthouseName', 'map_zoom_lighthouse_name', 12),
  ];

  static const layers = <MapLayerSetting>[
    MapLayerSetting('land', 'map_layer_land'),
    MapLayerSetting('islands', 'map_layer_islands'),
    MapLayerSetting('graticule', 'map_layer_graticule'),
    MapLayerSetting('sky', 'map_layer_sky'),
    MapLayerSetting('coast', 'map_layer_coast'),
    MapLayerSetting('waterways', 'map_layer_waterways'),
    MapLayerSetting('roads', 'map_layer_roads'),
    MapLayerSetting('roadNames', 'map_layer_road_names'),
    MapLayerSetting('contours', 'map_layer_contours'),
    MapLayerSetting('marinas', 'map_layer_marinas'),
    MapLayerSetting('places', 'map_layer_places'),
    MapLayerSetting('slipways', 'map_layer_slipways'),
    MapLayerSetting('bridges', 'map_layer_bridges'),
    MapLayerSetting('harbour', 'map_layer_harbour'),
    MapLayerSetting('ferries', 'map_layer_ferries'),
    MapLayerSetting('waterNames', 'map_layer_water_names'),
    MapLayerSetting('seamarks', 'map_layer_seamarks'),
    MapLayerSetting('platforms', 'map_layer_platforms'),
    MapLayerSetting('platformZones', 'map_layer_platform_zones'),
    MapLayerSetting('lighthouses', 'map_layer_lighthouses'),
  ];

  static const colors = <MapColorSetting>[
    MapColorSetting('chart', 'landBase', 'map_color_land'),
    MapColorSetting('chart', 'landBeach', 'map_color_beach'),
    MapColorSetting('chart', 'seaBase', 'map_color_sea'),
    MapColorSetting('chart', 'seaEdge', 'map_color_sea_edge'),
    MapColorSetting('chart', 'coastline', 'map_color_coast'),
    MapColorSetting('chart', 'islandFill', 'map_color_island'),
    MapColorSetting('chart', 'islandEdge', 'map_color_island_edge'),
    MapColorSetting('chart', 'graticule', 'map_color_graticule'),
    MapColorSetting('chart', 'meridian', 'map_color_meridian'),
    MapColorSetting('chart', 'labelStrong', 'map_color_label_strong'),
    MapColorSetting('chart', 'labelSoft', 'map_color_label_soft'),
    MapColorSetting('chart', 'labelFaint', 'map_color_label_faint'),
    MapColorSetting('chart', 'labelHalo', 'map_color_label_halo'),
    MapColorSetting('chart', 'landContour', 'map_color_contour'),
    MapColorSetting('chart', 'landContourLabel', 'map_color_contour_label'),
    MapColorSetting('chart', 'hillshadeShadow', 'map_color_hillshade_shadow'),
    MapColorSetting(
      'chart',
      'hillshadeHighlight',
      'map_color_hillshade_highlight',
    ),
    MapColorSetting('chart', 'hillshadeAccent', 'map_color_hillshade_accent'),
    MapColorSetting('chart', 'roadTrunk', 'map_color_road'),
    MapColorSetting('chart', 'roadMinor', 'map_color_road_minor'),
    MapColorSetting('chart', 'roadCasing', 'map_color_road_casing'),
    MapColorSetting('chart', 'roadLabel', 'map_color_road_label'),
    MapColorSetting('depth', 'danger', 'map_color_depth_danger'),
    MapColorSetting('depth', 'caution', 'map_color_depth_caution'),
    MapColorSetting('depth', 'coastal', 'map_color_depth_coastal'),
    MapColorSetting('depth', 'shelf', 'map_color_depth_shelf'),
    MapColorSetting('depth', 'deep', 'map_color_depth_deep'),
    MapColorSetting('depth', 'label', 'map_color_depth_label'),
    MapColorSetting('objects', 'marina', 'map_color_marina'),
    MapColorSetting('objects', 'anchorage', 'map_color_anchorage'),
    MapColorSetting('objects', 'fuel', 'map_color_fuel'),
    MapColorSetting('objects', 'customs', 'map_color_customs'),
    MapColorSetting('objects', 'port', 'map_color_port'),
    MapColorSetting('objects', 'service', 'map_color_service'),
    MapColorSetting('objects', 'slipway', 'map_color_slipway'),
    MapColorSetting('objects', 'ferry', 'map_color_ferry'),
    MapColorSetting('objects', 'ferryRoute', 'map_color_ferry_route'),
    MapColorSetting('objects', 'dock', 'map_color_dock'),
    MapColorSetting('objects', 'bridge', 'map_color_bridge'),
    MapColorSetting('objects', 'hazard', 'map_color_hazard'),
    MapColorSetting('objects', 'navLight', 'map_color_nav_light'),
    MapColorSetting('objects', 'platform', 'map_color_platform'),
    MapColorSetting('sky', 'sunCore', 'map_color_sun'),
    MapColorSetting('sky', 'sunRim', 'map_color_sun_rim'),
    MapColorSetting('sky', 'sunTrack', 'map_color_sun_track'),
    MapColorSetting('sky', 'moonCore', 'map_color_moon'),
    MapColorSetting('sky', 'moonRim', 'map_color_moon_rim'),
    MapColorSetting('sky', 'moonTrack', 'map_color_moon_track'),
  ];

  final Map<String, Set<int>> _zoomLevels = {};
  final Map<String, double> _zooms = {};
  final Map<String, bool> _layers = {};
  final Map<String, int> _colors = {};

  Map<String, int> get colorOverrides => Map.unmodifiable(_colors);

  double zoom(String id) {
    final levels = _zoomLevels[id];
    if (levels != null) {
      return levels.isEmpty
          ? 24
          : levels.reduce((a, b) => a < b ? a : b).toDouble();
    }
    final saved = _zooms[id];
    if (saved != null) return saved;
    for (final item in zooms) {
      if (item.id == id) return item.fallback;
    }
    return 0;
  }

  /// Inclusive first and last zoom. A fresh setting runs from its built-in start through 22.
  (int, int) zoomRange(String id) {
    final levels = _zoomLevels[id];
    if (levels != null) {
      if (levels.isEmpty) return (22, 22);
      var low = 22;
      var high = 2;
      for (final level in levels) {
        if (level < low) low = level;
        if (level > high) high = level;
      }
      return (low, high);
    }
    return (zoom(id).round().clamp(2, 22), 22);
  }

  Future<void> setZoomRange(String id, int minZoom, int maxZoom) async {
    final start = minZoom.clamp(2, 22);
    final end = maxZoom.clamp(2, 22);
    final low = start <= end ? start : end;
    final high = start <= end ? end : start;
    _zooms.remove(id);
    _zoomLevels[id] = {for (var level = low; level <= high; level++) level};
    await _save();
  }

  bool zoomEnabled(String id, double level) {
    final levels = _zoomLevels[id];
    if (levels == null) return level >= zoom(id);
    return levels.contains(level.floor().clamp(2, 22));
  }

  /// A top-level MapLibre step expression supports gaps between enabled zooms.
  List<Object> zoomExpression(String id, Object on, Object off) => [
    'step',
    ['zoom'],
    off,
    for (var level = 2; level <= 22; level++) ...[
      level,
      zoomEnabled(id, level.toDouble()) ? on : off,
    ],
  ];

  Future<void> setZoomEnabled(String id, int level, bool enabled) async {
    if (level < 2 || level > 22) throw RangeError.range(level, 2, 22);
    final levels = _zoomLevels.putIfAbsent(
      id,
      () => {
        for (var z = 2; z <= 22; z++)
          if (zoomEnabled(id, z.toDouble())) z,
      },
    );
    if (enabled) {
      levels.add(level);
    } else {
      levels.remove(level);
    }
    await _save();
  }

  bool layerOn(String id) => _layers[id] ?? true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final masks = decoded['zoomLevels'];
      if (masks is Map) {
        for (final entry in masks.entries) {
          if (entry.value is List) {
            _zoomLevels[entry.key.toString()] = (entry.value as List)
                .whereType<int>()
                .where((z) => z >= 2 && z <= 22)
                .toSet();
          }
        }
      }
      final zooms = decoded['zooms'];
      if (zooms is Map) {
        for (final entry in zooms.entries) {
          final value = entry.value;
          if (value is num) _zooms[entry.key.toString()] = value.toDouble();
        }
      }
      final layers = decoded['layers'];
      if (layers is Map) {
        for (final entry in layers.entries) {
          if (entry.value is bool) {
            _layers[entry.key.toString()] = entry.value as bool;
          }
        }
      }
      final colors = decoded['colors'];
      if (colors is Map) {
        for (final entry in colors.entries) {
          final value = entry.value;
          if (value is int) _colors[entry.key.toString()] = value;
        }
      }
    } catch (error) {
      debugPrint('Unable to read map settings: $error');
    }
  }

  Future<void> setZoom(String id, double value) async {
    _zoomLevels.remove(id);
    _zooms[id] = value.clamp(2, 22);
    await _save();
  }

  Future<void> setLayer(String id, bool on) async {
    _layers[id] = on;
    await _save();
  }

  Future<void> setColor(
    String theme,
    String group,
    String field,
    int argb,
  ) async {
    _colors['$theme.$group.$field'] = argb;
    await _save();
  }

  Future<void> reset() async {
    _zoomLevels.clear();
    _zooms.clear();
    _layers.clear();
    _colors.clear();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'zoomLevels': _zoomLevels.map(
          (id, levels) => MapEntry(id, levels.toList()..sort()),
        ),
        'zooms': _zooms,
        'layers': _layers,
        'colors': _colors,
      }),
    );
    notifyListeners();
  }
}
