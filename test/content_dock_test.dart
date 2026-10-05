import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/core/theme/app_theme.dart';
import 'package:free_open_ocean/core/theme/theme-data/main_theme_data.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/services/app.dart';
import 'package:free_open_ocean/widgets/footer.dart';
import 'package:free_open_ocean/widgets/header.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late App app;
  late Api api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'FreeOpenOcean',
      packageName: 'free_open_ocean',
      version: '0.0.0',
      buildNumber: '0',
      buildSignature: '',
    );
    app = App();
    api = Api(app: app, endpoints: const [], autoStart: false, useHttp: true);
    contentDockedRight.value = false;
    setTopBar(title: 'Settings', ownerId: 'settings', submenu: const []);
  });

  tearDown(() {
    contentDockedRight.value = false;
    clearTopBar(ownerId: 'settings');
    api.dispose();
    app.dispose();
  });

  testWidgets('wide screens offer a button that parks the page on the right', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_harness(api));
    await tester.pump();

    expect(find.byTooltip('Show the map'), findsOneWidget);
    expect(contentDockedRight.value, isFalse);

    await tester.tap(find.byTooltip('Show the map'));
    await tester.pump();

    expect(contentDockedRight.value, isTrue);
    expect(find.byTooltip('Center the page'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('section buttons sit at the right of the title', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    setTopBar(
      title: 'Settings',
      ownerId: 'settings',
      submenu: const [Text('General'), Text('Map'), Text('Style Guide')],
    );
    await tester.pumpWidget(_harness(api));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final title = tester.getRect(find.text('Settings'));
    final guide = tester.getRect(find.text('Style Guide'));
    final bar = tester.getRect(find.byType(AppBar));
    expect(guide.left, greaterThan(title.right));
    expect(bar.right - guide.right, lessThan(80));
  });

  testWidgets('phones do not show the map button', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_harness(api));
    await tester.pump();

    expect(find.byTooltip('Show the map'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
  });
}

Widget _harness(Api api) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AppThemeProvider(
      theme: MainThemeData(),
      deviceTypeOverride: DeviceTypeOverride.auto,
      onDeviceTypeOverrideChanged: (_) {},
      appTheme: AppThemeEnum.mainTheme,
      onAppThemeChanged: (_) {},
      themeMode: ThemeModeOptionEnum.dark,
      onThemeModeChanged: (_) {},
      locale: const Locale('en'),
      onLocaleChanged: (_, _) {},
      country: 'USA',
      onCountryChanged: (_) {},
      connectionMode: api.app.connectionMode,
      onConnectionModeChanged: (_) {},
      api: api,
      child: const Scaffold(
        appBar: MyAppBar(),
        body: Align(alignment: Alignment.bottomCenter, child: Footer()),
      ),
    ),
  );
}
