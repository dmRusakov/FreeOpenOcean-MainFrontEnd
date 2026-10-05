import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:free_open_ocean/services/map_object_icons.dart';

/// How a chart line is broken. [dasharray] is a MapLibre `line-dasharray`.
enum ChartLineType {
  solid,
  dashed,
  dotted,
  dashDot;

  static const choices = <ChartLineType>[solid, dashed, dotted, dashDot];

  static ChartLineType? named(String? name) {
    for (final type in choices) {
      if (type.name == name) return type;
    }
    return null;
  }

  String get labelKey => switch (this) {
    solid => 'map_line_solid',
    dashed => 'map_line_dashed',
    dotted => 'map_line_dotted',
    dashDot => 'map_line_dash_dot',
  };

  List<double>? get dasharray => switch (this) {
    solid => null,
    dashed => const [1, 2],
    dotted => const [0, 1.6],
    dashDot => const [2.5, 1.4, 0, 1.4],
  };

  String get cap => this == dotted || this == dashDot ? 'round' : 'butt';
}

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

/// Three zoom stops for a marine object: small icon, then full icon + name.
typedef ObjectZoomStops = ({int small, int full, int end});

/// Saved chart layers, zooms, and day/night colours.
class MapChartSettings extends ChangeNotifier {
  MapChartSettings._();

  static final instance = MapChartSettings._();

  static const _storageKey = 'mapChartSettings';

  /// Marine object families that use a 3-point zoom (2 zones).
  static const objectZoomIds = <String>{
    'marinaIcon',
    'anchorageIcon',
    'portIcon',
    'fuelIcon',
    'customsIcon',
    'serviceIcon',
    'dockIcon',
    'slipwayIcon',
    'places',
    'seamarks',
    'platformIcon',
    'lighthouseIcon',
  };

  /// Built-in (small, full+name, end) for each [objectZoomIds] entry.
  static const objectZoomStopDefaults = <String, ObjectZoomStops>{
    'marinaIcon': (small: 11, full: 13, end: 22),
    'anchorageIcon': (small: 11, full: 13, end: 22),
    'portIcon': (small: 12, full: 14, end: 22),
    'fuelIcon': (small: 12, full: 14, end: 22),
    'customsIcon': (small: 12, full: 14, end: 22),
    'serviceIcon': (small: 12, full: 14, end: 22),
    'dockIcon': (small: 12, full: 14, end: 22),
    'slipwayIcon': (small: 14, full: 15, end: 22),
    'places': (small: 12, full: 14, end: 22),
    'seamarks': (small: 12, full: 14, end: 22),
    'platformIcon': (small: 6, full: 12, end: 22),
    'lighthouseIcon': (small: 6, full: 12, end: 22),
  };

  /// Rows that used to share the [places] zoom before each got its own.
  static const _placesZoomAliases = <String>{
    'portIcon',
    'fuelIcon',
    'customsIcon',
    'serviceIcon',
    'dockIcon',
  };

  /// Legacy name zoom id kept in sync with the full+name stop.
  static const objectNameZoomId = <String, String>{
    'marinaIcon': 'marinaName',
    'anchorageIcon': 'anchorageName',
    'slipwayIcon': 'slipway',
    'platformIcon': 'platformName',
    'lighthouseIcon': 'lighthouseName',
  };

  static const zooms = <MapZoomSetting>[
    MapZoomSetting('iconFull', 'map_zoom_icon_full', 12),
    MapZoomSetting('roadNames', 'map_zoom_road_names', 14),
    MapZoomSetting('smallDetail', 'map_zoom_small_detail', 16),
    MapZoomSetting('marinaIcon', 'map_zoom_marina_icon', 11),
    MapZoomSetting('marinaName', 'map_zoom_marina_name', 13),
    MapZoomSetting('anchorageIcon', 'map_zoom_anchorage_icon', 11),
    MapZoomSetting('anchorageName', 'map_zoom_anchorage_name', 13),
    MapZoomSetting('portIcon', 'map_zoom_port_icon', 12),
    MapZoomSetting('fuelIcon', 'map_zoom_fuel_icon', 12),
    MapZoomSetting('customsIcon', 'map_zoom_customs_icon', 12),
    MapZoomSetting('serviceIcon', 'map_zoom_service_icon', 12),
    MapZoomSetting('dockIcon', 'map_zoom_dock_icon', 12),
    MapZoomSetting('slipwayIcon', 'map_zoom_slipway_icon', 14),
    MapZoomSetting('places', 'map_zoom_places', 12),
    MapZoomSetting('slipway', 'map_zoom_slipway', 15),
    MapZoomSetting('bridges', 'map_zoom_bridges', 13),
    MapZoomSetting('ferry', 'map_zoom_ferry', 6),
    MapZoomSetting('ferryNames', 'map_zoom_ferry_names', 9),
    MapZoomSetting('waterNames', 'map_zoom_water_names', 12),
    MapZoomSetting('countryNames', 'map_zoom_country_names', 2),
    MapZoomSetting('regionNames', 'map_zoom_region_names', 4),
    MapZoomSetting('localityNames', 'map_zoom_locality_names', 8),
    MapZoomSetting('tileIslandNames', 'map_zoom_tile_island_names', 4),
    MapZoomSetting('streams', 'map_zoom_streams', 14),
    MapZoomSetting('rivers', 'map_zoom_rivers', 9),
    MapZoomSetting('seamarks', 'map_zoom_seamarks', 12),
    MapZoomSetting('platformIcon', 'map_zoom_platform_icon', 6),
    MapZoomSetting('platformName', 'map_zoom_platform_name', 12),
    MapZoomSetting('platformZone', 'map_zoom_platform_zone', 12),
    MapZoomSetting('lighthouseIcon', 'map_zoom_lighthouse_icon', 6),
    MapZoomSetting('lighthouseName', 'map_zoom_lighthouse_name', 12),
    MapZoomSetting('graticule', 'map_zoom_graticule', 2),
    MapZoomSetting('equator', 'map_zoom_equator', 2),
    MapZoomSetting('landBase', 'map_color_land', 2),
    MapZoomSetting('landBeach', 'map_color_beach', 2),
    MapZoomSetting('islandFill', 'map_color_island', 4),
    MapZoomSetting('coastline', 'map_color_coast', 2),
    MapZoomSetting('boundaries', 'map_color_boundaries', 8),
    MapZoomSetting('landContour', 'map_color_contour', 7),
    MapZoomSetting('landContourLabel', 'map_color_contour_label', 7),
    MapZoomSetting('roadTrunk', 'map_color_road', 2),
    MapZoomSetting('roadCasing', 'map_color_road_casing', 2),
    MapZoomSetting('hillshade', 'map_color_hillshade_shadow', 11),
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
    MapLayerSetting('countryNames', 'map_layer_country_names'),
    MapLayerSetting('regionNames', 'map_layer_region_names'),
    MapLayerSetting('localityNames', 'map_layer_locality_names'),
    MapLayerSetting('tileIslandNames', 'map_layer_tile_island_names'),
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
    MapColorSetting('chart', 'boundaries', 'map_color_boundaries'),
    MapColorSetting('chart', 'islandFill', 'map_color_island'),
    MapColorSetting('chart', 'islandEdge', 'map_color_island_edge'),
    MapColorSetting('chart', 'graticule', 'map_color_graticule'),
    MapColorSetting('chart', 'equator', 'map_color_equator'),
    MapColorSetting('chart', 'meridian', 'map_color_meridian'),
    MapColorSetting('chart', 'labelStrong', 'map_color_label_strong'),
    MapColorSetting('chart', 'labelSoft', 'map_color_label_soft'),
    MapColorSetting('chart', 'labelFaint', 'map_color_label_faint'),
    MapColorSetting('chart', 'labelHalo', 'map_color_label_halo'),
    MapColorSetting('chart', 'labelCountry', 'map_color_label_country'),
    MapColorSetting('chart', 'labelRegion', 'map_color_label_region'),
    MapColorSetting('chart', 'labelLocality', 'map_color_label_locality'),
    MapColorSetting('chart', 'labelTileIsland', 'map_color_label_tile_island'),
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
    MapColorSetting('objects', 'marinaBorder', 'map_color_marina'),
    MapColorSetting('objects', 'anchorage', 'map_color_anchorage'),
    MapColorSetting('objects', 'anchorageBorder', 'map_color_anchorage'),
    MapColorSetting('objects', 'fuel', 'map_color_fuel'),
    MapColorSetting('objects', 'fuelBorder', 'map_color_fuel'),
    MapColorSetting('objects', 'customs', 'map_color_customs'),
    MapColorSetting('objects', 'customsBorder', 'map_color_customs'),
    MapColorSetting('objects', 'port', 'map_color_port'),
    MapColorSetting('objects', 'portBorder', 'map_color_port'),
    MapColorSetting('objects', 'service', 'map_color_service'),
    MapColorSetting('objects', 'serviceBorder', 'map_color_service'),
    MapColorSetting('objects', 'slipway', 'map_color_slipway'),
    MapColorSetting('objects', 'slipwayBorder', 'map_color_slipway'),
    MapColorSetting('objects', 'ferry', 'map_color_ferry'),
    MapColorSetting('objects', 'ferryRoute', 'map_color_ferry_route'),
    MapColorSetting('objects', 'dock', 'map_color_dock'),
    MapColorSetting('objects', 'dockBorder', 'map_color_dock'),
    MapColorSetting('objects', 'bridge', 'map_color_bridge'),
    MapColorSetting('objects', 'hazard', 'map_color_hazard'),
    MapColorSetting('objects', 'hazardBorder', 'map_color_hazard'),
    MapColorSetting('objects', 'navLight', 'map_color_nav_light'),
    MapColorSetting('objects', 'navLightBorder', 'map_color_nav_light'),
    MapColorSetting('objects', 'platform', 'map_color_platform'),
    MapColorSetting('objects', 'platformBorder', 'map_color_platform'),
    MapColorSetting('sky', 'sunCore', 'map_color_sun'),
    MapColorSetting('sky', 'sunRim', 'map_color_sun_rim'),
    MapColorSetting('sky', 'sunTrack', 'map_color_sun_track'),
    MapColorSetting('sky', 'moonCore', 'map_color_moon'),
    MapColorSetting('sky', 'moonRim', 'map_color_moon_rim'),
    MapColorSetting('sky', 'moonTrack', 'map_color_moon_track'),
  ];

  final Map<String, Set<int>> _zoomLevels = {};
  final Map<String, double> _zooms = {};
  final Map<String, List<int>> _zoomStops = {};
  final Map<String, bool> _layers = {};
  final Map<String, int> _colors = {};
  final Map<String, double> _linePx = {};
  final Map<String, ChartLineType> _lineType = {};
  final Map<String, ChartObjectIcon> _objectIcons = {};

  /// Built-in line thickness, in pixels.
  static const linePxFallback = <String, double>{
    'graticule': 1,
    'equator': 2,
    'coastline': 1.2,
    'boundaries': 0.5,
    'landContour': 0.6,
    'roadTrunk': 1.5,
    'roadMinor': 0.8,
    'roadCasing': 1,
  };

  /// Built-in stroke. The grid is broken; the equator is continuous.
  static const lineTypeFallback = <String, ChartLineType>{
    'graticule': ChartLineType.dashed,
    'equator': ChartLineType.solid,
    'boundaries': ChartLineType.dashed,
  };

  /// Choices offered for a chart line, half a pixel through 5 px.
  static const lineWidthChoices = <double>[
    0.5,
    1,
    1.5,
    2,
    2.5,
    3,
    3.5,
    4,
    4.5,
    5,
  ];

  Map<String, int> get colorOverrides => Map.unmodifiable(_colors);

  double zoom(String id) {
    // Name zooms follow the full+name stop of their icon family.
    for (final entry in objectNameZoomId.entries) {
      if (entry.value == id) return objectZoomStops(entry.key).full.toDouble();
    }
    if (objectZoomIds.contains(id)) {
      return objectZoomStops(id).small.toDouble();
    }
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

  /// Small-icon start, full-icon+name start, and last zoom for a marine object.
  ObjectZoomStops objectZoomStops(String id) {
    final saved = _zoomStops[id];
    if (saved != null && saved.length == 3) {
      return (small: saved[0], full: saved[1], end: saved[2]);
    }
    // Port / fuel / customs / service / dock used to share `places`.
    if (_placesZoomAliases.contains(id)) {
      final places = _zoomStops['places'];
      if (places != null && places.length == 3) {
        return (small: places[0], full: places[1], end: places[2]);
      }
    }
    final defaults =
        objectZoomStopDefaults[id] ?? (small: 2, full: 12, end: 22);
    final levels = _zoomLevels[id];
    final nameId = objectNameZoomId[id];
    final nameLevels = nameId == null ? null : _zoomLevels[nameId];
    final hasLegacy = levels != null ||
        nameLevels != null ||
        _zooms.containsKey(id) ||
        (nameId != null && _zooms.containsKey(nameId));
    if (!hasLegacy) return defaults;

    var small = defaults.small;
    var full = defaults.full;
    var end = defaults.end;
    if (levels != null && levels.isNotEmpty) {
      small = 22;
      end = 2;
      for (final level in levels) {
        if (level < small) small = level;
        if (level > end) end = level;
      }
    } else if (_zooms[id] != null) {
      small = _zooms[id]!.round().clamp(2, 22);
      end = 22;
    }
    if (nameLevels != null && nameLevels.isNotEmpty) {
      full = nameLevels.reduce((a, b) => a < b ? a : b);
    } else if (nameId != null && _zooms[nameId] != null) {
      full = _zooms[nameId]!.round();
    }
    full = full.clamp(small, end);
    return (small: small, full: full, end: end);
  }

  Future<void> setObjectZoomStops(
    String id,
    int small,
    int full,
    int end,
  ) async {
    var a = small.clamp(2, 22);
    var b = full.clamp(2, 22);
    var c = end.clamp(2, 22);
    final ordered = [a, b, c]..sort();
    a = ordered[0];
    b = ordered[1];
    c = ordered[2];
    _zoomStops[id] = [a, b, c];
    _zooms.remove(id);
    _zoomLevels[id] = {for (var level = a; level <= c; level++) level};
    final nameId = objectNameZoomId[id];
    if (nameId != null) {
      _zooms.remove(nameId);
      _zoomLevels[nameId] = {for (var level = b; level <= c; level++) level};
    }
    await _save();
  }

  /// On from [start] through the object's end stop; off elsewhere.
  List<Object> objectZoomExpression(
    String id, {
    required bool fromFull,
    required Object on,
    required Object off,
  }) {
    final stops = objectZoomStops(id);
    final start = fromFull ? stops.full : stops.small;
    final end = stops.end;
    return [
      'step',
      ['zoom'],
      off,
      for (var level = 2; level <= 22; level++) ...[
        level,
        level >= start && level <= end ? on : off,
      ],
    ];
  }

  /// [smallSize] until the full+name stop, then [fullSize], clipped to the end.
  /// When [smallSize] is omitted, uses 70% of [fullSize].
  List<Object> objectIconSizeExpression(
    String id,
    Object fullSize, {
    Object? smallSize,
  }) {
    final small = smallSize ?? <Object>['*', fullSize, 0.7];
    return objectZoomExpression(
      id,
      fromFull: true,
      on: fullSize,
      off: small,
    );
  }

  /// Inclusive first and last zoom. A fresh setting runs from its built-in start through 22.
  (int, int) zoomRange(String id) {
    if (objectZoomIds.contains(id)) {
      final stops = objectZoomStops(id);
      return (stops.small, stops.end);
    }
    for (final entry in objectNameZoomId.entries) {
      if (entry.value == id) {
        final stops = objectZoomStops(entry.key);
        return (stops.full, stops.end);
      }
    }
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
    if (objectZoomIds.contains(id)) {
      final mid = objectZoomStops(id).full.clamp(low, high);
      await setObjectZoomStops(id, low, mid, high);
      return;
    }
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

  /// Line thickness in pixels, snapped to the half-pixel choices.
  double linePx(String id) {
    final saved = _linePx[id];
    return snapLinePx(saved ?? linePxFallback[id] ?? 1);
  }

  static double snapLinePx(double px) {
    var nearest = lineWidthChoices.first;
    var gap = (px - nearest).abs();
    for (final choice in lineWidthChoices) {
      final next = (px - choice).abs();
      if (next < gap) {
        nearest = choice;
        gap = next;
      }
    }
    return nearest;
  }

  Future<void> setLinePx(String id, double px) async {
    _linePx[id] = snapLinePx(px);
    await _save();
  }

  ChartLineType lineType(String id) =>
      _lineType[id] ?? lineTypeFallback[id] ?? ChartLineType.solid;

  /// MapLibre `line-dasharray`. Null is a solid stroke.
  List<double>? lineDash(String id) => lineType(id).dasharray;

  /// Round caps turn a zero-length dash into a dot.
  String lineCap(String id) => lineType(id).cap;

  Future<void> setLineType(String id, ChartLineType type) async {
    _lineType[id] = type;
    await _save();
  }

  /// Flutter icon drawn for a Marine objects colour field.
  IconData objectIcon(String field) {
    final saved = _objectIcons[field];
    if (saved != null) return saved.data;
    return mapObjectIconDefaults[field] ?? Icons.place;
  }

  Future<void> setObjectIcon(String field, IconData icon) async {
    _objectIcons[field] = ChartObjectIcon.fromIconData(icon);
    await _save();
  }

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
      final lines = decoded['linePx'];
      if (lines is Map) {
        for (final entry in lines.entries) {
          final value = entry.value;
          if (value is num) {
            _linePx[entry.key.toString()] = snapLinePx(value.toDouble());
          }
        }
      }
      final strokes = decoded['lineType'];
      if (strokes is Map) {
        for (final entry in strokes.entries) {
          final type = ChartLineType.named(entry.value?.toString());
          if (type != null) _lineType[entry.key.toString()] = type;
        }
      }
      final icons = decoded['objectIcons'];
      if (icons is Map) {
        for (final entry in icons.entries) {
          final icon = ChartObjectIcon.fromJson(entry.value);
          if (icon != null) _objectIcons[entry.key.toString()] = icon;
        }
      }
      final stops = decoded['zoomStops'];
      if (stops is Map) {
        for (final entry in stops.entries) {
          final raw = entry.value;
          if (raw is! List || raw.length < 3) continue;
          final values = raw
              .whereType<num>()
              .map((n) => n.toInt().clamp(2, 22))
              .toList();
          if (values.length < 3) continue;
          final ordered = values.take(3).toList()..sort();
          _zoomStops[entry.key.toString()] = ordered;
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
    _zoomStops.clear();
    _layers.clear();
    _colors.clear();
    _linePx.clear();
    _lineType.clear();
    _objectIcons.clear();
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
        'zoomStops': _zoomStops,
        'layers': _layers,
        'colors': _colors,
        'linePx': _linePx,
        'lineType': _lineType.map((id, type) => MapEntry(id, type.name)),
        'objectIcons': _objectIcons.map(
          (field, icon) => MapEntry(field, icon.toJson()),
        ),
      }),
    );
    notifyListeners();
  }
}
