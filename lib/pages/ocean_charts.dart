import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:free_open_ocean/services/map_service.dart';

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
    final styleUrl = MapService.getStyleUrl(Theme.of(context).brightness);
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
          MapService.getCurrentLocation(controller);
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
}