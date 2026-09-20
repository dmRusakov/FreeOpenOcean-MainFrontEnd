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

  double _dragBearing = 0;

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
        builder: (context, bearing, _) => IconButton.filledTonal(
          tooltip: 'Click to face north; drag to rotate',
          onPressed: () => _mapController?.animateCamera(CameraUpdate.bearingTo(0)),
          icon: Transform.rotate(
            angle: -bearing * pi / 180,
            child: const Icon(Icons.navigation),
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
        submenu: [_buildCompass()],
      );
    });
  }

  @override
  void dispose() {
    clearTopBar(ownerId: 'ocean_charts');
    _mapController = null;
    _bearing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      fullScreen: true,
      onMapCreated: (controller) => _mapController = controller,
      onCameraMove: (position) {
        if (mounted) _bearing.value = position.bearing;
      },
      body: const SizedBox.expand(),
    );
  }
}
