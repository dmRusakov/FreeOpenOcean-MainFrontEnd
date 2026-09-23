import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../localization/countries.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/pages/about_page.dart';
import 'package:free_open_ocean/pages/ocean_charts.dart';
import 'package:free_open_ocean/pages/settings_page.dart';
import 'package:free_open_ocean/pages/user_page.dart';

class AppRouter {
  final void Function(String, Locale) onRegionChanged;
  final String initialCountry;
  final Locale initialLocale;
  int _redirectVersion = 0;
  bool _disposed = false;
  late String _country = initialCountry;
  late String _language = initialLocale.languageCode;

  AppRouter({
    required this.onRegionChanged,
    this.initialCountry = 'USA',
    this.initialLocale = const Locale('en'),
  });

  GoRouter get router => _router;
  late final GoRouter _router = GoRouter(
    initialLocation: '/$initialCountry/${initialLocale.languageCode}',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            state.uri.replace(path: '/$_country/$_language').toString(),
      ),
      _buildRoute(
        '/:country/:language',
        (params) => OceanCharts(params: params),
      ),
      _buildRoute(
        '/:country/:language/user',
        (params) => UserPage(params: params),
      ),
      _buildRoute(
        '/:country/:language/settings',
        (params) => SettingsPage(params: params),
      ),
      _buildRoute(
        '/:country/:language/ocean_charts',
        (params) => OceanCharts(params: params),
      ),
      _buildRoute(
        '/:country/:language/about',
        (params) => AboutPage(params: params),
      ),
    ],
    redirect: (context, state) {
      if (state.uri.path.endsWith('/about') &&
          state.uri.queryParameters['section'] == 'typography') {
        return state.uri.replace(
          path: state.uri.path.replaceFirst(RegExp(r'/about$'), '/settings'),
          queryParameters: {...state.uri.queryParameters, 'section': 'style'},
        ).toString();
      }
      final rawCountry = state.pathParameters['country'];
      final rawLanguage = state.pathParameters['language'];
      if (rawCountry == null || rawLanguage == null) return null;
      final country = countries.containsKey(rawCountry.toUpperCase())
          ? rawCountry.toUpperCase()
          : 'USA';
      final language =
          ['en', 'es', 'fr', 'pt', 'ru'].contains(rawLanguage.toLowerCase())
          ? rawLanguage.toLowerCase()
          : 'en';
      if (country != rawCountry || language != rawLanguage) {
        return withRegion(
          state.uri,
          country: country,
          language: language,
        ).toString();
      }
      if (_country != country || _language != language) {
        _country = country;
        _language = language;
        final version = ++_redirectVersion;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed && version == _redirectVersion) {
            onRegionChanged(country, Locale(language));
          }
        });
      }
      return null;
    },
  );

  static Uri withRegion(Uri uri, {String? country, String? language}) {
    final parts = uri.path.split('/');
    if (parts.length < 3) return uri;
    if (country != null) parts[1] = country;
    if (language != null) parts[2] = language;
    return uri.replace(path: parts.join('/'));
  }

  static void goTo(
    BuildContext context,
    String route, {
    Map<String, String> params = const {},
  }) {
    final state = GoRouterState.of(context);
    final language =
        state.pathParameters['language'] ??
        Localizations.localeOf(context).languageCode;
    final country = state.pathParameters['country'] ?? context.getCountry();
    final fullRoute = '/$country/$language${route.isEmpty ? '' : '/$route'}';
    GoRouter.of(context).go(
      Uri(
        path: fullRoute,
        queryParameters: params.isNotEmpty ? params : null,
      ).toString(),
    );
  }

  static GoRoute _buildRoute(
    String path,
    Widget Function(Map<String, String>) builder,
  ) => GoRoute(
    path: path,
    builder: (context, state) => builder({
      ...state.uri.queryParameters,
      'languageCode': state.pathParameters['language']!,
      'countryCode': state.pathParameters['country']!,
    }),
  );

  void dispose() {
    _disposed = true;
    _router.dispose();
  }
}
