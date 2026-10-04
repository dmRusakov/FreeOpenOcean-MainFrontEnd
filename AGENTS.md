# AGENTS.md

## Scope
- Flutter app (`free_open_ocean`) with web + mobile targets; primary runtime code is under `lib/`.
- Existing `README.md` is boilerplate, so rely on code-level patterns documented below.

## Big Picture Architecture
- App bootstraps in `lib/main.dart`: preload persisted settings from `App` (`lib/services/app.dart`), create `Api`, then gate UI with `SplashScreen` until an endpoint is ready (`_waitForReady`).
- Global state is provided through two inherited widgets:
  - `AppProvider` (`lib/core/provider/app_provider.dart`) for `App` + `Api` + connection helpers.
  - `AppThemeProvider` (`lib/core/provider/app_theme_provider.dart`) for theme/device/locale/country/connection mode and callbacks.
- Routing is centralized in `lib/core/router/app_router.dart` using `go_router`; canonical URL format is `/:country/:language/<page>` (example: `/USA/en/settings`).
- Header title/submenu is shared across pages through `topBarNotifier` in `lib/pages/page_template.dart`; pages set it in `didChangeDependencies` and clear it in `dispose`.

## Data and Service Boundaries
- `App` service persists user/session settings in `SharedPreferences` (theme, locale, country, endpoint id, connection mode, session id).
- Chart layers, zooms, and day/night colours are saved by `MapChartSettings` and edited on Settings → Map. The defaults below are what a fresh install uses. The chart reloads its style when those values change.
- Map settings always group related parameters near each other in the same tile and in the expanded list. Keep a zoom next to the colours and switches it controls (for example Local streets with Main roads, Minor roads, Road casing, and Road labels). Do not leave related road, land, water, or seamark controls scattered across the tile.
- `Api` service (`lib/services/api.dart`) owns endpoint discovery and health checks:
  - probes static endpoint list,
  - chooses fastest reachable endpoint,
  - updates `App.connectionStatus`,
  - re-checks every 15 minutes.
- Transport is platform-dependent:
  - non-web => gRPC via `grpc` package,
  - web => HTTP protobuf POST fallback.
- Page CMS/content is fetched by `PageService.get` (`lib/services/page_service.dart`) using slug + language + country and endpoint from `BuildContext.getEndpoint()`.

## Chart object labels
Point objects on the chart (marinas, anchorages, fuel, ferries, docks, seamarks, offshore platforms, and any new icon of that kind) share one label standard in `MapService`:

- The icon is half size until zoom 12, then full size (`objectIconFullZoom`, `_objectIconSize`). Zoom 12 and zoom 13 use the same full size.
- The name is the first line. The object type is the second line, at 0.75 of the name size (`objectTypeFontScale`, `_objectLabel`). A platform reads `DEVILS TOWER` / `Offshore oil platforms`.
- If the object has no name, only the type line is shown.
- Both lines are left-aligned (`text-anchor: left`, `text-justify: left`).
- The name and the type appear together. An icon may show earlier; the label waits for that object's name zoom.
- A slipway icon and its name are on past zoom 14. The icon is 90% of the marina icon and the same colour as the slipway name. The name stays 11 px. Chart tiles omit slipways until zoom 16, so the icon is loaded from OpenStreetMap for the view on screen.
- An offshore platform icon is on past zoom 6 and its name from zoom 12. A 500 m protection circle, in the same dark orange as the icon, is on past zoom 12. Platforms are not in the chart tiles, so the icon is loaded from OpenStreetMap for the view on screen.
- A lighthouse uses that same zoom rule: the icon is on past zoom 6, and the name plus the light description are on from zoom 12. The description is the character, colour, period, range, height, and sectors. Lighthouses are loaded from OpenStreetMap for the view on screen.
- Line labels (ferry tracks, bridges, water names, depth numbers, island groups) are not point objects and do not use this pattern.

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
- After every app update, reload or restart the running Flutter app so the latest code is compiled, then refresh the app in both Chrome and the ChatGPT/Codex in-app browser. Reuse the current development server and app tabs where possible, preserve the current route, and verify the updated UI in both browsers before reporting completion.
- FooApi (`/Users/dm/Apps/FOO/FooApi`) is documented in `/Users/dm/Apps/FOO/FooApi/AGENTS.md`. Follow that file for AppAPI, LogLoader, status, weather, Logpush, and Cloudflare. After every code change that affects `https://app-api.freeopenocean.com`, publish from FooApi with `npx wrangler deploy --config cloudflare/app-api/status-wrangler.toml` and confirm a protobuf POST to `/status.v1.Status/Get` returns HTTP 200. `DEV_MODE=true` allows `http://localhost` and `http://127.0.0.1` on ports 65500–65550; `freeopenocean.com` is always allowed. Do not deploy `cloudflare/app-api/wrangler.toml` for this host.
- If editing codegen/proto flow, check `build.yaml` + run your usual `build_runner` command for this repo setup.
