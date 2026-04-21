import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:free_open_ocean/config/config.dart';

class MapService {
  static String getStyleUrl(Brightness brightness) {
    final colorSchema = brightness == Brightness.dark ? 'dark' : 'light';
    return 'https://api.protomaps.com/styles/v2/$colorSchema.json?key=${Config.apiKey}';
  }

  static Future<void> getCurrentLocation(MaplibreMapController controller) async {
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
        desiredAccuracy: LocationAccuracy.high,
      );

      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          10.0,
        ),
      );
    } catch (e) {
      // Handle error
      print('Error getting location: $e');
    }
  }
}
