import 'dart:async';
import 'dart:math' as math;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/services/map_service.dart';
import 'package:free_open_ocean/core/theme/marine_palette.dart';
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
  Timer? _viewUrlTimer;
  String? _urlLat;
  String? _urlLon;
  String? _urlZoom;
  LatLng? _userLocation;
  LatLng? _mapCenter;
  StreamSubscription<Position>? _positionSub;
  bool? _shownCenter;

  double _dragBearing = 0;
  String? _shownZoom;
  String? _shownBearing;

  @override
  void initState() {
    super.initState();
    unawaited(_watchUserLocation());
  }

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
    if (bearing == null) return const SizedBox(height: 18);
    final degrees = bearing.round() % 360;
    return SizedBox(
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
    final showCenter = _isOffCenter;
    if (!force &&
        zoomText == _shownZoom &&
        bearingText == _shownBearing &&
        showCenter == _shownCenter) {
      return;
    }
    _shownZoom = zoomText;
    _shownBearing = bearingText;
    _shownCenter = showCenter;
    setTopBar(
      title: localizations.translate('ocean_charts'),
      ownerId: 'ocean_charts',
      submenu: [
        if (showCenter) ...[
          _controlWithLabel(_centerButton(), const SizedBox(height: 18)),
          const SizedBox(width: 8),
        ],
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
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: scheme.onSurface);
    final color = style?.color;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon == null)
                Text('∠', style: style)
              else
                Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(value, style: style),
            ],
          ),
        ),
      ),
    );
  }

  /// Chart controls float on whatever the map happens to be showing, so they
  /// carry their own surface and rim instead of relying on the map behind
  /// them for contrast.
  ButtonStyle get _headerButtonStyle {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(40, 40),
      fixedSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      iconSize: 20,
      backgroundColor: scheme.surface.withValues(alpha: 0.88),
      foregroundColor: scheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
      ),
    );
  }

  // GPS wander of a few dozen metres is still "on the center". A real pan
  // moves the chart much farther than that.
  static const _centerToleranceMeters = 80.0;

  bool get _isOffCenter {
    final user = _userLocation;
    final center = _mapCenter;
    if (user == null || center == null) return false;
    return _metersBetween(user, center) > _centerToleranceMeters;
  }

  double _metersBetween(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * earth * math.asin(math.sqrt(h));
  }

  void _rememberMapCenter(LatLng center) {
    _mapCenter = center;
    final show = _isOffCenter;
    if (show == _shownCenter) return;
    _publishHeader(force: true);
  }

  void _setUserLocation(Position position) {
    _userLocation = LatLng(position.latitude, position.longitude);
    final show = _isOffCenter;
    if (show == _shownCenter) return;
    _publishHeader(force: true);
  }

  Future<void> _watchUserLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled || !mounted) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _setUserLocation(position);
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(_setUserLocation, onError: (_) {});
    } catch (error) {
      debugPrint('Unable to read current position: $error');
    }
  }

  Widget _centerButton() => PointerInterceptor(
    child: Semantics(
      label: 'Center map on current position',
      button: true,
      child: IconButton(
        style: _headerButtonStyle,
        onPressed: () {
          final user = _userLocation;
          if (user == null) return;
          _mapController?.animateCamera(CameraUpdate.newLatLng(user));
        },
        icon: const Icon(Icons.my_location),
      ),
    ),
  );

  Widget _zoomButton(String label, IconData icon, double delta) =>
      PointerInterceptor(
        child: Semantics(
          label: label,
          button: true,
          child: IconButton(
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
            angle: -bearing * math.pi / 180,
            child: CustomPaint(
              size: const Size.square(36),
              painter: _CompassPainter(
                rimColor: Theme.of(context).colorScheme.onSurfaceVariant,
                northColor: MarinePalette.of(
                  Theme.of(context).brightness,
                ).chrome.danger,
                southColor: MarinePalette.of(
                  Theme.of(context).brightness,
                ).chrome.inkFaint,
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

  Widget _controlWithLabel(Widget control, Widget label) => Stack(
    alignment: Alignment.topCenter,
    clipBehavior: Clip.none,
    children: [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 40, child: control),
          const SizedBox(height: 20),
        ],
      ),
      Positioned(
        top: 42,
        left: 0,
        right: 0,
        height: 18,
        child: OverflowBox(
          maxWidth: 120,
          alignment: Alignment.topCenter,
          child: label,
        ),
      ),
    ],
  );

  CameraPosition? _cameraFromParams(Map<String, String>? params) {
    if (params == null) return null;
    final lat = double.tryParse(params['lat'] ?? '');
    final lon = double.tryParse(params['lon'] ?? '');
    final zoom = double.tryParse(params['zoom'] ?? '');
    if (lat == null || lon == null || zoom == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return CameraPosition(
      target: LatLng(lat, _wrapLongitude(lon)),
      zoom: zoom.clamp(2, 22),
    );
  }

  double _wrapLongitude(double longitude) {
    var value = longitude % 360;
    if (value > 180) value -= 360;
    if (value < -180) value += 360;
    return value;
  }

  void _rememberView(CameraPosition camera) {
    _urlLat = camera.target.latitude.toStringAsFixed(5);
    _urlLon = _wrapLongitude(camera.target.longitude).toStringAsFixed(5);
    _urlZoom = camera.zoom.clamp(2, 22).toStringAsFixed(2);
  }

  bool _isRememberedView(CameraPosition? camera) {
    if (camera == null) return false;
    return camera.target.latitude.toStringAsFixed(5) == _urlLat &&
        _wrapLongitude(camera.target.longitude).toStringAsFixed(5) == _urlLon &&
        camera.zoom.clamp(2, 22).toStringAsFixed(2) == _urlZoom;
  }

  void _scheduleViewUrl(CameraPosition camera) {
    _viewUrlTimer?.cancel();
    _viewUrlTimer = Timer(const Duration(milliseconds: 200), () {
      _writeViewUrl(camera);
    });
  }

  void _writeViewUrl(CameraPosition camera) {
    if (!mounted || _isRememberedView(camera)) return;
    _rememberView(camera);
    final uri = GoRouterState.of(context).uri;
    final params = Map<String, String>.from(uri.queryParameters);
    params['lat'] = _urlLat!;
    params['lon'] = _urlLon!;
    params['zoom'] = _urlZoom!;
    GoRouter.of(context).replace<void>(uri.replace(queryParameters: params).toString());
  }

  void _showViewFromUrl(Map<String, String>? params) {
    final camera = _cameraFromParams(params);
    final controller = _mapController;
    if (camera == null || controller == null || _isRememberedView(camera)) {
      return;
    }
    _rememberView(camera);
    controller.moveCamera(
      CameraUpdate.newLatLngZoom(camera.target, camera.zoom),
    );
  }

  @override
  void didUpdateWidget(covariant OceanCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    _showViewFromUrl(widget.params);
  }

  @override
  void dispose() {
    clearTopBar(ownerId: 'ocean_charts');
    _mapController = null;
    _zoomHideTimer?.cancel();
    _bearingHideTimer?.cancel();
    _viewUrlTimer?.cancel();
    _positionSub?.cancel();
    _bearing.dispose();
    _zoom.dispose();
    _visibleZoom.dispose();
    _visibleBearing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedView = _cameraFromParams(widget.params);
    return PageTemplate(
      fullScreen: true,
      initialCamera: sharedView,
      onMapCreated: (controller) {
        _mapController = controller;
        final camera = controller.cameraPosition;
        if (sharedView != null) {
          _rememberView(sharedView);
          _updateZoom(sharedView.zoom, reveal: false);
          if (camera != null) _updateBearing(camera.bearing, reveal: false);
          if (!_isRememberedView(camera)) {
            controller.moveCamera(
              CameraUpdate.newLatLngZoom(sharedView.target, sharedView.zoom),
            );
          }
          _rememberMapCenter(sharedView.target);
          return;
        }
        if (camera == null) return;
        _updateZoom(camera.zoom, reveal: false);
        _updateBearing(camera.bearing, reveal: false);
        _writeViewUrl(camera);
        _rememberMapCenter(camera.target);
      },
      onCameraIdle: () {
        final controller = _mapController;
        if (controller != null) {
          unawaited(MapService.syncSeamarkNames(controller));
          unawaited(MapService.syncOilPlatforms(controller));
          unawaited(MapService.syncLighthouses(controller));
          unawaited(MapService.syncSlipways(controller));
          final camera = controller.cameraPosition;
          if (camera != null) {
            _viewUrlTimer?.cancel();
            _writeViewUrl(camera);
          }
        }
      },
      onCameraMove: (position) {
        final controller = _mapController;
        if (controller != null) {
          MapService.syncSmallDetail(controller, position.zoom);
        }
        if (mounted) {
          _updateBearing(position.bearing);
          _updateZoom(position.zoom);
          _rememberMapCenter(position.target);
          _scheduleViewUrl(position);
        }
      },
      body: const SizedBox.expand(),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    required this.rimColor,
    required this.northColor,
    required this.southColor,
  });

  final Color rimColor;
  final Color northColor;
  final Color southColor;

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
    canvas.drawPath(north, Paint()..color = northColor);
    canvas.drawPath(south, Paint()..color = southColor);
    canvas.drawCircle(center, 1.5, Paint()..color = rimColor);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) =>
      oldDelegate.rimColor != rimColor ||
      oldDelegate.northColor != northColor ||
      oldDelegate.southColor != southColor;
}
