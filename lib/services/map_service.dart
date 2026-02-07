import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  static WMSTileLayer getNoaaTileLayer() {
    return WMSTileLayer(
      baseUrl: 'https://gis.charttools.noaa.gov/arcgis/services/MarineChart_Services/NOAACharts/MapServer/WMSServer?',
      layerNames: ['0'],
      version: '1.3.0',
      format: 'image/png',
      transparent: true,
      crs: const Epsg3857(),
      userAgentPackageName: 'com.example.free_open_ocean',
    );
  }

  static RichAttributionWidget getAttribution() {
    return RichAttributionWidget(
      attributions: [
        TextSourceAttribution(
          'NOAA Nautical Charts',
          onTap: () => {}, // TODO: open NOAA websites
        ),
      ],
    );
  }

  static MapOptions getDefaultOptions() {
    return MapOptions(
      initialCenter: LatLng(39.8283, -98.5795), // Center of USA
      initialZoom: 5.0,
    );
  }
}
