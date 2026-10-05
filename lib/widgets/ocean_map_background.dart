import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../core/localization/app_localizations.dart';
import '../services/map_chart_settings.dart';
import '../services/map_service.dart';
import '../services/marine_object_info.dart';
import '../web_setup_stub.dart'
    if (dart.library.html) '../web_setup.dart'
    as web_setup;
import 'marine_object_sheet.dart';

/// Full-bleed MapLibre map used as the app background (and ocean charts surface).
class OceanMapBackground extends StatefulWidget {
  final bool interactive;

  /// Compass is only shown on Charts; other pages keep attribution only.
  final bool showCompass;

  /// Shifts attribution left when a panel covers the right side of the chart.
  final double controlRightInset;
  final ValueChanged<MapLibreMapController>? onMapCreated;
  final ValueChanged<CameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;
  final CameraPosition? initialCamera;

  const OceanMapBackground({
    super.key,
    this.interactive = false,
    this.showCompass = false,
    this.controlRightInset = 0,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.initialCamera,
  });

  @override
  State<OceanMapBackground> createState() => _OceanMapBackgroundState();
}

class _OceanMapBackgroundState extends State<OceanMapBackground> {
  MapLibreMapController? _controller;
  int _styleGeneration = 0;
  Brightness? _brightness;
  String? _language;
  Timer? _moonOrbitTimer;
  Timer? _sunOrbitTimer;
  bool _showingMarineInfo = false;

  @override
  void initState() {
    super.initState();
    MapChartSettings.instance.addListener(_onChartSettings);
  }

  void _onChartSettings() {
    final controller = _controller;
    final brightness = _brightness;
    final language = _language;
    if (controller == null || brightness == null || language == null) return;
    if (!mounted) return;
    controller.setStyle(MapService.getStyleUrl(brightness, language));
  }

  void _showOrbit(String layerId, bool sun) {
    final timer = sun ? _sunOrbitTimer : _moonOrbitTimer;
    timer?.cancel();
    _controller?.setLayerVisibility(layerId, true);
    final hide = Timer(const Duration(seconds: 5), () {
      _controller?.setLayerVisibility(layerId, false);
    });
    if (sun) {
      _sunOrbitTimer = hide;
    } else {
      _moonOrbitTimer = hide;
    }
  }

  Future<void> _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) async {
    if (layerId == 'moon-hit') {
      _showOrbit('moon-orbit', false);
      return;
    }
    if (layerId == 'sun-hit') {
      _showOrbit('equator', true);
      return;
    }
    if (!MapService.marineObjectLayers.contains(layerId)) return;
    await _openMarineObjectInfo(point, layerId, coordinates);
  }

  Future<void> _openMarineObjectInfo(
    Point<double> point,
    String layerId,
    LatLng coordinates,
  ) async {
    if (_showingMarineInfo || !mounted) return;
    final controller = _controller;
    if (controller == null) return;
    _showingMarineInfo = true;
    try {
      final hits = await controller.queryRenderedFeatures(
        point,
        [layerId],
        null,
      );
      Map<String, dynamic>? feature;
      for (final hit in hits) {
        if (hit is Map) {
          feature = {
            for (final entry in hit.entries) entry.key.toString(): entry.value,
          };
          break;
        }
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final info = feature == null
          ? MarineObjectInfo(
              title: MarineObjectInfo.defaultTypeLabel(layerId),
              typeLabel: _localizedType(l10n, layerId),
              sourceLabel: _sourceForLayer(layerId),
              latitude: coordinates.latitude,
              longitude: coordinates.longitude,
              layerId: layerId,
            )
          : MarineObjectInfo.fromFeature(
              feature,
              layerId: layerId,
              typeLabelOf: (kind) => _localizedType(l10n, kind),
            );
      if (info == null || !mounted) return;
      await showMarineObjectInfoDialog(context, info);
    } finally {
      _showingMarineInfo = false;
    }
  }

  String _localizedType(AppLocalizations? l10n, String kind) {
    if (l10n == null) return MarineObjectInfo.defaultTypeLabel(kind);
    const keys = {
      'marina': 'map_color_marina',
      'harbour': 'map_color_marina',
      'anchorage': 'map_color_anchorage',
      'fuel': 'map_color_fuel',
      'customs': 'map_color_customs',
      'harbourmaster': 'map_color_port',
      'naval_base': 'map_color_port',
      'slipway': 'map_color_slipway',
      'dock': 'map_color_dock',
      'ferry': 'map_color_ferry_route',
      'ferry_terminal': 'map_color_ferry',
      'lighthouse': 'map_color_nav_light',
      'light_major': 'map_color_nav_light',
      'offshore_platform': 'map_color_platform',
      'small_craft_facility': 'map_color_hazard',
      'boat': 'map_color_service',
      'boat_rental': 'map_color_service',
      'boat_repair': 'map_color_service',
      'boat_storage': 'map_color_service',
      'ship_chandler': 'map_color_service',
    };
    final key = keys[kind];
    if (key != null) return l10n.translate(key);
    return MarineObjectInfo.defaultTypeLabel(kind);
  }

  String _sourceForLayer(String layerId) {
    return 'OpenStreetMap';
  }

  @override
  void dispose() {
    MapChartSettings.instance.removeListener(_onChartSettings);
    _moonOrbitTimer?.cancel();
    _sunOrbitTimer?.cancel();
    _controller?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final language = Localizations.localeOf(context).languageCode;
    if (_brightness != brightness || _language != language) {
      _brightness = brightness;
      _language = language;
      _styleGeneration++;
    }
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final generation = ++_styleGeneration;
    _moonOrbitTimer?.cancel();
    _sunOrbitTimer?.cancel();
    await MapService.addIslandOverlay(
      controller,
      _brightness!,
      () => mounted && generation == _styleGeneration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.interactive;
    final showCompass = widget.showCompass;
    final styleUrl = MapService.getStyleUrl(
      Theme.of(context).brightness,
      Localizations.localeOf(context).languageCode,
    );
    if (kIsWeb) {
      web_setup.setMapControlInsets(widget.controlRightInset, 0);
      web_setup.setMapInteractive(interactive);
    }

    Widget map = MapLibreMap(
      styleString: styleUrl,
      initialCameraPosition: widget.initialCamera ??
          const CameraPosition(
            target: LatLng(0, 0),
            zoom: 5,
          ),
      minMaxZoomPreference: const MinMaxZoomPreference(2, null),
      // Only Charts (interactive) may pan/zoom; other pages treat map as backdrop.
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
      doubleClickZoomEnabled: interactive,
      dragEnabled: interactive,
      trackCameraPosition: widget.onCameraMove != null,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
      compassEnabled: showCompass,
      compassViewPosition: showCompass ? CompassViewPosition.bottomRight : null,
      compassViewMargins: showCompass && !kIsWeb ? const Point(0, 0) : null,
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
      attributionButtonMargins: kIsWeb ? null : const Point(0, 0),
      onMapCreated: (controller) {
        _controller = controller;
        controller.onFeatureTapped.add(_onFeatureTapped);
        widget.onMapCreated?.call(controller);
        if (kIsWeb && widget.initialCamera == null) {
          MapService.getCurrentLocation(controller);
        }
      },
      onStyleLoadedCallback: _onStyleLoaded,
    );

    // Keep the same parent when interaction turns on, so the chart is not rebuilt.
    return IgnorePointer(
      ignoring: !interactive,
      child: map,
    );
  }
}
