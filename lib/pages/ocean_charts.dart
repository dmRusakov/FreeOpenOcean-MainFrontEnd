import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';

class OceanCharts extends StatefulWidget {
  final Map<String, String>? params;
  final String apiKey = '42f6ab2492a77fae';

  const OceanCharts({super.key, this.params});

  @override
  State<OceanCharts> createState() => _OceanChartsState();
}

class _OceanChartsState extends State<OceanCharts> {
  late Future<String> _styleFuture;

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadStyle();
  }

  Future<String> _loadStyle() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stylePath = isDark ? 'assets/styles/dark.json' : 'assets/styles/light.json';
    return await rootBundle.loadString(stylePath);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageTemplate(
      fullScreen: true,
      body: FutureBuilder<String>(
        future: _styleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading style: ${snapshot.error}'));
          } else {
            final styleString = snapshot.data!;
            return kIsWeb
                ? MaplibreMap(
                    styleString: styleString,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 2,
                    ),
                    onMapCreated: (MaplibreMapController controller) {
                      _getCurrentLocation(controller);
                    },
                  )
                : MaplibreMap(
                    styleString: styleString,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 2,
                    ),
                    myLocationRenderMode: MyLocationRenderMode.compass,
                    onMapCreated: (MaplibreMapController controller) {
                      // Add any additional setup here if needed
                    },
                  );
          }
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