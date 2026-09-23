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
  final _zoom = ValueNotifier<double>(2);
  final _visibleZoom = ValueNotifier<double?>(null);
  final _visibleBearing = ValueNotifier<double?>(null);
  Timer? _zoomHideTimer;
  Timer? _bearingHideTimer;

  double _dragBearing = 0;
  String? _shownZoom;
  String? _shownBearing;

  double _normalizeBearing(double bearing) {
    final normalized = bearing % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  void _holdVisible(
    ValueNotifier<double?> visible,
    Timer? timer,
    double value,
    void Function(Timer) store,
  ) {
    visible.value = value;
    timer?.cancel();
    store(Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      visible.value = null;
      _publishHeader();
    }));
  }

  void _updateBearing(double bearing, {bool reveal = true}) {
    final normalized = _normalizeBearing(bearing);
    final difference = (normalized - _bearing.value + 180) % 360 - 180;
    if (difference.abs() < 0.000001) return;
    _bearing.value = normalized;
    if (!reveal) return;
    _holdVisible(_visibleBearing, _bearingHideTimer, normalized, (timer) {
      _bearingHideTimer = timer;
    });
    _publishHeader();
  }

  Widget _buildBearingLabel() {
    final bearing = _visibleBearing.value;
    if (bearing == null) return const SizedBox(width: 80, height: 18);
    final degrees = bearing.round() % 360;
    return SizedBox(
      width: 80,
      height: 18,
      child: _buildIndicator(
        null,
        '$degrees°',
        'Compass angle $degrees degrees',
      ),
    );
  }

  void _updateZoom(double zoom, {bool reveal = true}) {
    if ((zoom - _zoom.value).abs() < 0.000001) return;
    _zoom.value = zoom;
    if (!reveal) return;
    _holdVisible(_visibleZoom, _zoomHideTimer, zoom, (timer) {
      _zoomHideTimer = timer;
    });
    _publishHeader();
  }

  Widget _buildZoomLabel() {
    final zoom = _visibleZoom.value;
    if (zoom == null) return const SizedBox(width: 88, height: 18);
    return SizedBox(
      width: 88,
      height: 18,
      child: _buildIndicator(
        Icons.search,
        zoom.toStringAsFixed(1),
        'Current zoom ${zoom.toStringAsFixed(1)}',
      ),
    );
  }

  void _publishHeader({bool force = false}) {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;
    final zoomText = _visibleZoom.value?.toStringAsFixed(1);
    final bearingText = _visibleBearing.value == null
        ? null
        : '${_visibleBearing.value!.round() % 360}';
    if (!force && zoomText == _shownZoom && bearingText == _shownBearing) {
      return;
    }
    _shownZoom = zoomText;
    _shownBearing = bearingText;
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
  }

  Widget _buildIndicator(IconData? icon, String value, String label) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
    final color = style?.color;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == null)
            Text('∠', style: style)
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: style),
        ],
      ),
    );
  }

  ButtonStyle get _headerButtonStyle => IconButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size(40, 40),
    fixedSize: const Size(40, 40),
    padding: EdgeInsets.zero,
    iconSize: 20,
  );

  Widget _zoomButton(String label, IconData icon, double delta) =>
      PointerInterceptor(
        child: Semantics(
          label: label,
          button: true,
          child: IconButton.filledTonal(
            style: _headerButtonStyle,
            onPressed: () =>
                _mapController?.animateCamera(CameraUpdate.zoomBy(delta)),
            icon: Icon(icon),
          ),
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
          style: _headerButtonStyle,
          padding: EdgeInsets.zero,
          iconSize: 36,
          onPressed: () =>
              _mapController?.animateCamera(CameraUpdate.bearingTo(0)),
          icon: Transform.rotate(
            angle: -bearing * pi / 180,
            child: CustomPaint(
              size: const Size.square(36),
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
      _publishHeader(force: true);
    });
  }

  Widget _controlWithLabel(Widget control, Widget label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(height: 40, child: control),
      const SizedBox(height: 2),
      SizedBox(height: 18, child: Center(child: label)),
    ],
  );

  @override
  void dispose() {
    clearTopBar(ownerId: 'ocean_charts');
    _mapController = null;
    _zoomHideTimer?.cancel();
    _bearingHideTimer?.cancel();
    _bearing.dispose();
    _zoom.dispose();
    _visibleZoom.dispose();
    _visibleBearing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      fullScreen: true,
      onMapCreated: (controller) {
        _mapController = controller;
        final camera = controller.cameraPosition;
        if (camera == null) return;
        _updateZoom(camera.zoom, reveal: false);
        _updateBearing(camera.bearing, reveal: false);
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
