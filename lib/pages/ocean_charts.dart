import 'dart:async';
import 'dart:math' show pi;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';

class OceanCharts extends StatefulWidget {
  final Map<String, String>? params;

  const OceanCharts({super.key, this.params});

  @override
  State<OceanCharts> createState() => _OceanChartsState();
}

class _OceanChartsState extends State<OceanCharts> {
  MapLibreMapController? _mapController;
  final _bearing = ValueNotifier<double>(0);
  final _visibleZoom = ValueNotifier<double?>(null);
  double _lastZoom = 2;
  Timer? _zoomHideTimer;
  final _visibleBearing = ValueNotifier<double?>(null);
  Timer? _bearingHideTimer;

  double _dragBearing = 0;

  void _updateBearing(double bearing) {
    final normalized = bearing % 360;
    final difference = (normalized - _bearing.value + 180) % 360 - 180;
    if (difference.abs() < 0.000001) return;
    _bearing.value = normalized;
    _visibleBearing.value = normalized;
    _bearingHideTimer?.cancel();
    _bearingHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _visibleBearing.value = null;
    });
  }

  Widget _buildBearingLabel() => ValueListenableBuilder<double?>(
    valueListenable: _visibleBearing,
    builder: (context, bearing, _) => SizedBox(
      width: 80,
      child: bearing == null
          ? null
          : _buildIndicator(
              null,
              '${bearing.round() % 360}°',
              'Compass angle ${bearing.round() % 360} degrees',
            ),
    ),
  );

  void _updateZoom(double zoom) {
    if ((zoom - _lastZoom).abs() < 0.000001) return;
    _lastZoom = zoom;
    _visibleZoom.value = zoom;
    _zoomHideTimer?.cancel();
    _zoomHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _visibleZoom.value = null;
    });
  }

  Widget _buildZoomLabel() => ValueListenableBuilder<double?>(
    valueListenable: _visibleZoom,
    builder: (context, zoom, _) => SizedBox(
      width: 72,
      child: zoom == null
          ? null
          : _buildIndicator(
              Icons.search,
              zoom.toStringAsFixed(1),
              'Current zoom ${zoom.toStringAsFixed(1)}',
            ),
    ),
  );

  Widget _buildIndicator(IconData? icon, String value, String label) =>
      Semantics(
        label: label,
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon == null)
              Text('∠', style: Theme.of(context).textTheme.labelSmall)
            else
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).textTheme.labelSmall?.color,
              ),
            const SizedBox(width: 4),
            Text(value, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );

  Widget _zoomButton(String label, IconData icon, double delta) =>
      PointerInterceptor(
        child: IconButton.filledTonal(
          tooltip: label,
          onPressed: () =>
              _mapController?.animateCamera(CameraUpdate.zoomBy(delta)),
          icon: Icon(icon),
        ),
      );

  Widget _buildCompass() => PointerInterceptor(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _dragBearing = _bearing.value,
      onPanUpdate: (details) {
        _dragBearing += details.delta.dx;
        _mapController?.moveCamera(CameraUpdate.bearingTo(_dragBearing));
      },
      child: ValueListenableBuilder<double>(
        valueListenable: _bearing,
        builder: (context, bearing, _) => IconButton(
          padding: EdgeInsets.zero,
          iconSize: 40,
          tooltip:
              'Red: north; blue: south. Click to face north; drag to rotate',
          onPressed: () =>
              _mapController?.animateCamera(CameraUpdate.bearingTo(0)),
          icon: Transform.rotate(
            angle: -bearing * pi / 180,
            child: CustomPaint(
              size: const Size.square(40),
              painter: _CompassPainter(
                rimColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context)!;
      setTopBar(
        title: localizations.translate('ocean_charts'),
        ownerId: 'ocean_charts',
        submenu: [
          _controlWithLabel(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomButton('Zoom in', Icons.add, 1),
                const SizedBox(width: 8),
                _zoomButton('Zoom out', Icons.remove, -1),
              ],
            ),
            _buildZoomLabel(),
          ),
          const SizedBox(width: 8),
          _controlWithLabel(_buildCompass(), _buildBearingLabel()),
        ],
      );
    });
  }

  Widget _controlWithLabel(Widget control, Widget label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(height: 40, child: control),
      SizedBox(height: 16, child: IgnorePointer(child: label)),
    ],
  );

  @override
  void dispose() {
    clearTopBar(ownerId: 'ocean_charts');
    _mapController = null;
    _bearing.dispose();
    _zoomHideTimer?.cancel();
    _visibleZoom.dispose();
    _bearingHideTimer?.cancel();
    _visibleBearing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      fullScreen: true,
      onMapCreated: (controller) {
        _mapController = controller;
        _lastZoom = controller.cameraPosition?.zoom ?? 2;
      },
      onCameraMove: (position) {
        if (mounted) {
          _updateBearing(position.bearing);
          _updateZoom(position.zoom);
        }
      },
      body: const SizedBox.expand(),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({required this.rimColor});

  final Color rimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = rimColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final north = Path()
      ..moveTo(center.dx, center.dy - radius + 3)
      ..lineTo(center.dx + radius / 3, center.dy)
      ..lineTo(center.dx - radius / 3, center.dy)
      ..close();
    final south = Path()
      ..moveTo(center.dx, center.dy + radius - 3)
      ..lineTo(center.dx - radius / 3, center.dy)
      ..lineTo(center.dx + radius / 3, center.dy)
      ..close();
    canvas.drawPath(north, Paint()..color = Colors.redAccent);
    canvas.drawPath(south, Paint()..color = Colors.blueAccent);
    canvas.drawCircle(center, 1.5, Paint()..color = rimColor);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) =>
      oldDelegate.rimColor != rimColor;
}
