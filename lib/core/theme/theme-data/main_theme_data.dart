import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:flutter_html/flutter_html.dart';

class MainThemeData extends AppTheme {

  @override
  Map<String, dynamic> get defaultSizes => {
    // page layout
    'pageLayout': <String, dynamic>{
      'topHeader': false,
      'footer': true,
    },
    'topHeader': <String, dynamic>{
      'padding': const EdgeInsets.all(2),
    },
    'header': <String, dynamic>{
      'padding': const EdgeInsets.symmetric(horizontal: 20)
    },
    'footer': <String, dynamic>{
      'height': 30.0,
      'fontSize': 10.0,
      'padding': const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    },
    'menu': <String, dynamic>{
      'margin': const EdgeInsets.all(10.0),
      'border': BorderRadius.circular(10.0),
      'headerHeight': 70.0,
      'headerMargin': EdgeInsets.zero,
      'headerPadding': EdgeInsets.symmetric(horizontal: 10.0),
      'headerButtonSize': 'm',
    },

    // logo
    'logo': <String, dynamic>{
      'padding': const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      'borderRadius': BorderRadius.circular(20),
    },

    // buttons
    'btn_s': <String, dynamic>{
      'fontSize': 13.0,
      'height': 25.0,
      'padding': const EdgeInsets.symmetric(horizontal: 7),
      'borderRadius': BorderRadius.circular(18.0),
      'alignment': Alignment.center,
    },
    'btn_m': <String, dynamic>{
      'fontSize': 16.0,
      'height': 30.0,
      'padding': const EdgeInsets.symmetric(horizontal: 10),
      'borderRadius': BorderRadius.circular(20.0),
      'alignment': Alignment.center,
    },
    'btn_l': <String, dynamic>{
      'iconSize': 19.0,
      'fontSize': 19.0,
      'height': 35.0,
      'padding': const EdgeInsets.symmetric(horizontal: 10),
      'borderRadius': BorderRadius.circular(20.0),
      'alignment': Alignment.center,
    },
    'btn_xl': <String, dynamic>{
      'iconSize': 24.0,
      'fontSize': 24.0,
      'height': 42.0,
      'padding': const EdgeInsets.symmetric(horizontal: 10),
      'borderRadius': BorderRadius.circular(20.0),
      'alignment': Alignment.center,
    },

    // dropdowns
    'dd_s': <String, dynamic>{
      'fontSize': 15.0,
      'height': 25.0,
      'padding': const EdgeInsets.only(right: 3, left: 10),
      'borderRadius': BorderRadius.circular(12.0),
      'alignment': Alignment.center,
    },
    'dd_m': <String, dynamic>{
      'fontSize': 16.0,
      'height': 30.0,
      'padding': const EdgeInsets.only(right: 5, left: 12),
      'borderRadius': BorderRadius.circular(15.0),
      'alignment': Alignment.center,
    },
    'dd_l': <String, dynamic>{
      'iconSize': 19.0,
      'fontSize': 19.0,
      'height': 35.0,
      'padding': const EdgeInsets.only(right: 7, left: 13),
      'borderRadius': BorderRadius.circular(20.0),
      'alignment': Alignment.center,
    },
    'dd_xl': <String, dynamic>{
      'iconSize': 24.0,
      'fontSize': 24.0,
      'height': 42.0,
      'padding': const EdgeInsets.only(right: 10, left: 17),
      'borderRadius': BorderRadius.circular(25.0),
      'alignment': Alignment.center,
    },
  };

  @override
  Map<String, dynamic> get mobileSizes => {
    // 'topHeader': <String, dynamic>{'height': 25.0},
    // 'header': <String, dynamic>{'height': 40.0},
    // 'btn_s': <String, dynamic>{'fontSize': 12.0, 'iconSize': 14.0},
    // 'btn_m': <String, dynamic>{'fontSize': 14.0, 'iconSize': 16.0},
    // 'btn_l': <String, dynamic>{'fontSize': 16.0, 'iconSize': 18.0},
    // 'btn_xl': <String, dynamic>{'fontSize': 18.0, 'iconSize': 20.0},
  };

  @override
  Map<String, dynamic> get tabletSizes => {
    // 'topHeader': <String, dynamic>{'height': 30.0},
    // 'header': <String, dynamic>{'height': 50.0},
    // 'btn_s': <String, dynamic>{'fontSize': 16.0, 'iconSize': 20.0},
    // 'btn_m': <String, dynamic>{'fontSize': 19.0, 'iconSize': 24.0},
    // 'btn_l': <String, dynamic>{'fontSize': 21.0, 'iconSize': 27.0},
    // 'btn_xl': <String, dynamic>{'fontSize': 24.0, 'iconSize': 32.0},
  };

  @override
  Map<String, dynamic> get desktopSizes => {
    // 'topHeader': <String, dynamic>{'height': 35.0},
    // 'header': <String, dynamic>{'height': 60.0},
    // 'btn_s': <String, dynamic>{'fontSize': 18.0, 'iconSize': 22.0},
    // 'btn_m': <String, dynamic>{'fontSize': 21.0, 'iconSize': 26.0},
    // 'btn_l': <String, dynamic>{'fontSize': 23.0, 'iconSize': 29.0},
    // 'btn_xl': <String, dynamic>{'fontSize': 26.0, 'iconSize': 34.0},
  };

  @override
  Map<String, dynamic> get tvSizes => {
    // 'topHeader': <String, dynamic>{'height': 40.0},
    // 'header': <String, dynamic>{'height': 70.0},
    // 'btn_s': <String, dynamic>{'fontSize': 20.0, 'height': 45.0, 'iconSize': 24.0},
    // 'btn_m': <String, dynamic>{'fontSize': 23.0, 'height': 45.0, 'iconSize': 28.0},
    // 'btn_l': <String, dynamic>{'fontSize': 25.0, 'height': 51.0, 'iconSize': 31.0},
    // 'btn_xl': <String, dynamic>{'fontSize': 28.0, 'height': 45.0, 'iconSize': 36.0},
  };

  // Charcoal cabinetry, cool stone, walnut and warm stair lighting.
  static const charcoal = Color(0xFF101619);
  static const graphite = Color(0xFF252D31);
  static const stone = Color(0xFFB6BCBC);
  static const ivory = Color(0xFFF2F0EB);
  static const walnut = Color(0xFF795B4E);
  static const ember = Color(0xFFAD4925);
  static const warmAccent = Color(0xFFEFAB85);

  @override
  Map<String, dynamic> get colors => {
    'header': <String, dynamic>{'background': Colors.transparent},
    'footer': <String, dynamic>{
      'background': Colors.transparent,
      'text': ivory,
    },
    'primary': ember,
    'secondary': walnut,
    'success': const Color(0xFF466354),
    'error': const Color(0xFFA63F36),
    'warning': const Color(0xFF825E28),
    'info': graphite,
    'btn_primary': <String, dynamic>{'background': ember, 'text': ivory},
    'btn_secondary': <String, dynamic>{'background': walnut, 'text': ivory},
    'btn_success': <String, dynamic>{'background': const Color(0xFF466354), 'text': ivory},
    'btn_warning': <String, dynamic>{'background': const Color(0xFF825E28), 'text': ivory},
    'btn_error': <String, dynamic>{'background': const Color(0xFFA63F36), 'text': ivory},
  };

  @override
  Map<String, dynamic> get lightColors => {
    'text': charcoal,
    'background': ivory,
    'info': const Color(0xFF535F63),
    'topHeader': <String, dynamic>{'background': Colors.transparent, 'text': charcoal},
    'btn_info': <String, dynamic>{'background': const Color(0xFFDCE0DD), 'text': charcoal},
    'btn_logo': <String, dynamic>{'background': ember, 'text': ivory},
  };

  @override
  Map<String, dynamic> get darkColors => {
    'text': ivory,
    'background': charcoal,
    'info': stone,
    'topHeader': <String, dynamic>{'background': Colors.transparent, 'text': ivory},
    'btn_logo': <String, dynamic>{'background': ember, 'text': ivory},
    'btn_info': <String, dynamic>{'background': graphite, 'text': ivory},
  };

  @override
  double get maxWidth => 1200.0;

  @override
  Map<String, Style> get pageStyles => {
    "p": Style(textAlign: TextAlign.justify),
    "li": Style(textAlign: TextAlign.justify),
    "div": Style(textAlign: TextAlign.justify),
  };

  static ThemeData buildThemeData(bool isDark) {
    final appTheme = MainThemeData();
    final colors = isDark ? appTheme.darkColors : appTheme.lightColors;
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: appTheme.colors['primary'],
      scaffoldBackgroundColor: colors['background'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: appTheme.colors['primary'],
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: isDark ? warmAccent : ember,
        onPrimary: isDark ? charcoal : ivory,
        primaryContainer: isDark ? const Color(0xFF51372B) : const Color(0xFFF2D7C7),
        onPrimaryContainer: isDark ? ivory : charcoal,
        secondary: isDark ? const Color(0xFFC4A394) : walnut,
        onSecondary: isDark ? charcoal : ivory,
        surface: isDark ? charcoal : ivory,
        onSurface: isDark ? ivory : charcoal,
        onSurfaceVariant: isDark ? stone : const Color(0xFF535F63),
        surfaceContainerLow: isDark ? const Color(0xFF192125) : const Color(0xFFE8E9E4),
        surfaceContainer: isDark ? graphite : const Color(0xFFE0E3DF),
        surfaceContainerHigh: isDark ? const Color(0xFF303A3E) : const Color(0xFFD7DCD8),
        surfaceContainerHighest: isDark ? const Color(0xFF3B464A) : const Color(0xFFCCD2CE),
        outline: isDark ? const Color(0xFF7B888B) : const Color(0xFF6C797C),
        outlineVariant: isDark ? const Color(0xFF384448) : const Color(0xFFCBD1CE),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colors['text']),
      ),
    );
  }
}
