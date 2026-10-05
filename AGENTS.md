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
- Detail map tiles (Land, Graticule, Sea, Marine objects, and any new tile in `_detailTiles`) use one standard row: 18-character Name, Zoom, Line type, Line width, Fill (Light/Dark), Line (Light/Dark). Empty slots stay reserved when a row has no fill or no stroke controls. Column titles sit under the tile header. Sun and Moon parameters live on Graticule with the grid and equator; there is no separate Sky tile. Sea is one section (not Rivers / Depth / Ferries subsections): waterways, depth, ferries, and bridges are absorbed into the Sea tile. Marine objects is one section (not Marinas / Harbour places / Seamarks subsections): places, docks, slipways, seamarks, platforms, and lighthouses are absorbed into that tile. Marine objects replaces Line type / Line width with an Icon picker (Flutter Material icons in a square border with a small radius) and replaces Fill / Line colour headers with Icon / Border; the chosen icon is drawn on the chart with those colours. Marine object icon rows use one 3-point zoom (small icon, full icon + name, end) instead of separate icon / name / full-size rows. Labels (`waterNames`) holds Water names, Country names (`places_country`), Region names (`places_region`), City names (`places_locality`), Object names, Island names (custom overlay), Basemap island names (`earth_label_islands`), and Name outline — not under Marine objects. City names are only partly tied to Local streets: when Local streets are off, only higher-rank cities stay. Basemap island names are separate from the Islands fill and Island names overlay controls. Land keeps Coastline and Boundaries with the other land lines (roads, contours, hillshade).
- On the chart but not in Settings: dam fills and pier lines follow Coastline (colour and switch) with no own row; chart backdrop colour is palette-only; leftover tile POIs (beacon, mooring, lock, life ring, ferry/cruise terminal, and similar) follow the Harbour places switch only, with no own Settings row.
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

- Each marine object family uses one 3-point zoom (2 zones) in Settings → Map: small-icon start, full-icon+name start, and end. In the first zone every marine object uses the same icon size (70% of the default full size); from the middle stop each kind uses its own full size (0.8³ × 1.2 of the prior full) and the name appears with it at ~9.9 px, shifted 5 px right of the icon (`objectZoomStops`, `_objectIconSize`). Defaults: marinas and anchorages 11 / 13 / 22; port, fuel, customs, services, dock, and seamarks 12 / 14 / 22; slipways 14 / 15 / 22; platforms and lighthouses 6 / 12 / 22.
- The name is the first line. The object type is the second line, at 0.75 of the name size (`objectTypeFontScale`, `_objectLabel`). A platform reads `DEVILS TOWER` / `Offshore oil platforms`.
- If the object has no name, only the type line is shown.
- Both lines are left-aligned (`text-anchor: left`, `text-justify: left`).
- The name and the type appear together at the full-icon stop. An icon may show earlier at the shared small size.
- A slipway uses the same 3-point rule (defaults 14 / 15 / 22). Chart tiles omit slipways until zoom 16, so the icon is loaded from OpenStreetMap for the view on screen.
- An offshore platform uses the 3-point zoom above. A 500 m protection circle, in the same dark orange as the icon, is on past zoom 12 (hardcoded, not a settings row). Platforms are not in the chart tiles, so the icon is loaded from OpenStreetMap for the view on screen.
- A lighthouse uses the same 3-point rule. The light description (character, colour, period, range, height, and sectors) appears with the name at the full stop. Lighthouses are loaded from OpenStreetMap for the view on screen.
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
