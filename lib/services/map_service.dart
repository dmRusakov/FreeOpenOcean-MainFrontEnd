import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:free_open_ocean/config/config.dart';

class MapService {
  static final _islandShapes = _loadGeoJson('island_shapes');
  static final _islandPoints = _loadGeoJson('island_points');

  static Future<Map<String, dynamic>> _loadGeoJson(String name) async =>
      jsonDecode(await rootBundle.loadString('assets/maps/$name.geojson'))
          as Map<String, dynamic>;

  static String getStyleUrl(Brightness brightness) {
    final colorSchema = brightness == Brightness.dark ? 'dark' : 'light';
    return 'https://api.protomaps.com/styles/v5/$colorSchema/en.json?key=${Config.apiKey}';
  }

  /// Supplement generalized low-zoom tiles without drawing overview geometry
  /// over the detailed coastlines supplied by Protomaps at navigation scales.
  static Future<void> addIslandOverlay(
    MapLibreMapController controller,
    Brightness brightness,
    bool Function() isCurrent,
  ) async {
    try {
      final shapes = await _islandShapes;
      final points = await _islandPoints;
      if (!isCurrent()) return;
      final layers = await controller.getLayerIds();
      if (!isCurrent()) return;
      // Above ocean fill, below waterways, roads and labels in the v5 style.
      if (!layers.contains('water_stream')) {
        debugPrint('Island overlay: expected Protomaps water layer missing');
        return;
      }
      // Match the earth fill in the hosted Protomaps v5 themes.
      final landColor = brightness == Brightness.dark ? '#1f1f1f' : '#e2dfda';
      await controller.addSource(
        'island-shapes',
        GeojsonSourceProperties(
          data: shapes,
          tolerance: 0,
          maxzoom: 7,
          attribution:
              '<a href="https://www.naturalearthdata.com/">Natural Earth</a>',
        ),
      );
      if (!isCurrent()) return;
      await controller.addFillLayer(
        'island-shapes',
        'island-overview',
        FillLayerProperties(
          fillColor: landColor,
          fillOpacity: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            6,
            1,
            7,
            0,
          ],
        ),
        belowLayerId: 'water_stream',
        maxzoom: 7,
        enableInteraction: false,
      );
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
          circleColor: landColor,
          circleRadius: 1.5,
          circleOpacity: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            7,
            1,
            8,
            0,
          ],
        ),
        filter: const [
          '<',
          ['zoom'],
          ['get', 'dotUntil'],
        ],
        belowLayerId: 'water_stream',
        maxzoom: 8,
        enableInteraction: false,
      );
    } catch (error) {
      if (isCurrent()) debugPrint('Unable to load island overlay: $error');
    }
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
