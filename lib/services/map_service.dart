import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:free_open_ocean/config/config.dart';
import '../web_setup_stub.dart'
    if (dart.library.html) '../web_setup.dart'
    as web_setup;

class MapService {
  static final _islandPoints = _loadGeoJson('island_points');
  static final _islandGroups = _loadGeoJson('island_groups');
  static final _maritimeBoundaries = _loadGeoJson('maritime_boundaries');
  static final _islandNames = _loadGeoJson('island_names');
  static final _graticule = _loadGeoJson('graticule');

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
    final n = utc.difference(yearStart).inMicroseconds /
            Duration.microsecondsPerDay +
        1;
    final g = 2 * pi * (n - 1) / days;
    final decl = 0.006918 -
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
    final n = utc.difference(yearStart).inMicroseconds /
            Duration.microsecondsPerDay +
        1;
    final g = 2 * pi * (n - 1) / days;
    final eqtime = 229.18 *
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
          'properties': {
            'kind': 'label',
            'name': _sunLatitudeLabel(latitude),
          },
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

  static String getStyleUrl(Brightness brightness) {
    final colorSchema = brightness == Brightness.dark ? 'dark' : 'light';
    return 'https://api.protomaps.com/styles/v5/$colorSchema/en.json?key=${Config.apiKey}';
  }

  /// Coastline dots for islands under about 600 km², plus hillshade, land
  /// contours, and open-ocean island group names. The dots stay on at every
  /// zoom so Samos and the smaller Fiji islands do not drop out of the chart.
  static Future<void> addIslandOverlay(
    MapLibreMapController controller,
    Brightness brightness,
    bool Function() isCurrent,
  ) async {
    try {
      final points = await _islandPoints;
      final groups = await _islandGroups;
      final maritime = await _maritimeBoundaries;
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
      final dark = brightness == Brightness.dark;
      // Same greens as the Protomaps forest landcover, dark and light.
      final islandColor = dark ? '#1c2925' : '#c4e7d2';
      final islandOutline = dark ? '#121c18' : '#8fbfa4';
      await _addLandElevation(controller, brightness, layers, isCurrent);
      if (!isCurrent()) return;
      await controller.addSource(
        'island-points',
        GeojsonSourceProperties(data: points, cluster: false),
      );
      if (!isCurrent()) return;
      await controller.addCircleLayer(
        'island-points',
        'island-visibility',
        CircleLayerProperties(
          circleColor: islandColor,
          circleRadius: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            0,
            2.3,
            6,
            3,
            8,
            2.5,
            12,
            1,
          ],
          circleOpacity: 1,
          circleStrokeColor: islandOutline,
          circleStrokeWidth: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            8,
            0.8,
            12,
            0,
          ],
        ),
        belowLayerId: 'water_stream',
        minzoom: 8.01,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Open-ocean group names for passagemaking. Coastal archipelagos are
      // omitted. Keep names visible throughout zoom levels 2 through 8.
      final labelColor = brightness == Brightness.dark ? '#8a8a8a' : '#5c564f';
      final labelHalo = brightness == Brightness.dark ? '#141414' : '#f4f1ec';
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
        minzoom: 2,
        // MapLibre's upper bound is exclusive; include the whole zoom-8 band.
        maxzoom: 9,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Latitude and longitude every 10 degrees. The solid line is the
      // latitude where the sun is overhead right now, not latitude 0.
      final gridColor = dark ? '#7d8b9e' : '#8a8a8a';
      final equatorColor = dark ? '#a3a3a3' : '#6a6a6a';
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
          lineWidth: 0.7,
          lineOpacity: 0.85,
          lineDasharray: const [1, 2],
        ),
        belowLayerId: 'water_stream',
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
          lineColor: equatorColor,
          lineWidth: 0.8,
          lineOpacity: 0.95,
        ),
        belowLayerId: 'water_stream',
        filter: const ['==', ['get', 'kind'], 'sun'],
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // The sun's overhead position right now, on the wide chart through zoom 4.
      await controller.addCircleLayer(
        'sun-equator',
        'sun-positions',
        const CircleLayerProperties(
          circleColor: '#f2c14d',
          circleRadius: 7,
          circleOpacity: 0.95,
          circleStrokeColor: '#fff6d0',
          circleStrokeWidth: 1.4,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const ['==', ['get', 'kind'], 'position'],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addSymbolLayer(
        'sun-equator',
        'sun-equator-label',
        SymbolLayerProperties(
          textField: const ['get', 'name'],
          textFont: const ['Noto Sans Italic'],
          textSize: 11,
          textColor: equatorColor,
          textHaloColor: dark ? '#141414' : '#f4f1ec',
          textHaloWidth: 1.2,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const ['==', ['get', 'kind'], 'label'],
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Moon's overhead track for one pass around the Earth, and where it
      // is right now. Both stay on the wide chart, zoom 0 through 4.
      final moonColor = dark ? '#c5ced8' : '#6d7580';
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
        filter: const ['==', ['get', 'kind'], 'orbit'],
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
        const CircleLayerProperties(
          circleColor: '#e7eef6',
          circleRadius: 6,
          circleOpacity: 0.95,
          circleStrokeColor: '#9aa6b5',
          circleStrokeWidth: 1.2,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const ['==', ['get', 'kind'], 'moon'],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addCircleLayer(
        'moon-orbit',
        'moon-hit',
        const CircleLayerProperties(
          circleColor: '#e7eef6',
          circleRadius: 18,
          circleOpacity: 0.01,
        ),
        filter: const ['==', ['get', 'kind'], 'moon'],
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
          textHaloColor: dark ? '#141414' : '#f4f1ec',
          textHaloWidth: 1.2,
          textOffset: const [0, 1.1],
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        belowLayerId: layers.contains('places_country')
            ? 'places_country'
            : null,
        filter: const ['==', ['get', 'kind'], 'moon'],
        minzoom: 0,
        maxzoom: 5,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Country limits that continue offshore: median lines, treaties, and
      // the 200-mile nautical limit. Same dash and color as the land borders.
      final boundaryColor = dark ? '#5b6374' : '#adadad';
      await controller.addSource(
        'maritime-boundaries',
        GeojsonSourceProperties(
          data: maritime,
          attribution:
              '<a href="https://www.naturalearthdata.com/">Natural Earth</a>',
        ),
      );
      if (!isCurrent()) return;
      await controller.addLineLayer(
        'maritime-boundaries',
        'maritime-boundaries',
        LineLayerProperties(
          lineColor: boundaryColor,
          lineWidth: 0.7,
          lineDasharray: const [2, 1],
        ),
        belowLayerId: 'water_stream',
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      // Protomaps adds these island names only at zoom 6 or 7.
      // Draw each name from zoom 4 until that basemap label takes over.
      final islandNameColor = dark ? '#525252' : '#5c564f';
      final islandNameHalo = dark ? '#1f1f1f' : '#f4f1ec';
      await controller.addSource(
        'island-names',
        GeojsonSourceProperties(data: islandNames),
      );
      if (!isCurrent()) return;
      final belowNames = layers.contains('places_country')
          ? 'places_country'
          : null;
      await controller.addSymbolLayer(
        'island-names',
        'island-names',
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
        filter: const ['==', ['get', 'until'], 6],
        minzoom: 4,
        maxzoom: 6,
        enableInteraction: false,
      );
      if (!isCurrent()) return;
      await controller.addSymbolLayer(
        'island-names',
        'island-names-later',
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
        filter: const ['==', ['get', 'until'], 7],
        minzoom: 4,
        maxzoom: 7,
        enableInteraction: false,
      );
    } catch (error) {
      if (isCurrent()) debugPrint('Unable to load island overlay: $error');
    }
  }

  /// Shade terrain from AWS tiles, and draw land contour lines with the
  /// elevation in meters on the major lines. Over the ocean the shade stops
  /// at zoom 11 so closer charts keep a flat water color. Contours are land
  /// only: heights at or below sea level are left off the chart.
  static Future<void> _addLandElevation(
    MapLibreMapController controller,
    Brightness brightness,
    List<dynamic> layers,
    bool Function() isCurrent,
  ) async {
    const landLayerId = 'land-elevation';
    const oceanLayerId = 'ocean-elevation';
    if (layers.contains(landLayerId) || layers.contains(oceanLayerId)) return;
    final dark = brightness == Brightness.dark;
    final shade = HillshadeLayerProperties(
      hillshadeExaggeration: 0.3,
      hillshadeShadowColor: dark ? '#000000' : '#3f3a34',
      hillshadeHighlightColor: dark ? '#5c5c5c' : '#e0dcd6',
      hillshadeAccentColor: dark ? '#101010' : '#c8c2b8',
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
          attribution:
              '<a href="https://registry.opendata.aws/terrain-tiles/">AWS Terrain Tiles</a>',
        ),
      );
      if (!isCurrent()) return;
      // From zoom 11 up, only land shows through holes in the ocean polygon.
      await controller.addHillshadeLayer(
        'land-elevation-dem',
        landLayerId,
        shade,
        belowLayerId: layers.contains('water') ? 'water' : 'water_stream',
        minzoom: 11,
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
      if (!isCurrent() || !kIsWeb) return;
      await _addLandContours(controller, dark, layers);
    } catch (error) {
      if (isCurrent()) debugPrint('Unable to load land elevation: $error');
    }
  }

  /// Contour vectors are generated in the browser from the terrain tiles.
  /// The protocol is registered in web/index.html.
  static Future<void> _addLandContours(
    MapLibreMapController controller,
    bool dark,
    List<dynamic> layers,
  ) async {
    const sourceId = 'land-contours';
    if (layers.contains('land-contour-lines')) return;
    final belowWater = layers.contains('water') ? 'water' : 'water_stream';
    final lineColor = dark ? '#8a8a8a' : '#9a938a';
    final textColor = dark ? '#c4c4c4' : '#4a453f';
    final textHalo = dark ? '#141414' : '#f7f4ef';
    await controller.addSource(
      sourceId,
      const VectorSourceProperties(
        tiles: [
          'dem-contour://{z}/{x}/{y}?contourLayer=contours&elevationKey=ele&levelKey=level&multiplier=1&overzoom=1&thresholds=4%2A500%2A1000%7E7%2A200%2A1000%7E9%2A100%2A500%7E11%2A50%2A200%7E13%2A20%2A100',
        ],
        maxzoom: 15,
        attribution:
            '<a href="https://registry.opendata.aws/terrain-tiles/">AWS Terrain Tiles</a>',
      ),
    );
    await controller.addLineLayer(
      sourceId,
      'land-contour-lines',
      LineLayerProperties(
        lineColor: lineColor,
        lineWidth: const [
          'match',
          ['get', 'level'],
          1,
          1.15,
          0.55,
        ],
        lineOpacity: 0.4,
      ),
      sourceLayer: 'contours',
      belowLayerId: belowWater,
      minzoom: 7,
      filter: const [
        '>',
        ['get', 'ele'],
        0,
      ],
      enableInteraction: false,
    );
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
      minzoom: 7,
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
