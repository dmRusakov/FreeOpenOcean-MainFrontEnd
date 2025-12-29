import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:free_open_ocean/core/theme/AppTheme.dart';
import 'package:free_open_ocean/pages/about_page.dart';
import 'package:free_open_ocean/pages/main_page.dart';
import 'package:free_open_ocean/pages/map_page.dart';
import 'package:free_open_ocean/pages/settings_page.dart';
import 'package:free_open_ocean/pages/user_page.dart';

class AppRouter {
  final void Function(Locale, bool) onLocaleChanged;

  AppRouter({required this.onLocaleChanged});

  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    initialLocation: '/USA/en',
    routes: [
      _buildRoute('/:country/:language', (params) => MainPage(params: params)),
      _buildRoute('/:country/:language/user', (params) => UserPage(params: params)),
      _buildRoute('/:country/:language/settings', (params) => SettingsPage(params: params)),
      _buildRoute('/:country/:language/ocean_map', (params) => MapPage(params: params)),
      _buildRoute('/:country/:language/about', (params) => AboutPage(params: params)),
    ],
    redirect: (context, state) {
      final pathLanguage = state.pathParameters['language'];
      final appLanguage = Localizations.localeOf(context).languageCode;

      if (pathLanguage != appLanguage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onLocaleChanged(Locale(pathLanguage ?? 'en', ''), false);
        });
      }
      return null;
    },
  );

  static void goTo(BuildContext context, String route, {Map<String, String> params = const {}}) {
    final language = Localizations.localeOf(context).languageCode;
    final country = context.getCountry();
    final fullRoute = '/$country/$language/${route.isEmpty ? '' : route}';
    final uri = Uri(path: fullRoute, queryParameters: params.isNotEmpty ? params : null);
    GoRouter.of(context).go(uri.toString());
  }

  static GoRoute _buildRoute(String path, Widget Function(Map<String, String>) builder) {
    return GoRoute(
      path: path,
      builder: (context, state) {
        final params = {...state.uri.queryParameters, 'languageCode': state.pathParameters['language']!, 'countryCode': state.pathParameters['country']!};
        return builder(params);
      },
    );
  }
}
