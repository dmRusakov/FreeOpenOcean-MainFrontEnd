import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:free_open_ocean/config/config.dart';

class OceanCharts extends StatefulWidget {
  final Map<String, String>? params;

  const OceanCharts({super.key, this.params});

  @override
  State<OceanCharts> createState() => _OceanChartsState();
}

class _OceanChartsState extends State<OceanCharts> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      setTopBar(title: localizations.translate('ocean_charts'), ownerId: 'ocean_charts', submenu: []);
    });
  }

  @override
  void dispose() {
    clearTopBar(ownerId: 'ocean_charts');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleUrl = isDark
        ? 'https://api.protomaps.com/styles/v2/dark.json?key=${Config.apiKey}'
        : 'https://api.protomaps.com/styles/v2/light.json?key=${Config.apiKey}';

    // final styleUrl = 'https://api.protomaps.com/styles/v2/light.json?key=${Config.apiKey}';

    return PageTemplate(
      fullScreen: true,
      body: kIsWeb
          ? MaplibreMap(
        styleString: styleUrl,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        onMapCreated: (MaplibreMapController controller) {
          _getCurrentLocation(controller);
        },
      )
          : MaplibreMap(
        styleString: styleUrl,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        myLocationRenderMode: MyLocationRenderMode.compass,
        onMapCreated: (MaplibreMapController controller) {
          // Add any additional setup here if needed
        },
      ),
    );
  }

  Future<void> _getCurrentLocation(MaplibreMapController controller) async {
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