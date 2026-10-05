import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:geolocator/geolocator.dart';
import 'package:free_open_ocean/config/config.dart';
import 'package:free_open_ocean/services/map_chart_settings.dart';
import 'package:free_open_ocean/services/map_object_icons.dart';
import 'package:free_open_ocean/core/theme/marine_palette.dart';
import '../web_setup_stub.dart'
    if (dart.library.html) '../web_setup.dart'
    as web_setup;

/// A partial restyle of an existing layer. The generated [LayerProperties]
/// classes emit every field they know about, so changing one colour through
/// them would reset the rest of the layer - including a symbol layer's
/// text-field - to its default.
class _StylePatch implements LayerProperties {
  const _StylePatch(this._properties);

  final Map<String, dynamic> _properties;

  @override
  Map<String, dynamic> toJson({bool skipNulls = true}) => _properties;
}

class MapService {
  static final _islandPoints = _loadGeoJson('island_points');
  static final _islandGroups = _loadGeoJson('island_groups');
  static final _islandNames = _loadGeoJson('island_names');
  static final _graticule = _loadGeoJson('graticule');

  /// Symbol / line layers that open the marine-object info dialog on tap.
  static const marineObjectLayers = <String>[
    'boat-marinas',
    'boat-anchorages',
    'boat-fuel',
    'boat-port',
    'boat-customs',
    'boat-service',
    'boat-dock',
    'boat-places',
    'slipways',
    'seamark-marinas',
    'seamark-names',
    'oil-platforms',
    'oil-platform-zone',
    'lighthouses',
    'chart-ferry',
    'chart-ferry-labels',
  ];

  static Future<Object> _loadGeoJson(String name) async {
    final asset = 'assets/maps/$name.geojson';
    // Fetch plain JSON on web: the plugin converts inline maps to objects
    // without prototypes, which MapLibre 5's worker serializer rejects.
    if (kIsWeb) return web_setup.mapAssetUrl(asset);
    return jsonDecode(await rootBundle.loadString(asset))
        as Map<String, dynamic>;
  }

  /// Latitude where the sun is overhead at [utc], in degrees.
  /// Spencer's series, evaluated on the device from the clock.
  static double _solarDeclination(DateTime utc) {
    final yearStart = DateTime.utc(utc.year, 1, 1);
    final days = DateTime.utc(utc.year + 1, 1, 1).difference(yearStart).inDays;
    final n =
        utc.difference(yearStart).inMicroseconds / Duration.microsecondsPerDay +
        1;
    final g = 2 * pi * (n - 1) / days;
    final decl =
        0.006918 -
        0.399912 * cos(g) +
        0.070257 * sin(g) -
        0.006758 * cos(2 * g) +
        0.000907 * sin(2 * g) -
        0.002697 * cos(3 * g) +
        0.00148 * sin(3 * g);
    return decl * 180 / pi;
  }

  /// Longitude where the sun is overhead at [utc], degrees east.
  static double _subsolarLongitude(DateTime utc) {
    final yearStart = DateTime.utc(utc.year, 1, 1);
    final days = DateTime.utc(utc.year + 1, 1, 1).difference(yearStart).inDays;
    final n =
        utc.difference(yearStart).inMicroseconds / Duration.microsecondsPerDay +
        1;
    final g = 2 * pi * (n - 1) / days;
    final eqtime =
        229.18 *
        (0.000075 +
            0.001868 * cos(g) -
            0.032077 * sin(g) -
            0.014615 * cos(2 * g) -
            0.040849 * sin(2 * g));
    final utcMinutes = utc.hour * 60 + utc.minute + utc.second / 60;
    var lon = (720 - utcMinutes - eqtime) / 4;
    while (lon > 180) {
      lon -= 360;
    }
    while (lon < -180) {
      lon += 360;
    }
    return lon;
  }

  static String _sunLatitudeLabel(double latitude) {
    final hemisphere = latitude >= 0 ? 'N' : 'S';
    return 'Sun ${latitude.abs().toStringAsFixed(1)}°$hemisphere';
  }

  static Object _sunEquatorData(DateTime utc) {
    final latitude = _solarDeclination(utc);
    final longitude = _subsolarLongitude(utc);
    final line = <List<double>>[
      for (var lon = -180; lon <= 180; lon += 2)
        [lon.toDouble(), double.parse(latitude.toStringAsFixed(4))],
    ];
    final sun = [
      double.parse(longitude.toStringAsFixed(4)),
      double.parse(latitude.toStringAsFixed(4)),
    ];
    final collection = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'kind': 'sun'},
          'geometry': {'type': 'LineString', 'coordinates': line},
        },
        {
          'type': 'Feature',
          'properties': {'kind': 'label', 'name': _sunLatitudeLabel(latitude)},
          'geometry': {'type': 'Point', 'coordinates': sun},
        },
        {
          'type': 'Feature',
          'properties': {'kind': 'position'},
          'geometry': {'type': 'Point', 'coordinates': sun},
        },
      ],
    };
    if (kIsWeb) return web_setup.mapGeoJsonUrl(jsonEncode(collection));
    return collection;
  }

  /// Latitude and longitude where the moon is overhead at [utc].
  /// Low-precision lunar series, evaluated on the device from the clock.
  static (double, double) _moonOverhead(DateTime utc) {
    final d = utc.millisecondsSinceEpoch / 86400000.0 - 10957.5;
    final e = (23.4397 - 0.00000036 * d) * pi / 180;
    double wrap(double degrees) {
      final turns = degrees % 360;
      return turns < 0 ? turns + 360 : turns;
    }

    final l0 = wrap(218.316 + 13.176396 * d) * pi / 180;
    final anomaly = wrap(134.963 + 13.064993 * d) * pi / 180;
    final node = wrap(93.272 + 13.229350 * d) * pi / 180;
    final l = l0 + 6.289 * sin(anomaly) * pi / 180;
    final b = 5.128 * sin(node) * pi / 180;
    final ra = atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l));
    final dec = asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l));
    final gmst = wrap(280.16 + 360.9856235 * d) * pi / 180;
    var longitude = (ra - gmst) * 180 / pi;
    while (longitude > 180) {
      longitude -= 360;
    }
    while (longitude < -180) {
      longitude += 360;
    }
    return (dec * 180 / pi, longitude);
  }

  static String _moonLabel(double latitude) {
    final hemisphere = latitude >= 0 ? 'N' : 'S';
    return 'Moon ${latitude.abs().toStringAsFixed(1)}°$hemisphere';
  }

  /// One pass of the moon around the Earth, plus where it is overhead now.
  static Object _moonOrbitData(DateTime utc) {
    final samples = <(double, double)>[
      for (var minutes = -745; minutes <= 745; minutes += 20)
        _moonOverhead(utc.add(Duration(minutes: minutes))),
    ];
    final segments = <List<List<double>>>[<List<double>>[]];
    double? previousLongitude;
    for (final sample in samples) {
      final latitude = double.parse(sample.$1.toStringAsFixed(4));
      final longitude = double.parse(sample.$2.toStringAsFixed(4));
      if (previousLongitude != null &&
          (longitude - previousLongitude).abs() > 180 &&
          segments.last.isNotEmpty) {
        segments.add(<List<double>>[]);
      }
      segments.last.add([longitude, latitude]);
      previousLongitude = longitude;
    }
    final here = _moonOverhead(utc);
    final moon = [
      double.parse(here.$2.toStringAsFixed(4)),
      double.parse(here.$1.toStringAsFixed(4)),
    ];
    final collection = {
      'type': 'FeatureCollection',
      'features': [
        for (final segment in segments)
          if (segment.length > 1)
            {
              'type': 'Feature',
              'properties': {'kind': 'orbit'},
              'geometry': {'type': 'LineString', 'coordinates': segment},
            },
        {
          'type': 'Feature',
          'properties': {'kind': 'moon', 'name': _moonLabel(here.$1)},
          'geometry': {'type': 'Point', 'coordinates': moon},
        },
      ],
    };
    if (kIsWeb) return web_setup.mapGeoJsonUrl(jsonEncode(collection));
    return collection;
  }

  static const _styleLanguages = {'en', 'es', 'fr', 'pt', 'ru'};

  static String getStyleUrl(Brightness brightness, String languageCode) {
    final colorSchema = brightness == Brightness.dark ? 'dark' : 'light';
    final language = _styleLanguages.contains(languageCode)
        ? languageCode
        : 'en';
    return 'https://api.protomaps.com/styles/v5/$colorSchema/$language.json?key=${Config.apiKey}';
  }

  /// Coastline dots for islands under about 600 km², plus hillshade, land
  /// contours, and open-ocean island group names. From zoom 4 a small dot
  /// stands in until the land shape is large enough to see, so Moore's Island
  /// and the same small islands do not drop out of the chart.
  static Future<void> addIslandOverlay(
    MapLibreMapController controller,
    Brightness brightness,
    bool Function() isCurrent,
  ) async {
    try {
      final points = await _islandPoints;
      final groups = await _islandGroups;
      final islandNames = await _islandNames;
      final graticule = await _graticule;
      if (!isCurrent()) return;
      final layers = await controller.getLayerIds();
      if (!isCurrent()) return;
      // Above ocean fill, below waterways, roads and labels in the v5 style.
      if (!layers.contains('water_stream')) {
        debugPrint('Island overlay: expected Protomaps water layer missing');
        return;
      }
      final palette = MarinePalette.of(brightness);
      final chart = palette.chart;
      final settings = MapChartSettings.instance;
      final islandColor = chart.islandFill.hex;
      final islandOutline = chart.islandEdge.hex;
      await _addLandElevation(controller, palette, layers, isCurrent);
      if (!isCurrent()) return;
      await _applyChartBase(controller, palette, layers);
      if (!isCurrent()) return;
      await controller.addSource(
        'island-points',
        GeojsonSourceProperties(data: points, cluster: false),
      );
      if (!isCurrent()) return;
      // A small land-colored dot from zoom 4 while the island shape is
      // still missing from the tiles. Moore's Island (dotUntil about 5)
      // is one of these. Islands that stay tiny keep the dot.
      final islandDot = CircleLayerProperties(
        circleColor: islandColor,
        circleRadius: 2.4,
        circleOpacity: 1,
        circleStrokeColor: islandOutline,
        circleStrokeWidth: 0.6,
      );
      await controller.addCircleLayer(
        'island-points',
        'island-visibility',
        islandDot,
        belowLayerId: 'water_stream',
        filter: const [
          'all',
          [
            '>',
            ['get', 'dotUntil'],
            4,
          ],
          [
            '<',
            ['get', 'dotUntil'],
            7,
          ],
        ],
        minzoom: 4,
        maxzoom: 7,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addCircleLayer(
        'island-points',
        'island-visibility-small',
        islandDot,
        belowLayerId: 'water_stream',
        filter: const [
          '>=',
          ['get', 'dotUntil'],
          7,
        ],
        minzoom: 4,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Open-ocean group names for passagemaking. Coastal archipelagos are
      // omitted. Keep names visible throughout zoom levels 2 through 8.
      final labelColor = chart.labelSoft.hex;
      final labelHalo = chart.labelHalo.hex;
      await controller.addSource(
        'island-groups',
        GeojsonSourceProperties(data: groups),
      );
      if (!isCurrent()) return;
      await controller.addSymbolLayer(
        'island-groups',
        'island-group-labels',
        SymbolLayerProperties(
          textField: const ['get', 'name'],
          textFont: const ['Noto Sans Italic'],
          textSize: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            3,
            11,
            6,
            14,
          ],
          textColor: labelColor,
          textHaloColor: labelHalo,
          textHaloWidth: 1.2,
          textMaxWidth: 10,
          textPadding: 6,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const [
          '!',
          ['has', 'until'],
        ],
        minzoom: 2,
        // MapLibre's upper bound is exclusive; include the whole zoom-8 band.
        maxzoom: 9,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Cabo Verde is a country label on the basemap from zoom 3. The
      // basemap omits it at zoom 2, so this label covers only that gap.
      await controller.addSymbolLayer(
        'island-groups',
        'island-group-labels-early',
        SymbolLayerProperties(
          textField: const ['get', 'name'],
          textFont: const ['Noto Sans Italic'],
          textSize: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            2,
            12,
            3,
            12,
          ],
          textColor: labelColor,
          textHaloColor: labelHalo,
          textHaloWidth: 1.2,
          textMaxWidth: 10,
          textPadding: 6,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const [
          '==',
          ['get', 'until'],
          3,
        ],
        minzoom: 2,
        maxzoom: 3,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Latitude and longitude every 10 degrees. Latitude 0 is its own line.
      final gridColor = chart.graticule.hex;
      final equatorColor = chart.equator.hex;
      final gridZoom = settings.zoomRange('graticule');
      final equatorZoom = settings.zoomRange('equator');
      await controller.addSource(
        'graticule',
        GeojsonSourceProperties(data: graticule),
      );
      if (!isCurrent()) return;
      await controller.addLineLayer(
        'graticule',
        'graticule',
        LineLayerProperties(
          lineColor: gridColor,
          lineWidth: settings.linePx('graticule').toDouble(),
          lineOpacity: 0.85,
          lineCap: settings.lineCap('graticule'),
          lineDasharray: settings.lineDash('graticule'),
        ),
        belowLayerId: 'water_stream',
        filter: const [
          '!=',
          ['get', 'kind'],
          'equator',
        ],
        minzoom: gridZoom.$1.toDouble(),
        maxzoom: gridZoom.$2 >= 22 ? 24.0 : (gridZoom.$2 + 1).toDouble(),
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addLineLayer(
        'graticule',
        'chart-equator',
        LineLayerProperties(
          lineColor: equatorColor,
          lineWidth: settings.linePx('equator').toDouble(),
          lineOpacity: 1,
          lineCap: settings.lineCap('equator'),
          lineDasharray: settings.lineDash('equator'),
        ),
        belowLayerId: 'water_stream',
        filter: const [
          '==',
          ['get', 'kind'],
          'equator',
        ],
        minzoom: equatorZoom.$1.toDouble(),
        maxzoom: equatorZoom.$2 >= 22 ? 24.0 : (equatorZoom.$2 + 1).toDouble(),
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      final sunEquator = _sunEquatorData(DateTime.now().toUtc());
      await controller.addSource(
        'sun-equator',
        GeojsonSourceProperties(data: sunEquator),
      );
      if (!isCurrent()) return;
      await controller.addLineLayer(
        'sun-equator',
        'equator',
        LineLayerProperties(
          lineColor: chart.meridian.hex,
          lineWidth: 0.8,
          lineOpacity: 0.95,
        ),
        belowLayerId: 'water_stream',
        filter: const [
          '==',
          ['get', 'kind'],
          'sun',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.setLayerVisibility('equator', false);
      if (!isCurrent()) return;
      // The sun's overhead position right now, on the wide chart through zoom 4.
      await controller.addCircleLayer(
        'sun-equator',
        'sun-positions',
        CircleLayerProperties(
          circleColor: palette.sky.sunCore.hex,
          circleRadius: 7,
          circleOpacity: 0.95,
          circleStrokeColor: palette.sky.sunRim.hex,
          circleStrokeWidth: 1.4,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const [
          '==',
          ['get', 'kind'],
          'position',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addCircleLayer(
        'sun-equator',
        'sun-hit',
        CircleLayerProperties(
          circleColor: palette.sky.sunCore.hex,
          circleRadius: 18,
          circleOpacity: 0.01,
        ),
        filter: const [
          '==',
          ['get', 'kind'],
          'position',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: true,
      );
      if (!isCurrent()) return;
      await controller.addSymbolLayer(
        'sun-equator',
        'sun-equator-label',
        SymbolLayerProperties(
          textField: const ['get', 'name'],
          textFont: const ['Noto Sans Italic'],
          textSize: 11,
          textColor: chart.meridian.hex,
          textHaloColor: labelHalo,
          textHaloWidth: 1.2,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const [
          '==',
          ['get', 'kind'],
          'label',
        ],
        minzoom: 0,
        // Hidden once zoom passes 5. The bound is exclusive, so zoom 5
        // still shows the label.
        maxzoom: 5.01,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Moon's overhead track for one pass around the Earth, and where it
      // is right now. Both stay on the wide chart, zoom 0 through 4.
      final moonColor = palette.sky.moonTrack.hex;
      final moonOrbit = _moonOrbitData(DateTime.now().toUtc());
      await controller.addSource(
        'moon-orbit',
        GeojsonSourceProperties(data: moonOrbit),
      );
      if (!isCurrent()) return;
      await controller.addLineLayer(
        'moon-orbit',
        'moon-orbit',
        LineLayerProperties(
          lineColor: moonColor,
          lineWidth: 0.9,
          lineOpacity: 0.9,
        ),
        belowLayerId: 'water_stream',
        filter: const [
          '==',
          ['get', 'kind'],
          'orbit',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.setLayerVisibility('moon-orbit', false);
      if (!isCurrent()) return;
      await controller.addCircleLayer(
        'moon-orbit',
        'moon-position',
        CircleLayerProperties(
          circleColor: palette.sky.moonCore.hex,
          circleRadius: 6,
          circleOpacity: 0.95,
          circleStrokeColor: palette.sky.moonRim.hex,
          circleStrokeWidth: 1.2,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const [
          '==',
          ['get', 'kind'],
          'moon',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addCircleLayer(
        'moon-orbit',
        'moon-hit',
        CircleLayerProperties(
          circleColor: palette.sky.moonCore.hex,
          circleRadius: 18,
          circleOpacity: 0.01,
        ),
        filter: const [
          '==',
          ['get', 'kind'],
          'moon',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: true,
      );
      if (!isCurrent()) return;
      await controller.addSymbolLayer(
        'moon-orbit',
        'moon-label',
        SymbolLayerProperties(
          textField: const ['get', 'name'],
          textFont: const ['Noto Sans Italic'],
          textSize: 11,
          textColor: moonColor,
          textHaloColor: labelHalo,
          textHaloWidth: 1.2,
          textOffset: const [0, 1.1],
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const [
          '==',
          ['get', 'kind'],
          'moon',
        ],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Larger islands are named from zoom 4 until the basemap label
      // takes over at zoom 6 or 7. Smaller ones, such as Moore's Island,
      // are named from zoom 7 until the basemap label at zoom 8, 9, or 10.
      final islandNameColor = chart.labelFaint.hex;
      final islandNameHalo = chart.labelHalo.hex;
      await controller.addSource(
        'island-names',
        GeojsonSourceProperties(data: islandNames),
      );
      if (!isCurrent()) return;
      final belowNames = layers.contains('places_country')
          ? 'places_country'
          : null;
      const nameBands = <List<num>>[
        [6, 4, 6],
        [7, 4, 7],
        [8, 7, 8],
        [9, 7, 9],
        [10, 7, 10],
      ];
      const nameLayerIds = [
        'island-names',
        'island-names-later',
        'island-names-8',
        'island-names-9',
        'island-names-10',
      ];
      for (var i = 0; i < nameBands.length; i++) {
        final until = nameBands[i][0].toInt();
        final minZoom = nameBands[i][1].toDouble();
        final maxZoom = nameBands[i][2].toDouble();
        await controller.addSymbolLayer(
          'island-names',
          nameLayerIds[i],
          SymbolLayerProperties(
            textField: const ['get', 'name'],
            textFont: const ['Noto Sans Italic'],
            textSize: 10,
            textLetterSpacing: 0.1,
            textMaxWidth: 8,
            textColor: islandNameColor,
            textHaloColor: islandNameHalo,
            textHaloWidth: 1,
            textPadding: 0,
            textRadialOffset: 0.6,
            textVariableAnchor: const [
              'top',
              'bottom',
              'left',
              'right',
              'top-left',
              'top-right',
              'bottom-left',
              'bottom-right',
            ],
          ),
          belowLayerId: belowNames,
          filter: [
            '==',
            ['get', 'until'],
            until,
          ],
          minzoom: minZoom,
          maxzoom: maxZoom,
          enableInteraction: false,
        );
        if (!isCurrent()) return;
      }
      if (!isCurrent()) return;
      await _hideSmallCityDetail(controller, layers);
      await _hideLandObjects(controller, layers);
      await _addBoatPlaces(controller, palette, layers, isCurrent);
      if (!isCurrent()) return;
      await _addChartDetails(controller, palette, layers, isCurrent);
      if (!isCurrent()) return;
      await _applyChartLayers(controller);
    } catch (error) {
      if (isCurrent()) debugPrint('Unable to load island overlay: $error');
    }
  }

  /// Repaints the Protomaps basemap as a nautical chart: warm sand ashore,
  /// graded blue afloat, and a drawn coastline.
  ///
  /// The coastline is the reason this works at night. The night fills for
  /// land and water sit within a few percent luminance of each other, which
  /// is what keeps a full-screen chart from flooding the cockpit, so the
  /// boundary has to be carried by a line rather than by a brightness step.
  static Future<void> _applyChartBase(
    MapLibreMapController controller,
    MarinePalette palette,
    List<dynamic> layers,
  ) async {
    final chart = palette.chart;

    Future<void> patch(String layerId, Map<String, dynamic> paint) async {
      if (!layers.contains(layerId)) return;
      await controller.setLayerProperties(layerId, _StylePatch(paint));
    }

    final settings = MapChartSettings.instance;
    await patch('background', {
      // Chart backdrop is palette-only; it has no Settings colour row.
      'background-color': chart.backdrop.hex,
    });
    if (settings.layerOn('land')) {
      await patch('earth', {
        'fill-color': chart.landBase.hex,
        'fill-opacity': settings.zoomExpression('landBase', 1, 0),
      });
    } else if (layers.contains('earth')) {
      await controller.setLayerVisibility('earth', false);
    }
    if (settings.layerOn('landBeach')) {
      await patch('landuse_beach', {
        'fill-color': chart.landBeach.hex,
        'fill-opacity': settings.zoomExpression('landBeach', 1, 0),
      });
    } else if (layers.contains('landuse_beach')) {
      await controller.setLayerVisibility('landuse_beach', false);
    }
    if (settings.layerOn('coast')) {
      await patch('water', {'fill-color': chart.seaBase.hex});
    } else if (layers.contains('water')) {
      await controller.setLayerVisibility('water', false);
    }
    await patch('water_waterway_label', {'text-color': chart.labelSoft.hex});
    if (settings.layerOn('boundaries')) {
      final boundaryOpacity = settings.zoomExpression('boundaries', 1, 0);
      final boundaryWidth = settings.linePx('boundaries');
      final boundaryDash = settings.lineDash('boundaries');
      final boundaryCap = settings.lineCap('boundaries');
      await patch('boundaries', {
        'line-color': chart.boundaries.hex,
        'line-width': boundaryWidth,
        'line-cap': boundaryCap,
        'line-dasharray': ?boundaryDash,
        'line-opacity': boundaryOpacity,
      });
      await patch('boundaries_country', {
        'line-color': chart.boundaries.hex,
        'line-width': boundaryWidth < 1 ? 1.0 : boundaryWidth * 2,
        'line-cap': boundaryCap,
        'line-dasharray': ?boundaryDash,
        'line-opacity': boundaryOpacity,
      });
    } else {
      for (final id in ['boundaries', 'boundaries_country']) {
        if (layers.contains(id)) {
          await controller.setLayerVisibility(id, false);
        }
      }
    }
    // Dam fills and pier lines take the coastline colour and follow the
    // Coastline switch. They have no Settings row of their own.
    if (settings.layerOn('coastline')) {
      await patch('landuse_pier', {'fill-color': chart.coastline.hex});
      await patch('roads_pier', {'line-color': chart.coastline.hex});
      // The pedestrian layer is filtered down to dams. A dam is a hard edge
      // on the water, so it takes the same line as the coast and the piers.
      await patch('landuse_pedestrian', {'fill-color': chart.coastline.hex});
    } else {
      for (final id in ['landuse_pier', 'roads_pier', 'landuse_pedestrian']) {
        if (layers.contains(id)) {
          await controller.setLayerVisibility(id, false);
        }
      }
    }
    await _muteRoads(palette, patch);
    // The basemap halos are tuned to its own water colour and read as a grey
    // glow against ours, worst of all at night.
    for (final id in ['water_label_ocean', 'water_label_lakes']) {
      await patch(id, {
        'text-color': chart.labelSoft.hex,
        'text-halo-color': chart.labelHalo.hex,
      });
    }
    Future<void> patchPlaceLabel(
      String layerId,
      String settingId,
      String textColor,
    ) async {
      if (!layers.contains(layerId)) return;
      if (!settings.layerOn(settingId)) {
        await controller.setLayerVisibility(layerId, false);
        return;
      }
      await controller.setLayerVisibility(layerId, true);
      await patch(layerId, {
        'text-color': textColor,
        'text-halo-color': chart.labelHalo.hex,
        'text-opacity': settings.zoomExpression(settingId, 1, 0),
      });
    }

    await patchPlaceLabel(
      'places_country',
      'countryNames',
      chart.labelCountry.hex,
    );
    await patchPlaceLabel(
      'places_region',
      'regionNames',
      chart.labelRegion.hex,
    );
    await patchPlaceLabel(
      'places_locality',
      'localityNames',
      chart.labelLocality.hex,
    );
    await patchPlaceLabel(
      'earth_label_islands',
      'tileIslandNames',
      chart.labelTileIsland.hex,
    );
    for (final id in [
      'places_subplace',
      'roads_labels_major',
      'roads_labels_minor',
      'water_waterway_label',
    ]) {
      await patch(id, {'text-halo-color': chart.labelHalo.hex});
    }

    await _redrawWaterways(controller, palette, layers);

    if (layers.contains('chart-coastline')) {
      await controller.removeLayer('chart-coastline');
    }
    if (!MapChartSettings.instance.layerOn('coastline')) return;
    final coastZoom = settings.zoomRange('coastline');
    // Outline the earth polygons for a drawn shore. Sit under the water
    // fill so tile-clip edges that cut straight across open water stay
    // hidden; the real shore still shows where land meets the sea.
    await controller.addLineLayer(
      'protomaps',
      'chart-coastline',
      LineLayerProperties(
        lineColor: chart.coastline.hex,
        lineWidth: settings.linePx('coastline'),
        lineCap: settings.lineCap('coastline'),
        lineDasharray: settings.lineDash('coastline'),
        lineOpacity: 0.95,
        lineJoin: 'round',
      ),
      sourceLayer: 'earth',
      belowLayerId: layers.contains('water') ? 'water' : null,
      filter: const ['==', '\$type', 'Polygon'],
      minzoom: coastZoom.$1.toDouble(),
      maxzoom: coastZoom.$2 >= 22 ? 24.0 : (coastZoom.$2 + 1).toDouble(),
      enableInteraction: false,
    );
  }

  /// Trunk roads, their links, and the bridge and tunnel variants of each.
  static const _trunkRoadLayers = [
    'roads_highway',
    'roads_major',
    'roads_link',
    'roads_bridges_highway',
    'roads_bridges_major',
    'roads_bridges_link',
    'roads_tunnels_highway',
    'roads_tunnels_major',
    'roads_tunnels_link',
  ];

  static const _minorRoadLayers = [
    'roads_minor',
    'roads_minor_service',
    'roads_other',
    'roads_bridges_minor',
    'roads_bridges_other',
    'roads_tunnels_minor',
    'roads_tunnels_other',
  ];

  static const _roadCasingLayers = [
    'roads_highway_casing_early',
    'roads_highway_casing_late',
    'roads_major_casing_early',
    'roads_major_casing_late',
    'roads_link_casing',
    'roads_minor_casing',
    'roads_minor_service_casing',
    'roads_bridges_highway_casing',
    'roads_bridges_major_casing',
    'roads_bridges_link_casing',
    'roads_bridges_minor_casing',
    'roads_bridges_other_casing',
    'roads_tunnels_highway_casing',
    'roads_tunnels_major_casing',
    'roads_tunnels_link_casing',
    'roads_tunnels_minor_casing',
    'roads_tunnels_other_casing',
  ];

  /// Drops the road network back to shore context.
  ///
  /// The basemap paints roads as the subject of the map: white ribbons on
  /// land by day, and by night a highway at `#474747` that is the brightest
  /// thing on screen by a wide margin. Neither belongs on a chart, where the
  /// water is the subject and roads only answer "can I get to this harbour,
  /// and where does that bridge cross".
  ///
  /// So the fills move to within a few percent of the land they cross and the
  /// casing goes darker than the land. Roads still read, as an engraved
  /// texture rather than a network, and the night chart gets its brightest
  /// pixel back for the things that have to be seen.
  static Future<void> _muteRoads(
    MarinePalette palette,
    Future<void> Function(String, Map<String, dynamic>) patch,
  ) async {
    final chart = palette.chart;
    final settings = MapChartSettings.instance;
    Future<void> hide(String id) async {
      await patch(id, {
        'line-opacity': 0,
        'icon-opacity': 0,
        'text-opacity': 0,
      });
    }

    Future<void> paintLine(String layerId, String settingId) async {
      await patch(layerId, {
        'line-color': switch (settingId) {
          'roadMinor' => chart.roadMinor.hex,
          'roadCasing' => chart.roadCasing.hex,
          _ => chart.roadTrunk.hex,
        },
        'line-width': settings.linePx(settingId),
        'line-cap': settings.lineCap(settingId),
        'line-dasharray': ?settings.lineDash(settingId),
        'line-opacity': settings.zoomExpression(
          settingId == 'roadMinor' ? 'smallDetail' : settingId,
          1,
          0,
        ),
      });
    }

    for (final id in _trunkRoadLayers) {
      if (settings.layerOn('roadTrunk')) {
        await paintLine(id, 'roadTrunk');
      } else {
        await hide(id);
      }
    }
    for (final id in _minorRoadLayers) {
      if (settings.layerOn('roadMinor')) {
        await paintLine(id, 'roadMinor');
      } else {
        await hide(id);
      }
    }
    for (final id in _roadCasingLayers) {
      if (settings.layerOn('roadCasing')) {
        await paintLine(id, 'roadCasing');
      } else {
        await hide(id);
      }
    }
    for (final id in ['roads_labels_major', 'roads_labels_minor']) {
      if (settings.layerOn('roadNames')) {
        await patch(id, {'text-color': chart.roadLabel.hex});
      } else {
        await hide(id);
      }
    }
    // Shields are a motorist's cue and carry a filled badge, so dimming the
    // number alone would leave the badge shouting.
    if (settings.layerOn('roadNames')) {
      await patch('roads_shields', {
        'text-color': chart.roadLabel.hex,
        'icon-opacity': 0.45,
        'text-opacity': 0.8,
      });
    } else {
      await hide('roads_shields');
    }
    await patch('roads_oneway', {
      'icon-opacity': settings.layerOn('roadTrunk') ? 0.35 : 0,
    });
  }

  /// Moves river and stream centrelines underneath the water fill.
  ///
  /// The basemap draws them on top, so a river wide enough to also be a water
  /// polygon ends up with a line running down the middle of open water, which
  /// says nothing a skipper can use. Drawn underneath, the polygon covers its
  /// own centreline, while a narrow stream that has no polygon still shows
  /// against the land. The name keeps its own layer either way, so a wide
  /// river stays labelled once the line is gone.
  static Future<void> _redrawWaterways(
    MapLibreMapController controller,
    MarinePalette palette,
    List<dynamic> layers,
  ) async {
    if (layers.contains('chart-waterway-river')) return;
    for (final id in ['water_stream', 'water_river']) {
      if (layers.contains(id)) await controller.setLayerVisibility(id, false);
    }
    if (!layers.contains('water')) return;
    if (!MapChartSettings.instance.layerOn('waterways')) return;
    // Where the centreline is wider than the water polygon it shows as the
    // bank. A stream keeps the coastline colour. A river is open water, so
    // it takes the ocean fill.
    final bank = palette.chart.coastline.hex;
    final river = palette.chart.seaBase.hex;
    // Same widths and zoom floors the basemap used, so narrow water reads the
    // way it always did where there is no polygon to hide it.
    await controller.addLineLayer(
      'protomaps',
      'chart-waterway-stream',
      LineLayerProperties(
        lineOpacity: MapChartSettings.instance.layerOn('streams')
            ? MapChartSettings.instance.zoomExpression('streams', 1, 0)
            : 0,
        lineColor: bank,
        lineWidth: 0.6,
        lineJoin: 'round',
        lineCap: 'round',
      ),
      sourceLayer: 'water',
      belowLayerId: 'water',
      filter: const [
        '==',
        ['get', 'kind'],
        'stream',
      ],
      minzoom: MapChartSettings.instance.zoom('streams'),
      enableInteraction: false,
    );
    await controller.addLineLayer(
      'protomaps',
      'chart-waterway-river',
      LineLayerProperties(
        lineOpacity: MapChartSettings.instance.layerOn('rivers')
            ? MapChartSettings.instance.zoomExpression('rivers', 1, 0)
            : 0,
        lineColor: river,
        lineWidth: const [
          'interpolate',
          ['exponential', 1.6],
          ['zoom'],
          9,
          0,
          9.5,
          1,
          18,
          12,
        ],
        lineJoin: 'round',
        lineCap: 'round',
      ),
      sourceLayer: 'water',
      belowLayerId: 'water',
      filter: const [
        '==',
        ['get', 'kind'],
        'river',
      ],
      minzoom: MapChartSettings.instance.zoom('rivers'),
      enableInteraction: false,
    );
  }

  /// Local streets, their bridges, neighbourhoods, and smaller towns stay
  /// off until zoom 16. Larger cities (population rank 10 and up) stay.
  /// Road names and route shields come on once the zoom is past 14.
  static double get smallDetailZoom =>
      MapChartSettings.instance.zoom('smallDetail');
  static double get roadNameZoom => MapChartSettings.instance.zoom('roadNames');

  static const _roadNameLayers = [
    'roads_labels_major',
    'roads_labels_minor',
    'roads_shields',
  ];

  static const _smallRoadLayers = [
    'roads_tunnels_other_casing',
    'roads_tunnels_minor_casing',
    'roads_tunnels_other',
    'roads_tunnels_minor',
    'roads_minor_service_casing',
    'roads_minor_casing',
    'roads_other',
    'roads_minor_service',
    'roads_minor',
    'roads_bridges_other_casing',
    'roads_bridges_minor_casing',
    'roads_bridges_other',
    'roads_bridges_minor',
    'places_subplace',
  ];

  static bool? _smallDetailShown;
  static bool? _roadNamesShown;
  static int _smallDetailEpoch = 0;

  static Future<void> _hideSmallCityDetail(
    MapLibreMapController controller,
    List<dynamic> layers,
  ) async {
    if (layers.contains('roads_oneway')) {
      await controller.setFilter('roads_oneway', const [
        'all',
        [
          '==',
          ['get', 'oneway'],
          'yes',
        ],
        [
          'in',
          ['get', 'kind'],
          [
            'literal',
            ['highway', 'major_road'],
          ],
        ],
      ]);
    }
    final zoom = controller.cameraPosition?.zoom ?? 5;
    await _applySmallDetail(controller, layers, zoom, ++_smallDetailEpoch);
  }

  /// Shows or hides local streets and smaller towns when the camera crosses
  /// zoom 16, and road names when it passes zoom 14. Safe to call on every
  /// camera move.
  static void syncSmallDetail(MapLibreMapController controller, double zoom) {
    final show =
        MapChartSettings.instance.layerOn('smallDetail') &&
        MapChartSettings.instance.layerOn('roadMinor') &&
        MapChartSettings.instance.zoomEnabled('smallDetail', zoom);
    final showNames =
        MapChartSettings.instance.layerOn('roadNames') &&
        MapChartSettings.instance.zoomEnabled('roadNames', zoom);
    if (_smallDetailShown == show && _roadNamesShown == showNames) return;
    _applySmallDetail(controller, null, zoom, ++_smallDetailEpoch);
  }

  static Future<void> _applySmallDetail(
    MapLibreMapController controller,
    List<dynamic>? layers,
    double zoom,
    int epoch,
  ) async {
    final show =
        MapChartSettings.instance.layerOn('smallDetail') &&
        MapChartSettings.instance.layerOn('roadMinor') &&
        MapChartSettings.instance.zoomEnabled('smallDetail', zoom);
    final ids = layers ?? await controller.getLayerIds();
    if (epoch != _smallDetailEpoch) return;
    for (final id in _smallRoadLayers) {
      if (ids.contains(id)) {
        await controller.setLayerVisibility(id, show);
      }
    }
    if (epoch != _smallDetailEpoch) return;
    if (ids.contains('places_locality')) {
      final localityOn = MapChartSettings.instance.layerOn('localityNames');
      await controller.setLayerVisibility('places_locality', localityOn);
      if (localityOn) {
        // When Local streets are off, only high-rank cities stay. The City /
        // town names switch can still hide the whole layer.
        await controller.setFilter(
          'places_locality',
          show
              ? const [
                  '==',
                  ['get', 'kind'],
                  'locality',
                ]
              : const [
                  'all',
                  [
                    '==',
                    ['get', 'kind'],
                    'locality',
                  ],
                  [
                    '>=',
                    ['get', 'population_rank'],
                    10,
                  ],
                ],
        );
      }
    }
    final showNames =
        MapChartSettings.instance.layerOn('roadNames') &&
        MapChartSettings.instance.zoomEnabled('roadNames', zoom);
    for (final id in _roadNameLayers) {
      if (ids.contains(id)) {
        await controller.setLayerVisibility(id, showNames);
      }
    }
    if (epoch == _smallDetailEpoch) {
      _smallDetailShown = show;
      _roadNamesShown = showNames;
    }
  }

  /// Hides chart groups the Map settings page has turned off.
  static Future<void> _applyChartLayers(
    MapLibreMapController controller,
  ) async {
    final chart = MapChartSettings.instance;
    final ids = await controller.getLayerIds();
    Future<void> hideAll(List<String> layers) async {
      for (final id in layers) {
        if (ids.contains(id)) await controller.setLayerVisibility(id, false);
      }
    }

    Future<void> hide(String group, List<String> layers) async {
      if (chart.layerOn(group)) return;
      await hideAll(layers);
    }

    await hide('islands', const [
      'island-visibility',
      'island-visibility-small',
      'island-group-labels',
      'island-group-labels-early',
      'island-names',
      'island-names-later',
      'island-names-8',
      'island-names-9',
      'island-names-10',
    ]);
    await hide('graticule', const ['graticule', 'chart-equator']);
    if (chart.layerOn('graticule')) {
      await hide('equator', const ['chart-equator']);
    }
    await hide('sky', const [
      'equator',
      'sun-positions',
      'sun-hit',
      'sun-equator-label',
      'moon-orbit',
      'moon-position',
      'moon-hit',
      'moon-label',
    ]);
    if (chart.layerOn('sky')) {
      await hide('meridian', const ['equator', 'sun-equator-label']);
      await hide('moonCore', const ['moon-position', 'moon-hit', 'moon-label']);
      await hide('moonTrack', const ['moon-orbit']);
    }
    await hide('coastline', const ['chart-coastline']);
    await hide('boundaries', const ['boundaries', 'boundaries_country']);
    await hide('waterways', const [
      'chart-waterway-stream',
      'chart-waterway-river',
    ]);
    if (chart.layerOn('waterways')) {
      await hide('streams', const ['chart-waterway-stream']);
      await hide('rivers', const ['chart-waterway-river']);
    }
    await hide('contours', const [
      'ocean-contour-lines',
      'ocean-contour-labels',
    ]);
    if (chart.layerOn('contours')) {
      await hide('label', const ['ocean-contour-labels']);
    }
    await hide('landContour', const ['land-contour-lines']);
    await hide('landContourLabel', const ['land-contour-labels']);
    await hide('hillshade', const ['land-elevation', 'ocean-elevation']);
    await hide('marinas', const ['boat-marinas']);
    await hide('anchorage', const ['boat-anchorages']);
    await hide('places', const ['boat-port', 'boat-places']);
    await hide('fuel', const ['boat-fuel']);
    await hide('customs', const ['boat-customs']);
    await hide('service', const ['boat-service']);
    await hide('slipways', const ['slipways']);
    await hide('bridges', const ['boat-bridge-labels']);
    await hide('harbour', const [
      'chart-marina-area',
      'chart-dock',
      'chart-canal',
      'boat-dock',
    ]);
    await hide('ferries', const ['chart-ferry', 'chart-ferry-labels']);
    if (chart.layerOn('ferries')) {
      await hide('ferryNames', const ['chart-ferry-labels']);
    }
    await hide('waterNames', const ['chart-water-names']);
    await hide('countryNames', const ['places_country']);
    await hide('regionNames', const ['places_region']);
    await hide('localityNames', const ['places_locality']);
    await hide('tileIslandNames', const ['earth_label_islands']);
    await hide('seamarks', const ['seamark-marinas', 'seamark-names']);
    await hide('platforms', const ['oil-platforms', 'oil-platform-zone']);
    await hide('lighthouses', const ['lighthouses']);
    await hide('roadTrunk', [..._trunkRoadLayers, 'roads_oneway']);
    await hide('roadMinor', _minorRoadLayers);
    if (!chart.layerOn('roadMinor') || !chart.layerOn('smallDetail')) {
      await hideAll(_smallRoadLayers);
    }
    await hide('roadCasing', _roadCasingLayers);
    await hide('roadNames', _roadNameLayers);
  }

  /// Parks, beaches, cafes, trains, buildings, and the other land places are
  /// hidden. Piers, dams, and ferry terminals stay. Beach sand fill stays;
  /// the park and beach icons do not.
  static Future<void> _hideLandObjects(
    MapLibreMapController controller,
    List<dynamic> layers,
  ) async {
    const landObjects = [
      'landcover',
      'landuse_park',
      'landuse_urban_green',
      'landuse_hospital',
      'landuse_industrial',
      'landuse_school',
      'landuse_zoo',
      'landuse_aerodrome',
      'landuse_runway',
      'roads_runway',
      'roads_taxiway',
      'roads_rail',
      'buildings',
      'address_label',
      'pois',
    ];
    for (final id in landObjects) {
      if (layers.contains(id)) {
        await controller.setLayerVisibility(id, false);
      }
    }
    if (layers.contains('landuse_pedestrian')) {
      await controller.setFilter('landuse_pedestrian', const [
        '==',
        ['get', 'kind'],
        'dam',
      ]);
    }
  }

  /// Boat places from the chart tiles: marinas, fuel, ferries, slipways,
  /// customs, port offices, and the other harbour kinds. Bridge lines stay
  /// in the road layers; this adds their names. The tiles have no clearance
  /// height, so the label is the bridge name.
  static const _boatKinds = [
    'anchorage',
    'beacon',
    'boat',
    'boat_rental',
    'boat_repair',
    'boat_storage',
    'cruise_terminal',
    'customs',
    'dock',
    'ferry_terminal',
    'fuel',
    'harbourmaster',
    'lighthouse',
    'life_ring',
    'lock',
    'marina',
    'mooring',
    'naval_base',
    'ship_chandler',
    'slipway',
  ];

  /// Harbour kinds that each have their own settings zoom and chart layer.
  static const _boatKindGroups = <String, List<String>>{
    'port': ['harbourmaster', 'naval_base'],
    'fuel': ['fuel'],
    'customs': ['customs'],
    'service': [
      'ship_chandler',
      'boat',
      'boat_rental',
      'boat_repair',
      'boat_storage',
    ],
    'dock': ['dock'],
  };

  static const _boatKindZoomIds = <String, String>{
    'port': 'portIcon',
    'fuel': 'fuelIcon',
    'customs': 'customsIcon',
    'service': 'serviceIcon',
    'dock': 'dockIcon',
  };

  static const _boatOwnLayerKinds = <String>{
    'marina',
    'anchorage',
    'slipway',
    'lighthouse',
    'harbourmaster',
    'naval_base',
    'fuel',
    'customs',
    'ship_chandler',
    'boat',
    'boat_rental',
    'boat_repair',
    'boat_storage',
    'dock',
  };

  /// Gap between a harbour icon and its name, on top of the offset each
  /// layer already carried. MapLibre measures text-offset in ems and these
  /// labels are 11 px, so an em is 11 px and 5 px of clearance is 0.45 of one.
  static const _labelClearanceEm = 0.45;
  static const _placeLabelOffset = 0.8 + _labelClearanceEm;
  static const _seamarkLabelOffset = 1.1 + _labelClearanceEm;

  /// Point objects use a half-size icon until this zoom, then the full icon.
  /// The name and the type line come on together. See AGENTS.md.
  static double get objectIconFullZoom =>
      MapChartSettings.instance.zoom('iconFull');
  static const objectTypeFontScale = 0.75;

  static const _objectTypeLabel = [
    'match',
    ['get', 'kind'],
    'marina',
    'Marina',
    'harbour',
    'Marina',
    'anchorage',
    'Anchorage',
    'fuel',
    'Fuel',
    'customs',
    'Customs',
    'harbourmaster',
    'Harbour office',
    'naval_base',
    'Naval base',
    'ferry_terminal',
    'Ferry terminal',
    'cruise_terminal',
    'Cruise terminal',
    'slipway',
    'Slipway',
    'dock',
    'Dock',
    'lighthouse',
    'Lighthouse',
    'light_major',
    'Major light',
    'beacon',
    'Beacon',
    'boat',
    'Boat service',
    'boat_rental',
    'Boat rental',
    'boat_repair',
    'Boat repair',
    'boat_storage',
    'Boat storage',
    'ship_chandler',
    'Chandler',
    'life_ring',
    'Life ring',
    'lock',
    'Lock',
    'mooring',
    'Mooring',
    'small_craft_facility',
    'Small craft',
    'offshore_platform',
    'Offshore oil platforms',
    '',
  ];

  /// Name on the first line, object type under it in a smaller size.
  /// Both lines are left-aligned by the layer. [fromZoom] hides the label
  /// until that zoom when the icon is already on the chart.
  static List<Object> _objectLabel({num? fromZoom}) {
    final label = [
      'format',
      [
        'case',
        [
          '>',
          [
            'length',
            [
              'to-string',
              [
                'coalesce',
                ['get', 'name'],
                '',
              ],
            ],
          ],
          0,
        ],
        [
          'concat',
          [
            'to-string',
            [
              'coalesce',
              ['get', 'name'],
              '',
            ],
          ],
          '\n',
        ],
        '',
      ],
      <String, Object>{},
      _objectTypeLabel,
      {'font-scale': objectTypeFontScale},
    ];
    if (fromZoom == null) return label;
    return [
      'step',
      ['zoom'],
      '',
      fromZoom,
      label,
    ];
  }

  /// Name, type, then the light description. Hidden until zoom 12, the same
  /// point the platform name comes on.
  static List<Object> _lighthouseLabel() => [
    'step',
    ['zoom'],
    '',
    MapChartSettings.instance.zoom('lighthouseName'),
    [
      'format',
      [
        'case',
        [
          '>',
          [
            'length',
            [
              'to-string',
              [
                'coalesce',
                ['get', 'name'],
                '',
              ],
            ],
          ],
          0,
        ],
        [
          'concat',
          [
            'to-string',
            [
              'coalesce',
              ['get', 'name'],
              '',
            ],
          ],
          '\n',
        ],
        '',
      ],
      <String, Object>{},
      _objectTypeLabel,
      {'font-scale': objectTypeFontScale},
      [
        'case',
        [
          '>',
          [
            'length',
            [
              'to-string',
              [
                'coalesce',
                ['get', 'detail'],
                '',
              ],
            ],
          ],
          0,
        ],
        [
          'concat',
          '\n',
          [
            'to-string',
            ['get', 'detail'],
          ],
        ],
        '',
      ],
      {'font-scale': objectTypeFontScale},
    ],
  ];

  /// Shared base for the small-icon zone so every marine object matches
  /// there; full-icon size may still differ by kind.
  static const _marineObjectSmallBase = 0.9;
  static const _marineObjectSmallFraction = 0.7;

  /// Full-icon zone icon+border: 0.8³ then +20%.
  static const _marineObjectFullFraction = 0.8 * 0.8 * 0.8 * 1.2;

  /// Name size in the full-icon zone: prior shrunk size (11×0.64) then 40% larger.
  static const _objectLabelTextSize = 11 * 0.64 * 1.4;

  /// Extra text-offset (ems) to push the name 5 px right of the icon.
  static const _objectLabelRightShiftEm = 5 / _objectLabelTextSize;

  /// Chart icons are drawn at half the historical MapLibre sizes so they
  /// stay readable without covering the chart.
  static const _marineObjectIconScale = 0.5;

  static Object _scaledIconSize(Object fullSize) => [
    '*',
    fullSize,
    _marineObjectIconScale,
  ];

  static List<Object> _objectIconSize(
    Object fullSize, [
    String? objectZoomId,
  ]) {
    final settings = MapChartSettings.instance;
    if (objectZoomId != null) {
      return settings.objectIconSizeExpression(
        objectZoomId,
        _scaledIconSize(['*', fullSize, _marineObjectFullFraction]),
        smallSize: _scaledIconSize(
          _marineObjectSmallBase * _marineObjectSmallFraction,
        ),
      );
    }
    final scaled = _scaledIconSize(fullSize);
    return settings.zoomExpression('iconFull', scaled, [
      '*',
      scaled,
      0.5,
    ]);
  }

  static Color _objectFieldColor(MarineObjects objects, String field) {
    return switch (field) {
      'marina' => objects.marina,
      'anchorage' => objects.anchorage,
      'fuel' => objects.fuel,
      'customs' => objects.customs,
      'port' => objects.port,
      'service' => objects.service,
      'dock' => objects.dock,
      'slipway' => objects.slipway,
      'hazard' => objects.hazard,
      'platform' => objects.platform,
      'navLight' => objects.navLight,
      _ => objects.marina,
    };
  }

  static Color _objectBorderColor(MarineObjects objects, String field) {
    return switch (field) {
      'marina' => objects.marinaBorder,
      'anchorage' => objects.anchorageBorder,
      'fuel' => objects.fuelBorder,
      'customs' => objects.customsBorder,
      'port' => objects.portBorder,
      'service' => objects.serviceBorder,
      'dock' => objects.dockBorder,
      'slipway' => objects.slipwayBorder,
      'hazard' => objects.hazardBorder,
      'platform' => objects.platformBorder,
      'navLight' => objects.navLightBorder,
      _ => _objectFieldColor(objects, field),
    };
  }

  static Future<void> _addBoatPlaces(
    MapLibreMapController controller,
    MarinePalette palette,
    List<dynamic> layers,
    bool Function() isCurrent,
  ) async {
    if (layers.contains('boat-port')) return;
    for (final old in ['boat-marinas', 'boat-fuel']) {
      if (layers.contains(old)) {
        await controller.setLayerVisibility(old, false);
      }
    }
    if (!isCurrent()) return;
    // Fallback PNGs for kinds that still use the old sprite names.
    const icons = {
      'boat-fuel': 'assets/icons/boat_fuel.png',
      'boat-anchor': 'assets/icons/boat_anchor.png',
      'boat-customs': 'assets/icons/boat_customs.png',
      'boat-port': 'assets/icons/boat_port.png',
      'boat-service': 'assets/icons/boat_service.png',
      'boat-slipway': 'assets/icons/boat_slipway.png',
    };
    for (final entry in icons.entries) {
      final bytes = await rootBundle.load(entry.value);
      await controller.addImage(
        entry.key,
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (!isCurrent()) return;
    }
    final objects = palette.objects;
    final settings = MapChartSettings.instance;
    for (final field in mapObjectIconFields) {
      final bytes = await MapObjectIcons.render(
        settings.objectIcon(field),
        _objectFieldColor(objects, field),
        _objectBorderColor(objects, field),
      );
      await controller.addImage(mapObjectImageId(field), bytes);
      if (!isCurrent()) return;
    }
    final textColor = palette.chart.labelStrong.hex;
    final halo = palette.chart.labelHalo.hex;
    final below = layers.contains('places_country') ? 'places_country' : null;
    // Each harbour kind carries its own colour so the name alone identifies
    // the place at a glance: teal marinas, green anchorages, amber fuel.
    final placeTextColor = [
      'match',
      ['get', 'kind'],
      'marina',
      objects.marina.hex,
      'anchorage',
      objects.anchorage.hex,
      'fuel',
      objects.fuel.hex,
      'customs',
      objects.customs.hex,
      'harbourmaster',
      objects.port.hex,
      'naval_base',
      objects.port.hex,
      'ferry_terminal',
      objects.ferry.hex,
      'cruise_terminal',
      objects.ferry.hex,
      'slipway',
      objects.slipway.hex,
      'dock',
      objects.dock.hex,
      'lighthouse',
      objects.navLight.hex,
      'beacon',
      objects.navLight.hex,
      textColor,
    ];
    final placeIcon = [
      'match',
      ['get', 'kind'],
      'marina',
      mapObjectImageId('marina'),
      'fuel',
      mapObjectImageId('fuel'),
      'ferry_terminal',
      'ferry_terminal',
      'cruise_terminal',
      'ferry_terminal',
      'customs',
      mapObjectImageId('customs'),
      'harbourmaster',
      mapObjectImageId('port'),
      'naval_base',
      mapObjectImageId('port'),
      'ship_chandler',
      mapObjectImageId('service'),
      'boat',
      mapObjectImageId('service'),
      'boat_rental',
      mapObjectImageId('service'),
      'boat_repair',
      mapObjectImageId('service'),
      'boat_storage',
      mapObjectImageId('service'),
      'slipway',
      'boat-slipway',
      'dock',
      mapObjectImageId('dock'),
      'anchorage',
      mapObjectImageId('anchorage'),
      'lighthouse',
      mapObjectImageId('navLight'),
      'beacon',
      mapObjectImageId('navLight'),
      mapObjectImageId('marina'),
    ];
    const placeIconSize = [
      'match',
      ['get', 'kind'],
      'marina',
      1.15,
      'ferry_terminal',
      1.1,
      'cruise_terminal',
      1.1,
      0.9,
    ];
    // Marina and anchorage each have their own 3-point zoom.
    await controller.addSymbolLayer(
      'protomaps',
      'boat-marinas',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'marinaIcon',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'marinaIcon',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        iconImage: placeIcon,
        iconSize: _objectIconSize(placeIconSize, 'marinaIcon'),
        iconAllowOverlap: false,
        iconPadding: 2,
        iconOptional: false,
        textField: _objectLabel(
          fromZoom: MapChartSettings.instance.zoom('marinaName'),
        ),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        textOffset: const [
          _placeLabelOffset + _objectLabelRightShiftEm,
          0,
        ],
        textOptional: true,
        textMaxWidth: 20,
        textColor: placeTextColor,
        textHaloColor: halo,
        textHaloWidth: 1.4,
        textPadding: 2,
      ),
      sourceLayer: 'pois',
      belowLayerId: below,
      filter: const [
        '==',
        ['get', 'kind'],
        'marina',
      ],
      minzoom: MapChartSettings.instance.zoom('marinaIcon'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'protomaps',
      'boat-anchorages',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'anchorageIcon',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'anchorageIcon',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        iconImage: placeIcon,
        iconSize: _objectIconSize(placeIconSize, 'anchorageIcon'),
        iconAllowOverlap: false,
        iconPadding: 2,
        iconOptional: false,
        textField: _objectLabel(
          fromZoom: MapChartSettings.instance.zoom('anchorageName'),
        ),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        textOffset: const [
          _placeLabelOffset + _objectLabelRightShiftEm,
          0,
        ],
        textOptional: true,
        textMaxWidth: 20,
        textColor: placeTextColor,
        textHaloColor: halo,
        textHaloWidth: 1.4,
        textPadding: 2,
      ),
      sourceLayer: 'pois',
      belowLayerId: below,
      filter: const [
        '==',
        ['get', 'kind'],
        'anchorage',
      ],
      minzoom: MapChartSettings.instance.zoom('anchorageIcon'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    Future<void> addKindLayer({
      required String layerId,
      required String zoomId,
      required List<String> kinds,
      bool respectMinZoom = false,
    }) async {
      final stops = MapChartSettings.instance.objectZoomStops(zoomId);
      await controller.addSymbolLayer(
        'protomaps',
        layerId,
        SymbolLayerProperties(
          textOpacity: MapChartSettings.instance.objectZoomExpression(
            zoomId,
            fromFull: true,
            on: 1,
            off: 0,
          ),
          iconOpacity: MapChartSettings.instance.objectZoomExpression(
            zoomId,
            fromFull: false,
            on: 1,
            off: 0,
          ),
          iconImage: placeIcon,
          iconSize: _objectIconSize(placeIconSize, zoomId),
          iconAllowOverlap: false,
          iconPadding: 2,
          iconOptional: false,
          textField: _objectLabel(fromZoom: stops.full.toDouble()),
          textFont: const ['Noto Sans Regular'],
          textSize: _objectLabelTextSize,
          textAnchor: 'left',
          textJustify: 'left',
          textOffset: const [
            _placeLabelOffset + _objectLabelRightShiftEm,
            0,
          ],
          textOptional: true,
          textMaxWidth: 20,
          textColor: placeTextColor,
          textHaloColor: halo,
          textHaloWidth: 1.4,
          textPadding: 2,
        ),
        sourceLayer: 'pois',
        belowLayerId: below,
        filter: respectMinZoom
            ? [
                'all',
                [
                  'in',
                  ['get', 'kind'],
                  ['literal', kinds],
                ],
                [
                  '>=',
                  ['zoom'],
                  [
                    'coalesce',
                    [
                      'to-number',
                      ['get', 'min_zoom'],
                      MapChartSettings.instance.zoom(zoomId),
                    ],
                    MapChartSettings.instance.zoom(zoomId),
                  ],
                ],
              ]
            : kinds.length == 1
            ? [
                '==',
                ['get', 'kind'],
                kinds.first,
              ]
            : [
                'in',
                ['get', 'kind'],
                ['literal', kinds],
              ],
        minzoom: MapChartSettings.instance.zoom(zoomId),
        enableInteraction: true,
      );
    }

    for (final entry in _boatKindGroups.entries) {
      await addKindLayer(
        layerId: 'boat-${entry.key}',
        zoomId: _boatKindZoomIds[entry.key]!,
        kinds: entry.value,
        respectMinZoom: true,
      );
      if (!isCurrent()) return;
    }
    final leftoverKinds = [
      // Beacon, mooring, lock, life ring, ferry/cruise terminal, and any
      // other harbour kind without its own Settings row. They follow the
      // Harbour places (Places) switch only.
      for (final kind in _boatKinds)
        if (!_boatOwnLayerKinds.contains(kind)) kind,
    ];
    if (leftoverKinds.isNotEmpty) {
      await addKindLayer(
        layerId: 'boat-places',
        zoomId: 'places',
        kinds: leftoverKinds,
        respectMinZoom: true,
      );
      if (!isCurrent()) return;
    }
    // Chart tiles omit slipways until zoom 16. Icons and names use the
    // Marine objects 3-point zoom, loaded from OpenStreetMap for the view.
    _slipwayCoverage.remove(controller);
    final emptySlipways = kIsWeb
        ? web_setup.mapGeoJsonUrl('{"type":"FeatureCollection","features":[]}')
        : {'type': 'FeatureCollection', 'features': <Map<String, dynamic>>[]};
    await controller.addSource(
      'slipways',
      GeojsonSourceProperties(data: emptySlipways),
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'slipways',
      'slipways',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'slipwayIcon',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'slipwayIcon',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        iconImage: mapObjectImageId('slipway'),
        iconSize: _objectIconSize(1.15, 'slipwayIcon'),
        iconAllowOverlap: false,
        iconPadding: 2,
        iconOptional: false,
        textField: _objectLabel(
          fromZoom: MapChartSettings.instance.zoom('slipway'),
        ),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        textOffset: const [
          _placeLabelOffset + _objectLabelRightShiftEm,
          0,
        ],
        textOptional: true,
        textMaxWidth: 20,
        textColor: objects.slipway.hex,
        textHaloColor: halo,
        textHaloWidth: 1.4,
        textPadding: 2,
      ),
      belowLayerId: below,
      minzoom: MapChartSettings.instance.zoom('slipwayIcon'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    unawaited(syncSlipways(controller));
    await controller.addSymbolLayer(
      'protomaps',
      'boat-bridge-labels',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.zoomExpression('bridges', 1, 0),
        symbolPlacement: 'line',
        textField: const ['get', 'name'],
        textFont: const ['Noto Sans Regular'],
        textSize: 11,
        textColor: objects.bridge.hex,
        textHaloColor: halo,
        textHaloWidth: 1.4,
        textMaxAngle: 35,
        symbolSpacing: 280,
      ),
      sourceLayer: 'roads',
      belowLayerId: below,
      filter: const [
        'all',
        ['has', 'is_bridge'],
        ['has', 'name'],
        [
          '!=',
          ['get', 'kind'],
          'rail',
        ],
      ],
      minzoom: MapChartSettings.instance.zoom('bridges'),
      enableInteraction: false,
    );
  }

  /// Ferry routes, marina basins, docks, and OpenSeaMap seamarks. Fuel type,
  /// breakwaters, and bridge clearance are not in the chart tiles.
  static Future<void> _addChartDetails(
    MapLibreMapController controller,
    MarinePalette palette,
    List<dynamic> layers,
    bool Function() isCurrent,
  ) async {
    if (layers.contains('chart-ferry')) return;
    final belowLabels = layers.contains('places_country')
        ? 'places_country'
        : null;
    final objects = palette.objects;
    final ferryColor = objects.ferryRoute.hex;
    final ferryLabelColor = objects.ferry.hex;
    final dockColor = objects.dock.hex;
    final textHalo = palette.chart.labelHalo.hex;
    await controller.addFillLayer(
      'protomaps',
      'chart-marina-area',
      FillLayerProperties(
        fillColor: objects.marina.hex,
        fillOpacity: 0.4,
        fillOutlineColor: objects.marina.hex,
      ),
      sourceLayer: 'landuse',
      belowLayerId: layers.contains('water_stream') ? 'water_stream' : null,
      filter: const [
        '==',
        ['get', 'kind'],
        'marina',
      ],
      minzoom: 12,
      enableInteraction: false,
    );
    if (!isCurrent()) return;
    await controller.addLineLayer(
      'protomaps',
      'chart-dock',
      LineLayerProperties(
        lineColor: dockColor,
        lineWidth: 1.2,
        lineOpacity: 0.9,
      ),
      sourceLayer: 'water',
      belowLayerId: belowLabels,
      filter: const [
        '==',
        ['get', 'kind_detail'],
        'dock',
      ],
      minzoom: 12,
      enableInteraction: false,
    );
    if (!isCurrent()) return;
    // A canal bank is a coast. The dock colour is a brighter blue, so a
    // canal drawn with it reads lighter than the open-water shoreline.
    await controller.addLineLayer(
      'protomaps',
      'chart-canal',
      LineLayerProperties(
        lineColor: palette.chart.coastline.hex,
        lineWidth: const [
          'interpolate',
          ['linear'],
          ['zoom'],
          2,
          0.5,
          6,
          0.8,
          10,
          1.2,
          14,
          1.7,
        ],
        lineOpacity: 0.95,
        lineJoin: 'round',
      ),
      sourceLayer: 'water',
      belowLayerId: belowLabels,
      filter: const [
        '==',
        ['get', 'kind_detail'],
        'canal',
      ],
      minzoom: 10,
      enableInteraction: false,
    );
    if (!isCurrent()) return;
    await controller.addLineLayer(
      'protomaps',
      'chart-ferry',
      LineLayerProperties(
        lineColor: ferryColor,
        lineWidth: const [
          'interpolate',
          ['linear'],
          ['zoom'],
          6,
          0.8,
          12,
          2.2,
        ],
        lineDasharray: const [1.2, 1.4],
        lineOpacity: MapChartSettings.instance.zoomExpression('ferry', 0.95, 0),
      ),
      sourceLayer: 'roads',
      belowLayerId: belowLabels,
      filter: const [
        '==',
        ['get', 'kind'],
        'ferry',
      ],
      minzoom: MapChartSettings.instance.zoom('ferry'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'protomaps',
      'chart-ferry-labels',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.zoomExpression(
          'ferryNames',
          1,
          0,
        ),
        textField: const ['get', 'name'],
        textFont: const ['Noto Sans Italic'],
        textSize: 11,
        textColor: ferryLabelColor,
        textHaloColor: textHalo,
        textHaloWidth: 1.2,
        symbolPlacement: 'line',
        textMaxAngle: 40,
        symbolSpacing: 350,
      ),
      sourceLayer: 'roads',
      belowLayerId: belowLabels,
      filter: const [
        'all',
        [
          '==',
          ['get', 'kind'],
          'ferry',
        ],
        ['has', 'name'],
      ],
      minzoom: MapChartSettings.instance.zoom('ferryNames'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'protomaps',
      'chart-water-names',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.zoomExpression(
          'waterNames',
          1,
          0,
        ),
        textField: const ['get', 'name'],
        textFont: const ['Noto Sans Italic'],
        textSize: 12,
        textColor: palette.chart.labelSoft.hex,
        textHaloColor: textHalo,
        textHaloWidth: 1.2,
        textMaxWidth: 8,
      ),
      sourceLayer: 'water',
      belowLayerId: belowLabels,
      filter: const [
        'all',
        ['has', 'name'],
        [
          'in',
          ['get', 'kind_detail'],
          [
            'literal',
            ['dock', 'canal', 'basin'],
          ],
        ],
      ],
      minzoom: MapChartSettings.instance.zoom('waterNames'),
      enableInteraction: false,
    );
    if (!isCurrent()) return;
    // OpenSeaMap seamark pictures are off for now (buoys, lights, wrecks,
    // and the harbour sailboat). Ferry routes, docks, and marina names stay.
    // The seamark tiles are pictures of the icons, so the names are a
    // separate layer filled from OpenStreetMap for the current view.
    _seamarkCoverage.remove(controller);
    final emptyNames = kIsWeb
        ? web_setup.mapGeoJsonUrl('{"type":"FeatureCollection","features":[]}')
        : {'type': 'FeatureCollection', 'features': <Map<String, dynamic>>[]};
    await controller.addSource(
      'seamark-names',
      GeojsonSourceProperties(data: emptyNames),
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'seamark-names',
      'seamark-marinas',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'seamarks',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'seamarks',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        // A seamark harbour is a marina. Use the marina icon and colour,
        // not the hazard mark.
        iconImage: mapObjectImageId('marina'),
        iconSize: _objectIconSize(1.15, 'seamarks'),
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: _objectLabel(
          fromZoom: MapChartSettings.instance
              .objectZoomStops('seamarks')
              .full
              .toDouble(),
        ),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        textOffset: const [
          _placeLabelOffset + _objectLabelRightShiftEm,
          0,
        ],
        textMaxWidth: 20,
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textColor: objects.marina.hex,
        textHaloColor: textHalo,
        textHaloWidth: 1.4,
      ),
      belowLayerId: belowLabels,
      filter: const [
        '==',
        ['get', 'kind'],
        'harbour',
      ],
      minzoom: MapChartSettings.instance.zoom('seamarks'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'seamark-names',
      'seamark-names',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'seamarks',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'seamarks',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        textField: _objectLabel(
          fromZoom: MapChartSettings.instance
              .objectZoomStops('seamarks')
              .full
              .toDouble(),
        ),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        textOffset: const [
          _seamarkLabelOffset + _objectLabelRightShiftEm,
          0,
        ],
        textMaxWidth: 20,
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textColor: palette.chart.labelStrong.hex,
        textHaloColor: textHalo,
        textHaloWidth: 1.2,
      ),
      belowLayerId: belowLabels,
      filter: const [
        '!=',
        ['get', 'kind'],
        'harbour',
      ],
      minzoom: MapChartSettings.instance.zoom('seamarks'),
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    // Platform image is registered with the other Marine objects icons.
    if (!isCurrent()) return;
    // OpenStreetMap platforms are not in the chart tiles. The icon is on
    // past zoom 6 and the name from zoom 12, for the view on screen.
    _oilPlatformCoverage.remove(controller);
    await controller.addSource(
      'oil-platforms',
      GeojsonSourceProperties(data: emptyNames),
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'oil-platforms',
      'oil-platforms',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'platformIcon',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'platformIcon',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        iconImage: mapObjectImageId('platform'),
        iconSize: _objectIconSize(0.9, 'platformIcon'),
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: _objectLabel(
          fromZoom: MapChartSettings.instance.zoom('platformName'),
        ),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        // Prior 5 px gap at 11 px text, plus another 5 px to the right.
        textOffset: const [
          _placeLabelOffset + 5 / 11 + _objectLabelRightShiftEm,
          0,
        ],
        textOptional: true,
        textMaxWidth: 20,
        textColor: objects.fuel.hex,
        textHaloColor: textHalo,
        textHaloWidth: 1.4,
      ),
      belowLayerId: belowLabels,
      minzoom: MapChartSettings.instance.zoom('platformIcon') + 0.001,
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    await controller.addCircleLayer(
      'oil-platforms',
      'oil-platform-zone',
      CircleLayerProperties(
        circleRadius: _oilPlatformZoneRadius,
        circleColor: objects.platform.hex,
        // Protection circle shares the platform full-icon zoom (hardcoded).
        circleOpacity: [
          'step',
          ['zoom'],
          0,
          _oilPlatformZoneZoom,
          0.18,
        ],
        circleStrokeColor: objects.platform.hex,
        circleStrokeWidth: 1.4,
        circleStrokeOpacity: [
          'step',
          ['zoom'],
          0,
          _oilPlatformZoneZoom,
          0.95,
        ],
      ),
      belowLayerId: 'oil-platforms',
      minzoom: _oilPlatformZoneZoom,
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    // Lighthouse image is registered with the other Marine objects icons.
    if (!isCurrent()) return;
    // Chart tiles omit most of the light description, and the icon only
    // appears at close range. The icon is on past zoom 6. The name and the
    // light description are on from zoom 12.
    _lighthouseCoverage.remove(controller);
    await controller.addSource(
      'lighthouses',
      GeojsonSourceProperties(data: emptyNames),
    );
    if (!isCurrent()) return;
    await controller.addSymbolLayer(
      'lighthouses',
      'lighthouses',
      SymbolLayerProperties(
        textOpacity: MapChartSettings.instance.objectZoomExpression(
          'lighthouseIcon',
          fromFull: true,
          on: 1,
          off: 0,
        ),
        iconOpacity: MapChartSettings.instance.objectZoomExpression(
          'lighthouseIcon',
          fromFull: false,
          on: 1,
          off: 0,
        ),
        iconImage: mapObjectImageId('navLight'),
        iconSize: _objectIconSize(0.9, 'lighthouseIcon'),
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: _lighthouseLabel(),
        textFont: const ['Noto Sans Regular'],
        textSize: _objectLabelTextSize,
        textAnchor: 'left',
        textJustify: 'left',
        // Prior 5 px gap at 11 px text, plus another 5 px to the right.
        textOffset: const [
          _placeLabelOffset + 5 / 11 + _objectLabelRightShiftEm,
          0,
        ],
        textOptional: true,
        textMaxWidth: 28,
        textColor: objects.navLight.hex,
        textHaloColor: textHalo,
        textHaloWidth: 1.4,
      ),
      belowLayerId: belowLabels,
      minzoom: MapChartSettings.instance.zoom('lighthouseIcon') + 0.001,
      enableInteraction: true,
    );
    if (!isCurrent()) return;
    unawaited(syncSeamarkNames(controller));
    unawaited(syncOilPlatforms(controller));
    unawaited(syncLighthouses(controller));
  }

  /// Harbour (sailboat) and small-craft icons, including water fuel, are
  /// drawn by the seamark tiles. Their names are not in those pictures, so
  /// each view loads the matching OpenStreetMap names. A place with no name
  /// still gets a short label, such as Fuel.
  static double get _seamarkNameZoom =>
      MapChartSettings.instance.zoom('seamarks');
  static final _seamarkCoverage = <MapLibreMapController, List<double>>{};
  static final _seamarkRequest = <MapLibreMapController, int>{};

  static Future<void> syncSeamarkNames(MapLibreMapController controller) async {
    if (!MapChartSettings.instance.layerOn('seamarks')) return;
    final zoom = controller.cameraPosition?.zoom ?? 0;
    if (zoom < _seamarkNameZoom) return;
    late LatLngBounds bounds;
    try {
      bounds = await controller.getVisibleRegion();
    } catch (_) {
      return;
    }
    final south = bounds.southwest.latitude;
    final west = bounds.southwest.longitude;
    final north = bounds.northeast.latitude;
    final east = bounds.northeast.longitude;
    if (south > north || west > east) return;
    final height = north - south;
    final width = east - west;
    if (height <= 0 || width <= 0 || height > 4 || width > 4) return;
    final box = [
      south - height * 0.35,
      west - width * 0.35,
      north + height * 0.35,
      east + width * 0.35,
    ];
    final covered = _seamarkCoverage[controller];
    if (covered != null &&
        box[0] >= covered[0] &&
        box[1] >= covered[1] &&
        box[2] <= covered[2] &&
        box[3] <= covered[3]) {
      return;
    }
    final request = (_seamarkRequest[controller] ?? 0) + 1;
    _seamarkRequest[controller] = request;
    try {
      final body = await _postSeamarkQuery(_seamarkQuery(box));
      if (_seamarkRequest[controller] != request || body == null) return;
      await controller.setGeoJsonSource(
        'seamark-names',
        _seamarkCollection(body),
      );
      if (_seamarkRequest[controller] == request) {
        _seamarkCoverage[controller] = box;
      }
    } catch (error) {
      if (_seamarkRequest[controller] == request) {
        debugPrint('Unable to load seamark names: $error');
      }
    }
  }

  /// The browser fetch client refuses a manual content-length header, so the
  /// web request is a plain form post. Other platforms use the http package.
  static Future<String?> _postSeamarkQuery(String query) async {
    const url = 'https://overpass.openstreetmap.fr/api/interpreter';
    if (kIsWeb) {
      final xhr = await html.HttpRequest.request(
        url,
        method: 'POST',
        sendData: 'data=${Uri.encodeQueryComponent(query)}',
        requestHeaders: const {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
      );
      if (xhr.status != 200) return null;
      return xhr.responseText;
    }
    final response = await http.post(
      Uri.parse(url),
      headers: const {
        'User-Agent': 'FreeOpenOcean/0.1 (ocean charts)',
        'Accept': 'application/json',
      },
      body: {'data': query},
    );
    if (response.statusCode != 200) return null;
    return response.body;
  }

  static String _seamarkQuery(List<double> box) {
    final bbox = box.map((value) => value.toStringAsFixed(5)).join(',');
    return '[out:json][timeout:20];('
        'node["seamark:type"="harbour"]($bbox);'
        'node["seamark:type"="small_craft_facility"]($bbox);'
        'way["seamark:type"="harbour"]($bbox);'
        'way["seamark:type"="small_craft_facility"]($bbox);'
        ');out geom;';
  }

  static Map<String, dynamic> _seamarkCollection(String body) {
    final decoded = jsonDecode(body);
    final elements = decoded is Map ? decoded['elements'] : null;
    final features = <Map<String, dynamic>>[];
    final seen = <String>{};
    if (elements is List) {
      for (final raw in elements) {
        if (raw is! Map) continue;
        final tags = raw['tags'];
        if (tags is! Map) continue;
        final label = _seamarkLabel(tags);
        if (label == null) continue;
        final point = _seamarkPoint(raw);
        if (point == null) continue;
        final key =
            '$label@${point[1].toStringAsFixed(3)},${point[0].toStringAsFixed(3)}';
        if (!seen.add(key)) continue;
        features.add({
          'type': 'Feature',
          'id': _osmFeatureId(raw),
          'geometry': {'type': 'Point', 'coordinates': point},
          'properties': _osmFeatureProperties(
            raw,
            tags,
            name: label,
            kind: '${tags['seamark:type']}',
          ),
        });
      }
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// GeoJSON id the chart reports on tap: `node/12345`.
  static String _osmFeatureId(Map raw) {
    final type = raw['type'];
    final id = raw['id'];
    if (type is String && type.isNotEmpty && id != null && '$id'.isNotEmpty) {
      return '$type/$id';
    }
    if (id != null && '$id'.isNotEmpty) return '$id';
    return '';
  }

  /// Shared OSM fields for Overpass-backed marine objects (source, id, contact).
  static Map<String, dynamic> _osmFeatureProperties(
    Map raw,
    Map tags, {
    required String name,
    required String kind,
    String? detail,
    double? lat,
  }) {
    final props = <String, dynamic>{
      'name': name,
      'kind': kind,
      'source': 'OpenStreetMap',
      'osm_type': '${raw['type'] ?? ''}',
      'osm_id': '${raw['id'] ?? ''}',
    };
    if (detail != null && detail.isNotEmpty) props['detail'] = detail;
    if (lat != null) props['lat'] = lat;
    for (final entry in {
      'operator': tags['operator'],
      'website': tags['website'] ?? tags['contact:website'],
      'phone': tags['phone'] ?? tags['contact:phone'],
      'ref': tags['ref'],
      'category': tags['seamark:small_craft_facility:category'],
    }.entries) {
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        props[entry.key] = value.trim();
      }
    }
    return props;
  }

  /// Nodes use their own position. Harbour areas use the polygon center so
  /// the marina icon sits on the seamark symbol.
  static List<double>? _seamarkPoint(Map raw) {
    final lat = raw['lat'];
    final lon = raw['lon'];
    if (lat is num && lon is num) {
      return [lon.toDouble(), lat.toDouble()];
    }
    final geometry = raw['geometry'];
    if (geometry is! List || geometry.isEmpty) return null;
    final ring = <List<double>>[];
    for (final point in geometry) {
      if (point is! Map) continue;
      final pointLat = point['lat'];
      final pointLon = point['lon'];
      if (pointLat is num && pointLon is num) {
        ring.add([pointLon.toDouble(), pointLat.toDouble()]);
      }
    }
    if (ring.isEmpty) return null;
    if (ring.length > 1 &&
        ring.first[0] == ring.last[0] &&
        ring.first[1] == ring.last[1]) {
      ring.removeLast();
    }
    if (ring.length < 3) {
      var sumLon = 0.0;
      var sumLat = 0.0;
      for (final point in ring) {
        sumLon += point[0];
        sumLat += point[1];
      }
      return [sumLon / ring.length, sumLat / ring.length];
    }
    var area = 0.0;
    var centerLon = 0.0;
    var centerLat = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final next = ring[(i + 1) % ring.length];
      final cross = ring[i][0] * next[1] - next[0] * ring[i][1];
      area += cross;
      centerLon += (ring[i][0] + next[0]) * cross;
      centerLat += (ring[i][1] + next[1]) * cross;
    }
    area *= 0.5;
    if (area.abs() < 1e-12) {
      var sumLon = 0.0;
      var sumLat = 0.0;
      for (final point in ring) {
        sumLon += point[0];
        sumLat += point[1];
      }
      return [sumLon / ring.length, sumLat / ring.length];
    }
    return [centerLon / (6 * area), centerLat / (6 * area)];
  }

  static String? _seamarkLabel(Map tags) {
    for (final key in ['name', 'seamark:name']) {
      final value = tags[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    final type = tags['seamark:type'];
    if (type == 'small_craft_facility') {
      final category = tags['seamark:small_craft_facility:category'];
      if (category is String && category.isNotEmpty) {
        return _seamarkCategory(category);
      }
    }
    if (type == 'harbour') return 'Marina';
    return null;
  }

  static String _seamarkCategory(String category) {
    const names = {
      'fuel_station': 'Fuel',
      'boat_hoist': 'Boat hoist',
      'water_tap': 'Water',
      'pump-out': 'Pump-out',
      'pump_out': 'Pump-out',
      'slipway': 'Slipway',
      'electricity': 'Electricity',
      'chandler': 'Chandler',
      'boatyard': 'Boatyard',
      'boat_yard': 'Boatyard',
      'toilets': 'Toilets',
      'showers': 'Showers',
      'visitor_berth': 'Visitor berth',
      'nautical_club': 'Club',
      'sailmaker': 'Sailmaker',
    };
    return names[category] ??
        category.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  /// Slipways from OpenStreetMap. Chart tiles leave them out until zoom 16.
  /// Icons follow the Marine objects 3-point zoom (defaults 14 / 15 / 22).
  static double get _slipwayZoom =>
      MapChartSettings.instance.zoom('slipwayIcon');
  static final _slipwayCoverage = <MapLibreMapController, List<double>>{};
  static final _slipwayRequest = <MapLibreMapController, int>{};

  static Future<void> syncSlipways(MapLibreMapController controller) async {
    if (!MapChartSettings.instance.layerOn('slipways')) return;
    final zoom = controller.cameraPosition?.zoom ?? 0;
    if (zoom <= _slipwayZoom) return;
    late LatLngBounds bounds;
    try {
      bounds = await controller.getVisibleRegion();
    } catch (_) {
      return;
    }
    final south = bounds.southwest.latitude;
    final west = bounds.southwest.longitude;
    final north = bounds.northeast.latitude;
    final east = bounds.northeast.longitude;
    if (south > north || west > east) return;
    final height = north - south;
    final width = east - west;
    if (height <= 0 || width <= 0 || height > 8 || width > 8) return;
    final box = [
      south - height * 0.35,
      west - width * 0.35,
      north + height * 0.35,
      east + width * 0.35,
    ];
    final covered = _slipwayCoverage[controller];
    if (covered != null &&
        box[0] >= covered[0] &&
        box[1] >= covered[1] &&
        box[2] <= covered[2] &&
        box[3] <= covered[3]) {
      return;
    }
    final request = (_slipwayRequest[controller] ?? 0) + 1;
    _slipwayRequest[controller] = request;
    try {
      final body = await _postSeamarkQuery(_slipwayQuery(box));
      if (_slipwayRequest[controller] != request || body == null) return;
      await controller.setGeoJsonSource('slipways', _slipwayCollection(body));
      if (_slipwayRequest[controller] == request) {
        _slipwayCoverage[controller] = box;
      }
    } catch (error) {
      if (_slipwayRequest[controller] == request) {
        debugPrint('Unable to load slipways: $error');
      }
    }
  }

  static String _slipwayQuery(List<double> box) {
    final bbox = box.map((value) => value.toStringAsFixed(5)).join(',');
    return '[out:json][timeout:25];('
        'node["leisure"="slipway"]($bbox);'
        'way["leisure"="slipway"]($bbox);'
        'node["man_made"="slipway"]($bbox);'
        'way["man_made"="slipway"]($bbox);'
        ');out geom;';
  }

  static Map<String, dynamic> _slipwayCollection(String body) {
    final decoded = jsonDecode(body);
    final elements = decoded is Map ? decoded['elements'] : null;
    final features = <Map<String, dynamic>>[];
    final indexByKey = <String, int>{};
    if (elements is List) {
      for (final raw in elements) {
        if (raw is! Map) continue;
        final tags = raw['tags'];
        if (tags is! Map) continue;
        final point = _seamarkPoint(raw);
        if (point == null) continue;
        final key =
            '${point[1].toStringAsFixed(3)},${point[0].toStringAsFixed(3)}';
        final name = _oilPlatformName(tags);
        final existing = indexByKey[key];
        if (existing != null) {
          final previous = features[existing]['properties'];
          if (previous is Map &&
              (previous['name'] as String).isEmpty &&
              name.isNotEmpty) {
            previous['name'] = name;
          }
          continue;
        }
        indexByKey[key] = features.length;
        features.add({
          'type': 'Feature',
          'id': _osmFeatureId(raw),
          'geometry': {'type': 'Point', 'coordinates': point},
          'properties': _osmFeatureProperties(
            raw,
            tags,
            name: name,
            kind: 'slipway',
          ),
        });
      }
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// Offshore oil and gas platforms from OpenStreetMap. The icon is drawn
  /// once the zoom is past 6. The name waits until the zoom is past 12.
  /// A 500 m protection zone, in the same dark orange as the icon, is drawn
  /// once the zoom is past 12.
  static double get _oilPlatformZoom =>
      MapChartSettings.instance.zoom('platformIcon');

  /// Protection circle start zoom. Not a settings control; stays with the
  /// platform full-icon default.
  static const _oilPlatformZoneZoom = 12.0;

  /// Screen radius of a 500 m circle. Web Mercator metres per pixel are
  /// 156543.03392 * cos(latitude) / 2^zoom, so the radius doubles each zoom.
  static final List<Object> _oilPlatformZoneRadius = () {
    const metersPerPixel = 156543.03392;
    const degToRad = 0.017453292519943295;
    final radius = <Object>[
      'interpolate',
      ['exponential', 2],
      ['zoom'],
    ];
    for (var zoom = 6; zoom <= 18; zoom++) {
      radius
        ..add(zoom)
        ..add([
          '/',
          500 * (1 << zoom),
          [
            '*',
            metersPerPixel,
            [
              'cos',
              [
                '*',
                ['get', 'lat'],
                degToRad,
              ],
            ],
          ],
        ]);
    }
    return radius;
  }();
  static final _oilPlatformCoverage = <MapLibreMapController, List<double>>{};
  static final _oilPlatformRequest = <MapLibreMapController, int>{};

  static Future<void> syncOilPlatforms(MapLibreMapController controller) async {
    final chart = MapChartSettings.instance;
    if (!chart.layerOn('platforms')) return;
    final zoom = controller.cameraPosition?.zoom ?? 0;
    if (zoom <= _oilPlatformZoom) return;
    late LatLngBounds bounds;
    try {
      bounds = await controller.getVisibleRegion();
    } catch (_) {
      return;
    }
    final south = bounds.southwest.latitude;
    final west = bounds.southwest.longitude;
    final north = bounds.northeast.latitude;
    final east = bounds.northeast.longitude;
    if (south > north || west > east) return;
    final height = north - south;
    final width = east - west;
    // A zoom-6 screen is tens of degrees across. Wider than that is still
    // zoomed out past the icon, so the query stays inside one view.
    if (height <= 0 || width <= 0 || height > 40 || width > 40) return;
    final box = [
      south - height * 0.35,
      west - width * 0.35,
      north + height * 0.35,
      east + width * 0.35,
    ];
    final covered = _oilPlatformCoverage[controller];
    if (covered != null &&
        box[0] >= covered[0] &&
        box[1] >= covered[1] &&
        box[2] <= covered[2] &&
        box[3] <= covered[3]) {
      return;
    }
    final request = (_oilPlatformRequest[controller] ?? 0) + 1;
    _oilPlatformRequest[controller] = request;
    try {
      final body = await _postSeamarkQuery(_oilPlatformQuery(box));
      if (_oilPlatformRequest[controller] != request || body == null) return;
      await controller.setGeoJsonSource(
        'oil-platforms',
        _oilPlatformCollection(body),
      );
      if (_oilPlatformRequest[controller] == request) {
        _oilPlatformCoverage[controller] = box;
      }
    } catch (error) {
      if (_oilPlatformRequest[controller] == request) {
        debugPrint('Unable to load oil platforms: $error');
      }
    }
  }

  static String _oilPlatformQuery(List<double> box) {
    final bbox = box.map((value) => value.toStringAsFixed(5)).join(',');
    return '[out:json][timeout:25];('
        'node["man_made"="offshore_platform"]($bbox);'
        'way["man_made"="offshore_platform"]($bbox);'
        'node["seamark:type"="platform"]($bbox);'
        'way["seamark:type"="platform"]($bbox);'
        ');out geom;';
  }

  static Map<String, dynamic> _oilPlatformCollection(String body) {
    final decoded = jsonDecode(body);
    final elements = decoded is Map ? decoded['elements'] : null;
    final features = <Map<String, dynamic>>[];
    final indexByKey = <String, int>{};
    if (elements is List) {
      for (final raw in elements) {
        if (raw is! Map) continue;
        final tags = raw['tags'];
        if (tags is! Map) continue;
        final point = _seamarkPoint(raw);
        if (point == null) continue;
        final key =
            '${point[1].toStringAsFixed(3)},${point[0].toStringAsFixed(3)}';
        final name = _oilPlatformName(tags);
        final existing = indexByKey[key];
        if (existing != null) {
          final previous = features[existing]['properties'];
          if (previous is Map &&
              (previous['name'] as String).isEmpty &&
              name.isNotEmpty) {
            previous['name'] = name;
          }
          continue;
        }
        indexByKey[key] = features.length;
        features.add({
          'type': 'Feature',
          'id': _osmFeatureId(raw),
          'geometry': {'type': 'Point', 'coordinates': point},
          'properties': _osmFeatureProperties(
            raw,
            tags,
            name: name,
            kind: 'offshore_platform',
            lat: point[1],
          ),
        });
      }
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  static String _oilPlatformName(Map tags) {
    for (final key in ['name', 'seamark:name', 'ref']) {
      final value = tags[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  /// Lighthouses and major lights from OpenStreetMap. The icon is on past
  /// zoom 6. The name and the light description are on from zoom 12.
  static double get _lighthouseZoom =>
      MapChartSettings.instance.zoom('lighthouseIcon');
  static final _lighthouseCoverage = <MapLibreMapController, List<double>>{};
  static final _lighthouseRequest = <MapLibreMapController, int>{};

  static Future<void> syncLighthouses(MapLibreMapController controller) async {
    if (!MapChartSettings.instance.layerOn('lighthouses')) return;
    final zoom = controller.cameraPosition?.zoom ?? 0;
    if (zoom <= _lighthouseZoom) return;
    late LatLngBounds bounds;
    try {
      bounds = await controller.getVisibleRegion();
    } catch (_) {
      return;
    }
    final south = bounds.southwest.latitude;
    final west = bounds.southwest.longitude;
    final north = bounds.northeast.latitude;
    final east = bounds.northeast.longitude;
    if (south > north || west > east) return;
    final height = north - south;
    final width = east - west;
    if (height <= 0 || width <= 0 || height > 40 || width > 40) return;
    final box = [
      south - height * 0.35,
      west - width * 0.35,
      north + height * 0.35,
      east + width * 0.35,
    ];
    final covered = _lighthouseCoverage[controller];
    if (covered != null &&
        box[0] >= covered[0] &&
        box[1] >= covered[1] &&
        box[2] <= covered[2] &&
        box[3] <= covered[3]) {
      return;
    }
    final request = (_lighthouseRequest[controller] ?? 0) + 1;
    _lighthouseRequest[controller] = request;
    try {
      final body = await _postSeamarkQuery(_lighthouseQuery(box));
      if (_lighthouseRequest[controller] != request || body == null) return;
      await controller.setGeoJsonSource(
        'lighthouses',
        _lighthouseCollection(body),
      );
      if (_lighthouseRequest[controller] == request) {
        _lighthouseCoverage[controller] = box;
      }
    } catch (error) {
      if (_lighthouseRequest[controller] == request) {
        debugPrint('Unable to load lighthouses: $error');
      }
    }
  }

  static String _lighthouseQuery(List<double> box) {
    final bbox = box.map((value) => value.toStringAsFixed(5)).join(',');
    return '[out:json][timeout:25];('
        'node["man_made"="lighthouse"]($bbox);'
        'way["man_made"="lighthouse"]($bbox);'
        'node["seamark:type"="lighthouse"]($bbox);'
        'way["seamark:type"="lighthouse"]($bbox);'
        'node["seamark:type"="light_major"]($bbox);'
        'way["seamark:type"="light_major"]($bbox);'
        ');out geom;';
  }

  static Map<String, dynamic> _lighthouseCollection(String body) {
    final decoded = jsonDecode(body);
    final elements = decoded is Map ? decoded['elements'] : null;
    final features = <Map<String, dynamic>>[];
    final indexByKey = <String, int>{};
    if (elements is List) {
      for (final raw in elements) {
        if (raw is! Map) continue;
        final tags = raw['tags'];
        if (tags is! Map) continue;
        final point = _seamarkPoint(raw);
        if (point == null) continue;
        final key =
            '${point[1].toStringAsFixed(3)},${point[0].toStringAsFixed(3)}';
        final name = _lighthouseName(tags);
        final detail = _lighthouseDetail(tags);
        final kind = _lighthouseKind(tags);
        final existing = indexByKey[key];
        if (existing != null) {
          final previous = features[existing]['properties'];
          if (previous is Map) {
            if ((previous['name'] as String).isEmpty && name.isNotEmpty) {
              previous['name'] = name;
            }
            final previousDetail = previous['detail'];
            if (previousDetail is String &&
                detail.length > previousDetail.length) {
              previous['detail'] = detail;
            }
            if (kind == 'lighthouse') previous['kind'] = kind;
          }
          continue;
        }
        indexByKey[key] = features.length;
        features.add({
          'type': 'Feature',
          'id': _osmFeatureId(raw),
          'geometry': {'type': 'Point', 'coordinates': point},
          'properties': _osmFeatureProperties(
            raw,
            tags,
            name: name,
            kind: kind,
            detail: detail,
          ),
        });
      }
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  static String _lighthouseName(Map tags) {
    for (final key in ['name', 'seamark:name']) {
      final value = tags[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static String _lighthouseKind(Map tags) {
    if (tags['man_made'] == 'lighthouse' ||
        tags['seamark:type'] == 'lighthouse') {
      return 'lighthouse';
    }
    return 'light_major';
  }

  /// Character, colour, period, range, height, and sectors for each light,
  /// then a fog signal when one is tagged.
  static String _lighthouseDetail(Map tags) {
    final indexes = <String>{};
    for (final key in tags.keys) {
      final text = key.toString();
      const prefix = 'seamark:light:';
      if (!text.startsWith(prefix)) continue;
      final rest = text.substring(prefix.length);
      if (rest == 'reference') continue;
      final split = rest.indexOf(':');
      indexes.add(split < 0 ? '' : rest.substring(0, split));
    }
    if (indexes.length > 1) indexes.remove('');
    final ordered = indexes.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    final lines = <String>[];
    for (final index in ordered) {
      final line = _lighthouseLightLine(
        tags,
        index.isEmpty ? 'seamark:light:' : 'seamark:light:$index:',
      );
      if (line.isNotEmpty) lines.add(line);
    }
    if (lines.isEmpty) {
      final height = tags['height'];
      if (height is String && height.trim().isNotEmpty) {
        lines.add('${height.trim()}m');
      }
    }
    final fog = tags['seamark:fog_signal:category'];
    if (fog is String && fog.trim().isNotEmpty) {
      final word = fog.trim().replaceAll('_', ' ');
      lines.add('${word[0].toUpperCase()}${word.substring(1)}');
    }
    final reference = tags['seamark:light:reference'];
    if (reference is String && reference.trim().isNotEmpty) {
      lines.add(reference.trim());
    }
    return lines.join('\n');
  }

  static String _lighthouseLightLine(Map tags, String prefix) {
    String? tag(String key) {
      final value = tags['$prefix$key'];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    final character = tag('character');
    final group = tag('group');
    final colour = tag('colour') ?? tag('color');
    final period = tag('period');
    final range = tag('range');
    final height = tag('height');
    final sectorStart = tag('sector_start');
    final sectorEnd = tag('sector_end');
    if (character == null &&
        colour == null &&
        range == null &&
        height == null) {
      return '';
    }
    final parts = <String>[];
    if (character != null) {
      parts.add(
        group != null && group != '1' ? '$character($group)' : character,
      );
    }
    if (colour != null) {
      parts.add(
        colour
            .split(RegExp(r'[;,]'))
            .map((part) => _lighthouseColour(part.trim()))
            .join(),
      );
    }
    if (period != null) {
      parts.add(period.endsWith('s') ? period : '${period}s');
    }
    if (range != null) {
      parts.add(range.endsWith('M') ? range : '${range}M');
    }
    if (height != null) {
      parts.add(height.endsWith('m') ? height : '${height}m');
    }
    if (sectorStart != null && sectorEnd != null) {
      parts.add('$sectorStart°–$sectorEnd°');
    }
    return parts.join(' ');
  }

  static String _lighthouseColour(String colour) {
    const letters = {
      'white': 'W',
      'red': 'R',
      'green': 'G',
      'yellow': 'Y',
      'blue': 'Bu',
      'orange': 'Or',
      'amber': 'Am',
      'violet': 'Vi',
    };
    return letters[colour.toLowerCase()] ?? colour;
  }

  /// Shade terrain from AWS tiles, and draw contour lines with the elevation
  /// in meters on the major land lines. Over the ocean the shade stops at
  /// zoom 11 so closer charts keep a flat water color. Land contours stay
  /// under the water fill. Depth contours sit on the water from zoom 7.
  static Future<void> _addLandElevation(
    MapLibreMapController controller,
    MarinePalette palette,
    List<dynamic> layers,
    bool Function() isCurrent,
  ) async {
    const landLayerId = 'land-elevation';
    const oceanLayerId = 'ocean-elevation';
    if (layers.contains(landLayerId) || layers.contains(oceanLayerId)) return;
    final chart = palette.chart;
    final shadeOn = MapChartSettings.instance.layerOn('hillshade');
    final shade = HillshadeLayerProperties(
      hillshadeExaggeration: 0.3,
      hillshadeShadowColor: chart.hillshadeShadow.hex,
      hillshadeHighlightColor: chart.hillshadeHighlight.hex,
      hillshadeAccentColor: chart.hillshadeAccent.hex,
    );
    try {
      await controller.addSource(
        'land-elevation-dem',
        const RasterDemSourceProperties(
          tiles: [
            'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png',
          ],
          encoding: 'terrarium',
          tileSize: 256,
          maxzoom: 15,
        ),
      );
      if (!isCurrent()) return;
      if (shadeOn) {
        final shadeZoom = MapChartSettings.instance.zoomRange('hillshade');
        // From the chosen zoom up, only land shows through holes in the ocean polygon.
        await controller.addHillshadeLayer(
          'land-elevation-dem',
          landLayerId,
          shade,
          belowLayerId: layers.contains('water') ? 'water' : 'water_stream',
          minzoom: shadeZoom.$1.toDouble(),
          maxzoom: shadeZoom.$2 >= 22 ? 24.0 : (shadeZoom.$2 + 1).toDouble(),
        );
        if (!isCurrent()) return;
        // Through zoom 11 the same shade sits on the water as well.
        await controller.addHillshadeLayer(
          'land-elevation-dem',
          oceanLayerId,
          shade,
          belowLayerId: 'water_stream',
          maxzoom: 11,
        );
      }
      if (!isCurrent() || !kIsWeb) return;
      await _addLandContours(controller, palette, layers);
    } catch (error) {
      if (isCurrent()) debugPrint('Unable to load land elevation: $error');
    }
  }

  /// Contour vectors are generated in the browser from the terrain tiles.
  /// The protocol is registered in web/index.html.
  static Future<void> _addLandContours(
    MapLibreMapController controller,
    MarinePalette palette,
    List<dynamic> layers,
  ) async {
    const sourceId = 'land-contours';
    if (layers.contains('land-contour-lines') ||
        layers.contains('ocean-contour-lines')) {
      return;
    }
    final chart = palette.chart;
    final depth = palette.depth;
    final settings = MapChartSettings.instance;
    final belowWater = layers.contains('water') ? 'water' : 'water_stream';
    final lineColor = chart.landContour.hex;
    final textColor = chart.landContourLabel.hex;
    final textHalo = chart.labelHalo.hex;
    await controller.addSource(
      sourceId,
      const VectorSourceProperties(
        tiles: [
          'dem-contour://{z}/{x}/{y}?contourLayer=contours&elevationKey=ele&levelKey=level&multiplier=1&overzoom=1&thresholds=0%2A2000%2A4000%7E3%2A1000%2A2000%7E5%2A500%2A1000%7E7%2A200%2A1000%7E9%2A100%2A500%7E11%2A50%2A200%7E13%2A20%2A100',
        ],
        maxzoom: 15,
      ),
    );
    if (settings.layerOn('landContour')) {
      final contourZoom = settings.zoomRange('landContour');
      await controller.addLineLayer(
        sourceId,
        'land-contour-lines',
        LineLayerProperties(
          lineColor: lineColor,
          lineWidth: settings.linePx('landContour'),
          lineCap: settings.lineCap('landContour'),
          lineDasharray: settings.lineDash('landContour'),
          lineOpacity: 0.4,
        ),
        sourceLayer: 'contours',
        belowLayerId: belowWater,
        minzoom: contourZoom.$1.toDouble(),
        maxzoom: contourZoom.$2 >= 22 ? 24.0 : (contourZoom.$2 + 1).toDouble(),
        filter: const [
          '>',
          ['get', 'ele'],
          0,
        ],
        enableInteraction: false,
      );
    }
    if (settings.layerOn('landContourLabel')) {
      final labelZoom = settings.zoomRange('landContourLabel');
      await controller.addSymbolLayer(
        sourceId,
        'land-contour-labels',
        SymbolLayerProperties(
          textField: const [
            'concat',
            [
              'number-format',
              ['get', 'ele'],
              {'max-fraction-digits': 0},
            ],
            ' m',
          ],
          textFont: const ['Noto Sans Regular'],
          textSize: 11,
          textColor: textColor,
          textOpacity: 0.5,
          textHaloColor: textHalo,
          textHaloWidth: 1.2,
          symbolPlacement: 'line',
          textAllowOverlap: false,
          textPadding: 8,
        ),
        sourceLayer: 'contours',
        belowLayerId: belowWater,
        minzoom: labelZoom.$1.toDouble(),
        maxzoom: labelZoom.$2 >= 22 ? 24.0 : (labelZoom.$2 + 1).toDouble(),
        filter: const [
          'all',
          [
            '>',
            ['get', 'level'],
            0,
          ],
          [
            '>',
            ['get', 'ele'],
            0,
          ],
        ],
        enableInteraction: false,
      );
    }
    if (!settings.layerOn('contours')) return;
    // Below-sea-level lines sit above the water fill, banded by sounding so
    // depth is readable without stopping to find a number. Shallow water is
    // warm and heavy; everything with water under the keel stays blue and
    // thin, which also keeps the loud colour off most of the screen at night.
    final aboveWater = layers.contains('water_stream') ? 'water_stream' : null;
    const metresBelowSurface = [
      '-',
      0,
      ['get', 'ele'],
    ];
    String band(String id, Color color) =>
        settings.layerOn(id) ? color.hex : 'rgba(0,0,0,0)';
    final depthBandColor = [
      'step',
      metresBelowSurface,
      depth.danger.hex,
      MarineDepth.cautionFrom,
      band('caution', depth.caution),
      MarineDepth.coastalFrom,
      band('coastal', depth.coastal),
      MarineDepth.shelfFrom,
      band('shelf', depth.shelf),
      MarineDepth.deepFrom,
      band('deep', depth.deep),
    ];
    await controller.addLineLayer(
      sourceId,
      'ocean-contour-lines',
      LineLayerProperties(
        lineColor: depthBandColor,
        lineWidth: const [
          '*',
          // Major contours carry twice the weight of the intermediates.
          [
            'match',
            ['get', 'level'],
            1,
            1.0,
            0.5,
          ],
          [
            'step',
            metresBelowSurface,
            1.9,
            MarineDepth.cautionFrom,
            1.5,
            MarineDepth.coastalFrom,
            1.1,
            MarineDepth.shelfFrom,
            0.9,
            MarineDepth.deepFrom,
            0.75,
          ],
        ],
        lineOpacity: const [
          'step',
          metresBelowSurface,
          1.0,
          MarineDepth.coastalFrom,
          0.85,
          MarineDepth.deepFrom,
          0.7,
        ],
      ),
      sourceLayer: 'contours',
      belowLayerId: aboveWater,
      minzoom: 6,
      filter: const [
        '<',
        ['get', 'ele'],
        0,
      ],
      enableInteraction: false,
    );
    if (!settings.layerOn('label')) return;
    final depthHalo = chart.labelHalo.hex;
    await controller.addSymbolLayer(
      sourceId,
      'ocean-contour-labels',
      SymbolLayerProperties(
        textField: const [
          'concat',
          [
            'number-format',
            [
              'abs',
              ['get', 'ele'],
            ],
            {'max-fraction-digits': 0},
          ],
          ' m',
        ],
        textFont: const ['Noto Sans Regular'],
        textSize: 11,
        // Soundings inside the caution bands are tinted; deeper numbers stay
        // neutral so only the shallow ones draw the eye.
        textColor: [
          'step',
          metresBelowSurface,
          depth.danger.hex,
          MarineDepth.cautionFrom,
          depth.caution.hex,
          MarineDepth.coastalFrom,
          depth.label.hex,
        ],
        textOpacity: 0.9,
        textHaloColor: depthHalo,
        textHaloWidth: 1.4,
        symbolPlacement: 'line',
        textAllowOverlap: false,
        textPadding: 8,
      ),
      sourceLayer: 'contours',
      belowLayerId: aboveWater,
      minzoom: 6,
      filter: const [
        'all',
        [
          '>',
          ['get', 'level'],
          0,
        ],
        [
          '<',
          ['get', 'ele'],
          0,
        ],
      ],
      enableInteraction: false,
    );
  }

  static Future<void> getCurrentLocation(
    MapLibreMapController controller,
  ) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          10.0,
        ),
      );
    } catch (e) {
      // Handle error
      debugPrint('Error getting location: $e');
    }
  }
}
