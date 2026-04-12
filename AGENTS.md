# AGENTS.md

## Scope
- Flutter app (`free_open_ocean`) with web + mobile targets; primary runtime code is under `lib/`.
- Existing `README.md` is boilerplate, so rely on code-level patterns documented below.

## Big Picture Architecture
- App bootstraps in `lib/main.dart`: preload persisted settings from `App` (`lib/services/app.dart`), create `Api`, then gate UI with `SplashScreen` until an endpoint is ready (`_waitForReady`).
- Global state is provided through two inherited widgets:
  - `AppProvider` (`lib/core/provider/AppProvider.dart`) for `App` + `Api` + connection helpers.
  - `AppThemeProvider` (`lib/core/provider/AppThemeProvider.dart`) for theme/device/locale/country/connection mode and callbacks.
- Routing is centralized in `lib/core/router/app_router.dart` using `go_router`; canonical URL format is `/:country/:language/<page>` (example: `/USA/en/settings`).
- Header title/submenu is shared across pages through `topBarNotifier` in `lib/pages/page_template.dart`; pages set it in `didChangeDependencies` and clear it in `dispose`.

## Data and Service Boundaries
- `App` service persists user/session settings in `SharedPreferences` (theme, locale, country, endpoint id, connection mode, session id).
- `Api` service (`lib/services/api.dart`) owns endpoint discovery and health checks:
  - probes static endpoint list,
  - chooses fastest reachable endpoint,
  - updates `App.connectionStatus`,
  - re-checks every 15 minutes.
- Transport is platform-dependent:
  - non-web => gRPC via `grpc` package,
  - web => HTTP protobuf POST fallback.
- Page CMS/content is fetched by `PageService.get` (`lib/services/page_service.dart`) using slug + language + country and endpoint from `BuildContext.getEndpoint()`.

## Project Conventions (Important)
- Keep country/language in URL synchronized with app state; locale/country changes rewrite the current route in `main.dart`.
- For navigations, use `AppRouter.goTo(...)` / `context.routerGoTo(...)` instead of hardcoded paths.
- For new pages using the common shell, wrap with `PageTemplate`, then call `setTopBar(... ownerId: ...)` and `clearTopBar(ownerId: ...)`.
- Theme/layout values are key-based (`context.getTheme('header')`, `context.getThemeSizes('pageLayout')`); avoid hardcoding sizes/colors when a theme key exists.
- Connection UI and mode controls should use helper builders from `AppProvider` / `AppThemeProvider` / `AppLocalizations` (search dialogs are a repeated pattern).

## Integrations and External Dependencies
- gRPC contracts come from git dependency `free_open_ocean_grpc` in `pubspec.yaml`.
- `build.yaml` config references `protoc_builder`; keep generated-proto workflow compatible with that builder setup.
- Web runtime adjusts URL behavior through `lib/web_setup.dart` (`usePathUrlStrategy`).
- Map screen (`lib/pages/ocean_charts.dart`) uses `maplibre_gl` + `geolocator`; style switches by brightness.

## Developer Workflows
- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests (if/when present): `flutter test`
- Run web locally: `flutter run -d chrome`
- If editing codegen/proto flow, check `build.yaml` + run your usual `build_runner` command for this repo setup.

