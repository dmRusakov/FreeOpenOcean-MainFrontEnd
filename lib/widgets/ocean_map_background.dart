import 'dart:math' show Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/map_service.dart';
import '../web_setup_stub.dart'
    if (dart.library.html) '../web_setup.dart'
    as web_setup;

/// Full-bleed MapLibre map used as the app background (and ocean charts surface).
class OceanMapBackground extends StatefulWidget {
  final bool interactive;

  /// Compass is only shown on Charts; other pages keep attribution only.
  final bool showCompass;
  final ValueChanged<MapLibreMapController>? onMapCreated;
  final ValueChanged<CameraPosition>? onCameraMove;

  const OceanMapBackground({
    super.key,
    this.interactive = false,
    this.showCompass = false,
    this.onMapCreated,
    this.onCameraMove,
  });

  @override
  State<OceanMapBackground> createState() => _OceanMapBackgroundState();
}

class _OceanMapBackgroundState extends State<OceanMapBackground> {
  MapLibreMapController? _controller;
  int _styleGeneration = 0;
  Brightness? _brightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_brightness != brightness) {
      _brightness = brightness;
      _styleGeneration++;
    }
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final generation = ++_styleGeneration;
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
    final styleUrl = MapService.getStyleUrl(Theme.of(context).brightness);
    if (kIsWeb) {
      web_setup.setMapControlInsets(0, 0);
      web_setup.setMapInteractive(interactive);
    }

    Widget map = MapLibreMap(
      styleString: styleUrl,
      initialCameraPosition: const CameraPosition(
        target: LatLng(0, 0),
        zoom: 2,
      ),
      // Only Charts (interactive) may pan/zoom; other pages treat map as backdrop.
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
      doubleClickZoomEnabled: interactive,
      dragEnabled: interactive,
      trackCameraPosition: widget.onCameraMove != null,
      onCameraMove: widget.onCameraMove,
      compassEnabled: showCompass,
      compassViewPosition: showCompass ? CompassViewPosition.bottomRight : null,
      compassViewMargins: showCompass && !kIsWeb ? const Point(0, 0) : null,
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
      attributionButtonMargins: kIsWeb ? null : const Point(0, 0),
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
        if (kIsWeb) MapService.getCurrentLocation(controller);
      },
      onStyleLoadedCallback: _onStyleLoaded,
    );

    if (!interactive) {
      map = IgnorePointer(child: map);
    }
    return map;
  }
}
