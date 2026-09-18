import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'web_setup_stub.dart'
    if (dart.library.html) 'web_setup.dart'
    as web_setup;
import 'package:free_open_ocean/core/router/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart' as theme_interface;
import 'core/theme/theme-data/main_theme_data.dart';
import 'services/app.dart';
import 'services/api.dart';
import 'package:free_open_ocean/core/provider/app_provider.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    web_setup.setupWeb();
  }
  final settingsService = App();
  final appTheme = await settingsService.getTheme();
  final themeModeOption = await settingsService.getThemeMode();
  final locale = await settingsService.getLocale();
  final deviceTypeOverride = await settingsService.getDevice();
  final country = await settingsService.getCountry();
  final connectionMode = await settingsService.getConnectionMode();

  runApp(
    MyApp(
      settingsService: settingsService,
      initialAppTheme: appTheme,
      initialThemeModeOption: themeModeOption,
      initialLocale: locale,
      initialDeviceTypeOverride: deviceTypeOverride,
      initialCountry: country,
      initialConnectionMode: connectionMode,
    ),
  );
}

class MyApp extends StatefulWidget {
  final App settingsService;
  final theme_interface.AppThemeEnum initialAppTheme;
  final theme_interface.ThemeModeOptionEnum initialThemeModeOption;
  final Locale initialLocale;
  final theme_interface.DeviceTypeOverride initialDeviceTypeOverride;
  final String initialCountry;
  final ConnectionMode initialConnectionMode;

  const MyApp({
    super.key,
    required this.settingsService,
    required this.initialAppTheme,
    required this.initialThemeModeOption,
    required this.initialLocale,
    required this.initialDeviceTypeOverride,
    required this.initialCountry,
    required this.initialConnectionMode,
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
  late ConnectionMode _connectionMode = ConnectionMode.normal;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _appTheme = widget.initialAppTheme;
    _themeModeOption = widget.initialThemeModeOption;
    _locale = widget.initialLocale;
    _deviceTypeOverride = widget.initialDeviceTypeOverride;
    _country = widget.initialCountry;
    _connectionMode = widget.initialConnectionMode;
    _api = Api(app: widget.settingsService);
    _appRouter = AppRouter(
      initialCountry: _country,
      initialLocale: _locale,
      onRegionChanged: _syncRegionFromRoute,
    );
    _waitForReady();
  }

  Future<void> _waitForReady() async {
    try {
      await _api.refresh();
    } catch (_) {}
    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  void _changeAppTheme(theme_interface.AppThemeEnum? theme) {
    if (theme == null) return;
    setState(() {
      _appTheme = theme;
    });
    widget.settingsService.setTheme(theme);
  }

  void _changeThemeModeOption(theme_interface.ThemeModeOptionEnum? mode) {
    if (mode == null) return;
    setState(() {
      _themeModeOption = mode;
    });
    widget.settingsService.setThemeMode(mode);
  }

  void _syncRegionFromRoute(String country, Locale locale) {
    if (!mounted) return;
    setState(() {
      _country = country;
      _locale = locale;
    });
    widget.settingsService.setCountry(country);
    widget.settingsService.setLocale(locale);
  }

  void _rewriteRegion({String? country, String? language}) {
    final router = _appRouter.router;
    final uri = router.routerDelegate.currentConfiguration.uri;
    router.go(
      AppRouter.withRegion(
        uri,
        country: country,
        language: language,
      ).toString(),
    );
  }

  void _changeLanguage(Locale? locale, bool fromDropdown) {
    if (locale == null) return;
    setState(() => _locale = locale);
    widget.settingsService.setLocale(locale);
    if (fromDropdown) _rewriteRegion(language: locale.languageCode);
  }

  void _changeDeviceTypeOverride(
    theme_interface.DeviceTypeOverride? deviceTypeOverride,
  ) {
    if (deviceTypeOverride == null) return;
    setState(() {
      _deviceTypeOverride = deviceTypeOverride;
    });
    widget.settingsService.setDevice(deviceTypeOverride);
  }

  void _changeCountry(String? country) {
    if (country == null) return;
    setState(() => _country = country);
    widget.settingsService.setCountry(country);
    _rewriteRegion(country: country);
  }

  @override
  void dispose() {
    _api.dispose();
    _appRouter.dispose();
    super.dispose();
  }

  void _changeConnectionMode(ConnectionMode? mode) {
    if (mode == null) return;
    setState(() {
      _connectionMode = mode;
    });
    widget.settingsService.setConnectionMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData lightTheme;
    ThemeData darkTheme;
    theme_interface.AppTheme currentTheme;

    switch (_appTheme) {
      case theme_interface.AppThemeEnum.mainTheme:
        lightTheme = MainThemeData.buildThemeData(false);
        darkTheme = MainThemeData.buildThemeData(true);
        currentTheme = MainThemeData();
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
      localeResolutionCallback: AppLocalizations.resolveLocale,
      routerConfig: _appRouter.router,
      builder: (context, child) {
        return AppProvider(
          app: widget.settingsService,
          api: _api,
          child: AppThemeProvider(
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
            connectionMode: _connectionMode,
            onConnectionModeChanged: _changeConnectionMode,
            api: _api,
            child: _isReady ? child! : const SplashScreen(),
          ),
        );
      },
    );
  }
}
