import 'package:flutter/material.dart';
import '../AppTheme.dart';
import 'package:flutter_html/flutter_html.dart';

class MinimalisticThemeData extends AppTheme {
  @override
  Map<String, dynamic> get defaultSizes => {
        'topHeader': <String, dynamic>{
          'padding': const EdgeInsets.all(2),
        },
        'button_small': <String, dynamic>{
          'padding': 10.0,
        },
      };

  // Mobile sizes
  @override
  Map<String, dynamic> get mobileSizes => {
        'topHeader': <String, dynamic>{
          'height': 25.0,
        },
        'button_small': <String, dynamic>{
          'font_size': 12.0,
        },
      };

  // Tablet sizes
  @override
  Map<String, dynamic> get tabletSizes => {
        'topHeader': <String, dynamic>{
          'height': 30.0,
        },
        'button_small': <String, dynamic>{
          'font_size': 14.0,
        },
      };

  // Desktop sizes
  @override
  Map<String, dynamic> get desktopSizes => {
        'topHeader': <String, dynamic>{
          'height': 35.0,
        },
        'button_small': <String, dynamic>{
          'font_size': 16.0,
        },
      };

  // TV sizes
  @override
  Map<String, dynamic> get tvSizes => {
        'topHeader': <String, dynamic>{
          'height': 40.0,
        },
        'button_small': <String, dynamic>{
          'font_size': 18.0,
        },
      };

  // default color
  @override
  Map<String, dynamic> get colors => {
        'primary': Colors.blueGrey,
        'secondary': Colors.blueGrey,
        'error': Colors.redAccent,
        'success': Colors.greenAccent,
        'warning': Colors.yellowAccent,
      };

  // light color
  @override
  Map<String, dynamic> get lightColors => {
        'text': Colors.black,
        'background': Colors.white,
        'secondary': const Color(0xFFE0E0E0),
        'topHeader': <String, dynamic>{
          'background': const Color(0xFFEAEAEA),
          'text': Colors.white,
        },
      };

  // dark color
  @override
  Map<String, dynamic> get darkColors => {
        'text': Colors.white,
        'background': const Color(0xFF212121),
        'secondary': Colors.black,
        'topHeader': <String, dynamic>{
          'background': const Color(0xFF424242),
          'text': Colors.white,
        },
      };

  @override
  double get maxWidth => 1000.0;

  @override
  Map<String, Style> get pageStyles => {
    "p": Style(textAlign: TextAlign.justify),
    "li": Style(textAlign: TextAlign.justify),
    "div": Style(textAlign: TextAlign.justify),
  };

  // Helper method to build ThemeData based on mode
  static ThemeData buildThemeData(bool isDark) {
    final appTheme = MinimalisticThemeData();
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
