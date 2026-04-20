import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

enum AppThemeEnum { main_theme, /*minimalistic_theme*/ }

enum ThemeModeOptionEnum { auto, light, dark }

enum DeviceType { mobile, tablet, desktop, tv }

enum DeviceTypeOverride { auto, mobile, tablet, desktop, tv }

abstract class AppTheme {
  Map<String, dynamic> get defaultSizes;
  Map<String, dynamic> get mobileSizes;
  Map<String, dynamic> get tabletSizes;
  Map<String, dynamic> get desktopSizes;
  Map<String, dynamic> get tvSizes;

  Map<String, dynamic> get colors;
  Map<String, dynamic> get lightColors;
  Map<String, dynamic> get darkColors;

  double get maxWidth;
  Map<String, Style> get pageStyles;

  dynamic getColor(String key, Brightness brightness) {
    final baseColor = colors[key];
    final modeColor = (brightness == Brightness.dark) ? darkColors[key] : lightColors[key];

    if (baseColor is Map && modeColor is Map) {
      return {...baseColor, ...modeColor};
    }

    return modeColor ?? baseColor;
  }

  Map<String, dynamic> _getDeviceSizes(DeviceType device) {
    switch (device) {
      case DeviceType.mobile:
        return mobileSizes;
      case DeviceType.tablet:
        return tabletSizes;
      case DeviceType.desktop:
        return desktopSizes;
      case DeviceType.tv:
        return tvSizes;
    }
  }

  Map<String, dynamic> getSizesForDevice(DeviceType device) {
    final deviceSpecificSizes = _getDeviceSizes(device);
    final finalSizes = <String, dynamic>{};
    final allKeys = {...defaultSizes.keys, ...deviceSpecificSizes.keys};

    for (final key in allKeys) {
      final defaultVal = defaultSizes[key];
      final specificVal = deviceSpecificSizes[key];

      if (defaultVal is Map && specificVal is Map) {
        // Explicitly create a <String, dynamic> map to avoid type errors.
        finalSizes[key] = <String, dynamic>{...defaultVal, ...specificVal};
      } else {
        finalSizes[key] = specificVal ?? defaultVal;
      }
    }
    return finalSizes;
  }
}

class ThemeValues {
  final dynamic color;
  final Map<String, dynamic> sizes;

  const ThemeValues({required this.color, required this.sizes});
}
