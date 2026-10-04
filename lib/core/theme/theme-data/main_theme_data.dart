import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../marine_palette.dart';
import 'package:flutter_html/flutter_html.dart';

class MainThemeData extends AppTheme {

  @override
  Map<String, dynamic> get defaultSizes => {
    // page layout
    'pageLayout': <String, dynamic>{
      'topHeader': false,
      'footer': true,
      'contentVerticalPadding': 30.0,
      'contentHorizontalPadding': 30.0,
    },
    'topHeader': <String, dynamic>{
      'padding': const EdgeInsets.all(2),
    },
    'header': <String, dynamic>{
      'padding': const EdgeInsets.symmetric(horizontal: 20)
    },
    'footer': <String, dynamic>{
      'height': 40.0,
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
    'pageLayout': <String, dynamic>{
      'contentVerticalPadding': 10.0,
      'contentHorizontalPadding': 10.0,
    },
    // 'topHeader': <String, dynamic>{'height': 25.0},
    // 'header': <String, dynamic>{'height': 40.0},
    // 'btn_s': <String, dynamic>{'fontSize': 12.0, 'iconSize': 14.0},
    // 'btn_m': <String, dynamic>{'fontSize': 14.0, 'iconSize': 16.0},
    // 'btn_l': <String, dynamic>{'fontSize': 16.0, 'iconSize': 18.0},
    // 'btn_xl': <String, dynamic>{'fontSize': 18.0, 'iconSize': 20.0},
  };

  @override
  Map<String, dynamic> get tabletSizes => {
    'pageLayout': <String, dynamic>{
      'contentVerticalPadding': 20.0,
      'contentHorizontalPadding': 20.0,
    },
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

  static const _day = MarinePalette.day;
  static const _night = MarinePalette.night;

  @override
  Map<String, dynamic> get colors => {
    'header': <String, dynamic>{'background': Colors.transparent},
    'footer': <String, dynamic>{'background': Colors.transparent},
  };

  @override
  Map<String, dynamic> get lightColors => _modeColors(_day);

  @override
  Map<String, dynamic> get darkColors => _modeColors(_night);

  static Map<String, dynamic> _modeColors(MarinePalette palette) {
    final chrome = palette.chrome;
    return <String, dynamic>{
      'text': chrome.ink,
      'background': chrome.surface,
      'primary': chrome.primary,
      'secondary': chrome.secondary,
      'success': chrome.positive,
      'error': chrome.danger,
      'warning': chrome.caution,
      'info': chrome.inkMuted,
      'footer': <String, dynamic>{'text': chrome.inkMuted},
      'topHeader': <String, dynamic>{
        'background': Colors.transparent,
        'text': chrome.ink,
      },
      'btn_primary': <String, dynamic>{
        'background': chrome.primary,
        'text': chrome.onPrimary,
      },
      'btn_secondary': <String, dynamic>{
        'background': chrome.secondary,
        'text': chrome.onSecondary,
      },
      'btn_success': <String, dynamic>{
        'background': chrome.positive,
        'text': chrome.onPrimary,
      },
      'btn_warning': <String, dynamic>{
        'background': chrome.caution,
        'text': chrome.onPrimary,
      },
      'btn_error': <String, dynamic>{
        'background': chrome.danger,
        'text': chrome.onPrimary,
      },
      'btn_info': <String, dynamic>{
        'background': chrome.surfaceSunken,
        'text': chrome.ink,
      },
      'btn_logo': <String, dynamic>{
        'background': chrome.primary,
        'text': chrome.onPrimary,
      },
    };
  }

  @override
  double get maxWidth => 1200.0;

  @override
  Map<String, Style> get pageStyles => {
    "p": Style(textAlign: TextAlign.justify),
    "li": Style(textAlign: TextAlign.justify),
    "div": Style(textAlign: TextAlign.justify),
  };

  static ThemeData buildThemeData(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final palette = MarinePalette.of(brightness);
    final chrome = palette.chrome;
    // Each container step is the surface lifted towards the ink, so the dark
    // ladder stays inside the night luminance budget instead of climbing
    // towards grey the way a seeded scheme would.
    Color layer(double amount) =>
        Color.lerp(chrome.surface, chrome.ink, amount)!;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: chrome.primary,
          brightness: brightness,
        ).copyWith(
          primary: chrome.primary,
          onPrimary: chrome.onPrimary,
          primaryContainer: Color.lerp(chrome.surface, chrome.primary, 0.22)!,
          onPrimaryContainer: chrome.ink,
          secondary: chrome.secondary,
          onSecondary: chrome.onSecondary,
          secondaryContainer: Color.lerp(
            chrome.surface,
            chrome.secondary,
            0.22,
          )!,
          onSecondaryContainer: chrome.ink,
          tertiary: chrome.beacon,
          onTertiary: chrome.onPrimary,
          error: chrome.danger,
          onError: chrome.onPrimary,
          surface: chrome.surface,
          onSurface: chrome.ink,
          onSurfaceVariant: chrome.inkMuted,
          surfaceContainerLowest: chrome.surfaceSunken,
          surfaceContainerLow: layer(0.04),
          surfaceContainer: layer(0.08),
          surfaceContainerHigh: layer(0.13),
          surfaceContainerHighest: layer(0.18),
          outline: chrome.outline,
          outlineVariant: chrome.outlineFaint,
        );

    return ThemeData(
      brightness: brightness,
      primaryColor: chrome.primary,
      scaffoldBackgroundColor: chrome.surface,
      colorScheme: colorScheme,
      dividerTheme: DividerThemeData(
        color: chrome.outlineFaint,
        thickness: 1,
        space: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: chrome.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: chrome.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: chrome.outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: chrome.inkMuted,
        textColor: chrome.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      iconTheme: IconThemeData(color: chrome.inkMuted),
      textSelectionTheme: TextSelectionThemeData(cursorColor: chrome.primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: chrome.surfaceSunken,
        hintStyle: TextStyle(color: chrome.inkFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: chrome.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: chrome.outlineFaint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: chrome.primary, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: chrome.ink,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(color: chrome.ink),
        bodyMedium: TextStyle(color: chrome.ink),
        labelSmall: TextStyle(color: chrome.inkMuted),
      ),
    );
  }
}
