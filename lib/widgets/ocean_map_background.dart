import 'dart:async';
import 'dart:math' show Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/map_chart_settings.dart';
import '../services/map_service.dart';
import '../web_setup_stub.dart'
    if (dart.library.html) '../web_setup.dart'
    as web_setup;

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

  void _onFeatureTapped(
    Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    if (layerId == 'moon-hit') {
      _showOrbit('moon-orbit', false);
    } else if (layerId == 'sun-hit') {
      _showOrbit('equator', true);
    }
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
