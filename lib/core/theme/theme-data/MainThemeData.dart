import 'package:flutter/material.dart';
import '../AppTheme.dart';
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
      'fontSize': 15.0,
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

  @override
  Map<String, dynamic> get colors => {
    // layout
    'header': <String, dynamic>{'background': Colors.transparent},
    'footer': <String, dynamic>{
      'background': Colors.transparent,
      'text': Colors.white,
    },

    // main
    'primary': const Color(0xff3d1e82),
    'secondary': const Color(0xff446155),
    'success': const Color(0xFF1F3284),
    'error': const Color(0xFF8F3000),
    'warning': const Color(0xFFA2762A),
    'info': const Color(0xFF141515),

    // buttons
    'btn_primary': <String, dynamic>{'background': const Color(0xff3d1e82), 'text': Colors.white},
    'btn_secondary': <String, dynamic>{'background': const Color(0xff446155), 'text': Colors.white},
    'btn_success': <String, dynamic>{'background': const Color(0xFF1F3284), 'text': Colors.white},
    'btn_warning': <String, dynamic>{'background': const Color(0xFFA2762A), 'text': Colors.white},
    'btn_error': <String, dynamic>{'background': const Color(0xFF8F3000), 'text': Colors.white},
  };

  @override
  Map<String, dynamic> get lightColors => {
    'text': Colors.black,
    'background': Colors.white,
    'info': const Color(0xFF5b5b5b),
    'topHeader': <String, dynamic>{'background': Colors.transparent, 'text': Colors.white},
    'btn_info': <String, dynamic>{'background': const Color(0xFF4E4E4E), 'text': Colors.white},
    'btn_logo': <String, dynamic>{'background': const Color(0xFF6532C2), 'text': Colors.white},
  };

  @override
  Map<String, dynamic> get darkColors => {
    'text': Colors.white,
    'background': const Color(0xFF212121),
    'info': Colors.white,
    'topHeader': <String, dynamic>{'background': Colors.transparent, 'text': Colors.black},
    'btn_logo': <String, dynamic>{'background': const Color(0xFF321665), 'text': Colors.white},
    'btn_info': <String, dynamic>{'background': const Color(0x45877F7F), 'text': Colors.white},
  };

  @override
  double get maxWidth => 1000.0;

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
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colors['text']),
      ),
    );
  }
}
