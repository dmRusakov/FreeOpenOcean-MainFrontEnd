import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'map_object_icon_catalog.dart';

/// One Material icon a chart object can use.
class ChartObjectIcon {
  const ChartObjectIcon(this.codePoint, {this.fontFamily, this.fontPackage});

  factory ChartObjectIcon.fromIconData(IconData data) => ChartObjectIcon(
    data.codePoint,
    fontFamily: data.fontFamily,
    fontPackage: data.fontPackage,
  );

  final int codePoint;
  final String? fontFamily;
  final String? fontPackage;

  IconData get data => IconData(
    codePoint,
    fontFamily: fontFamily ?? 'MaterialIcons',
    fontPackage: fontPackage,
  );

  Map<String, Object?> toJson() => {
    'codePoint': codePoint,
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontPackage != null) 'fontPackage': fontPackage,
  };

  static ChartObjectIcon? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final code = raw['codePoint'];
    if (code is! num) return null;
    return ChartObjectIcon(
      code.toInt(),
      fontFamily: raw['fontFamily']?.toString(),
      fontPackage: raw['fontPackage']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChartObjectIcon &&
      other.codePoint == codePoint &&
      other.fontFamily == fontFamily &&
      other.fontPackage == fontPackage;

  @override
  int get hashCode => Object.hash(codePoint, fontFamily, fontPackage);
}

/// Colour-field ids on Marine objects that draw a point icon on the chart.
const mapObjectIconFields = <String>{
  'marina',
  'anchorage',
  'fuel',
  'customs',
  'port',
  'service',
  'dock',
  'slipway',
  'hazard',
  'platform',
  'navLight',
};

/// Built-in icons before the user picks another.
const mapObjectIconDefaults = <String, IconData>{
  'marina': Icons.sailing,
  'anchorage': Icons.anchor,
  'fuel': Icons.local_gas_station,
  'customs': Icons.badge_outlined,
  'port': Icons.home_work_outlined,
  'service': Icons.build_circle_outlined,
  'dock': Icons.directions_boat_filled,
  'slipway': Icons.call_made,
  'hazard': Icons.warning_amber_rounded,
  'platform': Icons.oil_barrel,
  'navLight': Icons.lightbulb_outline,
};

/// MapLibre image id for a Marine objects colour field.
String mapObjectImageId(String field) => 'foo-obj-$field';

/// Renders [icon] as a PNG with a rounded square border for the chart.
class MapObjectIcons {
  static const imageSize = 64.0;
  static const borderRadius = 6.0;
  static const borderWidth = 2.0;

  static Future<Uint8List> render(
    IconData icon,
    Color iconColor,
    Color borderColor,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = imageSize;
    final inset = borderWidth / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size - borderWidth, size - borderWidth),
      const Radius.circular(borderRadius),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor,
    );
    // Fill the square inside the border; leave a small gap so the glyph
    // does not touch the stroke.
    final glyphSize = size - borderWidth * 2 - 4;
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: glyphSize,
          color: iconColor,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
