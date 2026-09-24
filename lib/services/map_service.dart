import 'dart:convert';

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

  static Future<Object> _loadGeoJson(String name) async {
    final asset = 'assets/maps/$name.geojson';
    // Fetch plain JSON on web: the plugin converts inline maps to objects
    // without prototypes, which MapLibre 5's worker serializer rejects.
    if (kIsWeb) return web_setup.mapAssetUrl(asset);
    return jsonDecode(await rootBundle.loadString(asset))
        as Map<String, dynamic>;
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
