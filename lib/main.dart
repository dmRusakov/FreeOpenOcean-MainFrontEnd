import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'web_setup_stub.dart' if (dart.library.html) 'web_setup.dart' as web_setup;
import 'package:free_open_ocean/core/router/app_router.dart';
import 'core/localization/AppLocalizations.dart';
import 'core/theme/AppTheme.dart' as theme_interface;
import 'core/theme/theme-data/MainThemeData.dart';
import 'core/theme/theme-data/MinimalisticThemeData.dart';
import 'services/settings_service.dart';
import 'services/api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) web_setup.setupWeb();
  final settingsService = SettingsService();
  final appTheme = await settingsService.loadAppTheme();
  final themeModeOption = await settingsService.loadThemeModeOption();
  final locale = await settingsService.loadLocale();
  final deviceTypeOverride = await settingsService.loadDeviceTypeOverride();
  final country = await settingsService.loadCountry();

  runApp(MyApp(
    settingsService: settingsService,
    initialAppTheme: appTheme,
    initialThemeModeOption: themeModeOption,
    initialLocale: locale,
    initialDeviceTypeOverride: deviceTypeOverride,
    initialCountry: country,
  ));
}

class MyApp extends StatefulWidget {
  final SettingsService settingsService;
  final theme_interface.AppThemeEnum initialAppTheme;
  final theme_interface.ThemeModeOptionEnum initialThemeModeOption;
  final Locale initialLocale;
  final theme_interface.DeviceTypeOverride initialDeviceTypeOverride;
  final String initialCountry;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.initialAppTheme,
    required this.initialThemeModeOption,
    required this.initialLocale,
    required this.initialDeviceTypeOverride,
    required this.initialCountry,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late theme_interface.AppThemeEnum _appTheme;
  late theme_interface.ThemeModeOptionEnum _themeModeOption;
  late Locale _locale;
  late theme_interface.DeviceTypeOverride _deviceTypeOverride;
  late String _country;
  late AppRouter _appRouter;
  late Api _api;
  bool _isChangingFromDropdown = false;

  @override
  void initState() {
    super.initState();
    _appTheme = widget.initialAppTheme;
    _themeModeOption = widget.initialThemeModeOption;
    _locale = widget.initialLocale;
    _deviceTypeOverride = widget.initialDeviceTypeOverride;
    _country = widget.initialCountry;
    _api = Api(settingsService: widget.settingsService);
    _appRouter = AppRouter(onLocaleChanged: _changeLanguage);
  }

  void _changeAppTheme(theme_interface.AppThemeEnum? theme) {
    if (theme == null) return;
    setState(() {
      _appTheme = theme;
    });
    widget.settingsService.saveAppTheme(theme);
  }

  void _changeThemeModeOption(theme_interface.ThemeModeOptionEnum? mode) {
    if (mode == null) return;
    setState(() {
      _themeModeOption = mode;
    });
    widget.settingsService.saveThemeModeOption(mode);
  }

  void _changeLanguage(Locale? locale, bool fromDropdown) {
    if (locale == null) return;
    setState(() {
      _locale = locale;
    });
    widget.settingsService.saveLocale(locale);
    if (fromDropdown) {
      _isChangingFromDropdown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentPath = _appRouter.router.routerDelegate.currentConfiguration.uri.path;
        final pathParts = currentPath.split('/');
        if (pathParts.length > 2) {
          pathParts[2] = locale.languageCode;
          final newPath = pathParts.join('/');
          _appRouter.router.go(newPath);
        }
        _isChangingFromDropdown = false;
      });
    }
  }

  void _changeDeviceTypeOverride(
      theme_interface.DeviceTypeOverride? deviceTypeOverride) {
    if (deviceTypeOverride == null) return;
    setState(() {
      _deviceTypeOverride = deviceTypeOverride;
    });
    widget.settingsService.saveDeviceTypeOverride(deviceTypeOverride);
  }

  void _changeCountry(String? country) {
    if (country == null) return;
    setState(() {
      _country = country;
    });
    widget.settingsService.saveCountry(country);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentPath = _appRouter.router.routerDelegate.currentConfiguration.uri.path;
      final pathParts = currentPath.split('/');
      if (pathParts.length >= 3) {
        pathParts[1] = country;
        final newPath = pathParts.join('/');
        _appRouter.router.go(newPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData lightTheme;
    ThemeData darkTheme;
    theme_interface.AppTheme currentTheme;

    switch (_appTheme) {
      case theme_interface.AppThemeEnum.main_theme:
        lightTheme = MainThemeData.buildThemeData(false);
        darkTheme = MainThemeData.buildThemeData(true);
        currentTheme = MainThemeData();
        break;
      default:
        lightTheme = MinimalisticThemeData.buildThemeData(false);
        darkTheme = MinimalisticThemeData.buildThemeData(true);
        currentTheme = MinimalisticThemeData();
        break;
    }

    ThemeMode themeMode;
    switch (_themeModeOption) {
      case theme_interface.ThemeModeOptionEnum.light:
        themeMode = ThemeMode.light;
        break;
      case theme_interface.ThemeModeOptionEnum.dark:
        themeMode = ThemeMode.dark;
        break;
      case theme_interface.ThemeModeOptionEnum.auto:
      default:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'FreeOpenOcean - Ocean Navigation and Weather Applications',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('pt', ''),
        Locale('ru', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      routerConfig: _appRouter.router,
      builder: (context, child) {
        return theme_interface.AppThemeProvider(
          theme: currentTheme,
          deviceTypeOverride: _deviceTypeOverride,
          onDeviceTypeOverrideChanged: _changeDeviceTypeOverride,
          appTheme: _appTheme,
          onAppThemeChanged: _changeAppTheme,
          themeMode: _themeModeOption,
          onThemeModeChanged: _changeThemeModeOption,
          locale: _locale,
          onLocaleChanged: _changeLanguage,
          country: _country,
          onCountryChanged: _changeCountry,
          api: _api,
          child: child!,
        );
      },
    );
  }
}
