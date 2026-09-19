import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:free_open_ocean/services/api.dart';
import 'package:free_open_ocean/services/app.dart';
import 'package:free_open_ocean/models/endpoint.dart';
import 'package:free_open_ocean/core/provider/app_theme_provider.dart';
import 'package:free_open_ocean/core/theme/app_theme.dart';
import 'package:free_open_ocean/core/theme/theme-data/main_theme_data.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/pages/page_content.dart';
// The contracts package only exposes generated files.
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pb.dart' as pages;
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart'
    as status;

Widget harness(Api api, {String country = 'USA', String language = 'en'}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('fr')],
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
        themeMode: ThemeModeOptionEnum.light,
        onThemeModeChanged: (_) {},
        locale: Locale(language),
        onLocaleChanged: (_, _) {},
        country: country,
        onCountryChanged: (_) {},
        connectionMode: api.app.connectionMode,
        onConnectionModeChanged: (_) {},
        api: api,
        child: const Scaffold(body: PageContent(slug: 'style-guide')),
      ),
    );
void main() {
  late App app;
  late Endpoint ep;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = App();
    ep = Endpoint(
      id: 'test',
      grpcHost: 'localhost',
      grpcPort: 1,
      httpHost: 'http://localhost',
      httpPort: 1,
      country: 'USA',
    );
    await app.setEndpoint(ep);
  });
  tearDown(() => app.dispose());
  testWidgets('failed page shows retry and retry recovers', (tester) async {
    var successful = false;
    final api = Api(
      app: app,
      endpoints: [ep],
      useHttp: true,
      autoStart: false,
      clientFactory: () => MockClient((request) async {
        if (request.url.path == Api.statusGetPath) {
          return http.Response.bytes(
            status.GetResponse(id: 'test', key: 'key').writeToBuffer(),
            200,
          );
        }
        return successful
            ? http.Response.bytes(
                pages.Page(
                  title: 'Recovered',
                  content: '<p>Content</p>',
                ).writeToBuffer(),
                200,
              )
            : http.Response('', 503);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(harness(api));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    successful = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    api.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('country and language changes reload content', (tester) async {
    final requested = <String>[];
    final api = Api(
      app: app,
      endpoints: [],
      useHttp: true,
      autoStart: false,
      clientFactory: () => MockClient((request) async {
        final page = pages.GetRequest.fromBuffer(request.bodyBytes);
        final label = '${page.countryCode}/${page.languageCode}';
        requested.add(label);
        return http.Response.bytes(
          pages.Page(title: label).writeToBuffer(),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(harness(api));
    await tester.pumpAndSettle();
    await tester.pumpWidget(harness(api, country: 'FRA', language: 'fr'));
    await tester.pumpAndSettle();
    expect(requested, ['usa/en', 'fra/fr']);
    expect(find.text('fra/fr'), findsOneWidget);
    expect(find.text('usa/en'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('stale page response cannot replace newly selected region', (
    tester,
  ) async {
    final oldResponse = Completer<http.Response>();
    final api = Api(
      app: app,
      endpoints: [],
      useHttp: true,
      autoStart: false,
      clientFactory: () => MockClient((request) async {
        final page = pages.GetRequest.fromBuffer(request.bodyBytes);
        if (page.countryCode == 'usa') return oldResponse.future;
        return http.Response.bytes(
          pages.Page(title: 'France').writeToBuffer(),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(harness(api));
    await tester.pump();
    await tester.pumpWidget(harness(api, country: 'FRA'));
    await tester.pumpAndSettle();
    oldResponse.complete(
      http.Response.bytes(
        pages.Page(title: 'Old content').writeToBuffer(),
        200,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('France'), findsOneWidget);
    expect(find.text('Old content'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'disabled mode displays explanation without requests or spinner',
    (tester) async {
      await app.setConnectionMode(ConnectionMode.disable);
      var requests = 0;
      final api = Api(
        app: app,
        endpoints: [],
        useHttp: true,
        autoStart: false,
        clientFactory: () => MockClient((_) async {
          requests++;
          return http.Response('', 500);
        }),
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(harness(api));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Backend connection is disabled'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
