import 'package:flutter/material.dart';

import 'package:free_open_ocean/services/map_chart_settings.dart';

/// Colours for the chart and for the chrome that floats over it.
///
/// Two variants: [day] for daylight, [night] for use on a boat after dark.
///
/// The night variant is built to protect dark adaptation, so it follows three
/// rules that the day variant does not:
///
/// 1. Nothing that covers a large area goes above 7% relative luminance, and
///    no token reaches white. Contrast comes from darkening the background,
///    never from brightening the foreground.
/// 2. Anything that has to be bright enough to catch the eye - alerts, the
///    safety depth contour, the light sectors - is red or amber. Long
///    wavelengths leave the rods alone; blue and green bleach them.
/// 3. Label halos are darker than the label, so text reads as light on dark
///    instead of glowing.
@immutable
class MarinePalette {
  const MarinePalette._({
    required this.chrome,
    required this.chart,
    required this.depth,
    required this.objects,
    required this.sky,
    required this.weather,
  });

  final MarineChrome chrome;
  final MarineChart chart;
  final MarineDepth depth;
  final MarineObjects objects;
  final MarineSky sky;
  final MarineWeather weather;

  static MarinePalette of(Brightness brightness) {
    final nightMode = brightness == Brightness.dark;
    final base = nightMode ? night : day;
    final overrides = MapChartSettings.instance.colorOverrides;
    if (overrides.isEmpty) return base;
    return base._withOverrides(nightMode ? 'night' : 'day', overrides);
  }

  MarinePalette _withOverrides(String theme, Map<String, int> overrides) {
    Color pick(String group, String field, Color fallback) {
      final value = overrides['$theme.$group.$field'];
      return value == null ? fallback : Color(value);
    }

    final chart = this.chart;
    final depth = this.depth;
    final objects = this.objects;
    final sky = this.sky;
    return MarinePalette._(
      chrome: chrome,
      chart: MarineChart(
        backdrop: chart.backdrop,
        landBase: pick('chart', 'landBase', chart.landBase),
        landBeach: pick('chart', 'landBeach', chart.landBeach),
        seaBase: pick('chart', 'seaBase', chart.seaBase),
        seaEdge: pick('chart', 'seaEdge', chart.seaEdge),
        coastline: pick('chart', 'coastline', chart.coastline),
        islandFill: pick('chart', 'islandFill', chart.islandFill),
        islandEdge: pick('chart', 'islandEdge', chart.islandEdge),
        graticule: pick('chart', 'graticule', chart.graticule),
        meridian: pick('chart', 'meridian', chart.meridian),
        labelStrong: pick('chart', 'labelStrong', chart.labelStrong),
        labelSoft: pick('chart', 'labelSoft', chart.labelSoft),
        labelFaint: pick('chart', 'labelFaint', chart.labelFaint),
        labelHalo: pick('chart', 'labelHalo', chart.labelHalo),
        landContour: pick('chart', 'landContour', chart.landContour),
        landContourLabel: pick(
          'chart',
          'landContourLabel',
          chart.landContourLabel,
        ),
        roadTrunk: pick('chart', 'roadTrunk', chart.roadTrunk),
        roadMinor: pick('chart', 'roadMinor', chart.roadMinor),
        roadCasing: pick('chart', 'roadCasing', chart.roadCasing),
        roadLabel: pick('chart', 'roadLabel', chart.roadLabel),
        hillshadeShadow: pick(
          'chart',
          'hillshadeShadow',
          chart.hillshadeShadow,
        ),
        hillshadeHighlight: pick(
          'chart',
          'hillshadeHighlight',
          chart.hillshadeHighlight,
        ),
        hillshadeAccent: pick(
          'chart',
          'hillshadeAccent',
          chart.hillshadeAccent,
        ),
      ),
      depth: MarineDepth(
        danger: pick('depth', 'danger', depth.danger),
        caution: pick('depth', 'caution', depth.caution),
        coastal: pick('depth', 'coastal', depth.coastal),
        shelf: pick('depth', 'shelf', depth.shelf),
        deep: pick('depth', 'deep', depth.deep),
        label: pick('depth', 'label', depth.label),
      ),
      objects: MarineObjects(
        marina: pick('objects', 'marina', objects.marina),
        anchorage: pick('objects', 'anchorage', objects.anchorage),
        fuel: pick('objects', 'fuel', objects.fuel),
        customs: pick('objects', 'customs', objects.customs),
        port: pick('objects', 'port', objects.port),
        service: pick('objects', 'service', objects.service),
        slipway: pick('objects', 'slipway', objects.slipway),
        ferry: pick('objects', 'ferry', objects.ferry),
        ferryRoute: pick('objects', 'ferryRoute', objects.ferryRoute),
        dock: pick('objects', 'dock', objects.dock),
        bridge: pick('objects', 'bridge', objects.bridge),
        hazard: pick('objects', 'hazard', objects.hazard),
        navLight: pick('objects', 'navLight', objects.navLight),
        platform: pick('objects', 'platform', objects.platform),
      ),
      sky: MarineSky(
        sunCore: pick('sky', 'sunCore', sky.sunCore),
        sunRim: pick('sky', 'sunRim', sky.sunRim),
        sunTrack: pick('sky', 'sunTrack', sky.sunTrack),
        moonCore: pick('sky', 'moonCore', sky.moonCore),
        moonRim: pick('sky', 'moonRim', sky.moonRim),
        moonTrack: pick('sky', 'moonTrack', sky.moonTrack),
      ),
      weather: weather,
    );
  }

  /// Warm chart sand over graded blue water, deep navy ink. Reads as a paper
  /// chart that was drawn this decade.
  static const day = MarinePalette._(
    chrome: MarineChrome(
      ink: Color(0xFF0C2433),
      inkMuted: Color(0xFF476274),
      inkFaint: Color(0xFF7C93A2),
      surface: Color(0xFFF4F7F8),
      surfaceRaised: Color(0xFFFFFFFF),
      surfaceSunken: Color(0xFFE4EBEF),
      outline: Color(0xFFC3D2DA),
      outlineFaint: Color(0xFFDCE5EA),
      primary: Color(0xFF0E6F8C),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF3C5A6D),
      onSecondary: Color(0xFFFFFFFF),
      danger: Color(0xFFC8402C),
      caution: Color(0xFFD98A22),
      positive: Color(0xFF2C7F63),
      beacon: Color(0xFFC9982B),
    ),
    chart: MarineChart(
      backdrop: Color(0xFFCBDFE8),
      landBase: Color(0xFFF2EADA),
      landBeach: Color(0xFFF5E7C6),
      seaBase: Color(0xFFA9D3E6),
      seaEdge: Color(0xFF5FA5C4),
      coastline: Color(0xFF536B78),
      islandFill: Color(0xFFEDE3D0),
      islandEdge: Color(0xFFB9A98C),
      graticule: Color(0xFF89A5B4),
      meridian: Color(0xFF5E7C8C),
      labelStrong: Color(0xFF123243),
      labelSoft: Color(0xFF3E5C6E),
      labelFaint: Color(0xFF6C8494),
      labelHalo: Color(0xFFF7FAFB),
      landContour: Color(0xFFB6A489),
      landContourLabel: Color(0xFF7E6E56),
      roadTrunk: Color(0xFFE8DEC7),
      roadMinor: Color(0xFFEDE4D1),
      roadCasing: Color(0xFFD8CBB0),
      roadLabel: Color(0xFF9A8B71),
      hillshadeShadow: Color(0xFF41505A),
      hillshadeHighlight: Color(0xFFF2F6F8),
      hillshadeAccent: Color(0xFFBCCAD2),
    ),
    depth: MarineDepth(
      danger: Color(0xFFC25232),
      caution: Color(0xFFCC8A2E),
      coastal: Color(0xFF2F87A6),
      shelf: Color(0xFF2A6690),
      deep: Color(0xFF2A4E78),
      label: Color(0xFF3E5C6E),
    ),
    objects: MarineObjects(
      marina: Color(0xFF0E6F8C),
      anchorage: Color(0xFF2C7F63),
      fuel: Color(0xFFD0762A),
      customs: Color(0xFF6F53A3),
      port: Color(0xFF3C5A6D),
      service: Color(0xFF547486),
      slipway: Color(0xFF7A6A55),
      ferry: Color(0xFF1F7A83),
      ferryRoute: Color(0xFF7FB3B8),
      dock: Color(0xFF1D4E6E),
      bridge: Color(0xFF1D4E6E),
      hazard: Color(0xFFC8402C),
      navLight: Color(0xFFC9982B),
      platform: Color(0xFFC65A12),
    ),
    sky: MarineSky(
      sunCore: Color(0xFFE8B231),
      sunRim: Color(0xFFFAE1A0),
      sunTrack: Color(0xFF6A6A6A),
      moonCore: Color(0xFF7E8B98),
      moonRim: Color(0xFFB7C2CC),
      moonTrack: Color(0xFF6D7580),
    ),
    weather: MarineWeather(
      wind: [
        MarineStop(0, Color(0xFF8FC9D6)),
        MarineStop(6, Color(0xFF78C49A)),
        MarineStop(11, Color(0xFFB8C55C)),
        MarineStop(17, Color(0xFFE2B13C)),
        MarineStop(22, Color(0xFFE08A2E)),
        MarineStop(28, Color(0xFFD6602C)),
        MarineStop(34, Color(0xFFC23B2E)),
        MarineStop(41, Color(0xFFA32A47)),
        MarineStop(48, Color(0xFF7E2A72)),
        MarineStop(56, Color(0xFF5B2E8E)),
        MarineStop(64, Color(0xFF3C2E8E)),
      ],
      wave: [
        MarineStop(0, Color(0xFFA9DCE8)),
        MarineStop(0.5, Color(0xFF7FC2DE)),
        MarineStop(1, Color(0xFF57A6D0)),
        MarineStop(1.5, Color(0xFF3E86BE)),
        MarineStop(2.5, Color(0xFF3E6BAE)),
        MarineStop(4, Color(0xFF4A4F9E)),
        MarineStop(6, Color(0xFF6A3E8E)),
        MarineStop(9, Color(0xFF8E2F6E)),
      ],
    ),
  );

  /// Night watch. Same structure and same hue families as [day], pulled down
  /// to the luminance a dark-adapted eye can take, with the warm end of the
  /// spectrum carrying anything that must stand out.
  static const night = MarinePalette._(
    chrome: MarineChrome(
      ink: Color(0xFFB6C3CC),
      inkMuted: Color(0xFF7C8B96),
      inkFaint: Color(0xFF586772),
      surface: Color(0xFF070B0F),
      surfaceRaised: Color(0xFF0E141A),
      surfaceSunken: Color(0xFF04070A),
      outline: Color(0xFF25323C),
      outlineFaint: Color(0xFF18222A),
      primary: Color(0xFF357387),
      onPrimary: Color(0xFFD6E2E9),
      secondary: Color(0xFF334A57),
      onSecondary: Color(0xFFC2CDD5),
      danger: Color(0xFFB04434),
      caution: Color(0xFFA9762C),
      positive: Color(0xFF2F6B57),
      beacon: Color(0xFF9E7E2C),
    ),
    chart: MarineChart(
      backdrop: Color(0xFF04080B),
      landBase: Color(0xFF15191A),
      landBeach: Color(0xFF1C1D18),
      seaBase: Color(0xFF080F16),
      seaEdge: Color(0xFF1E3D50),
      coastline: Color(0xFF263C47),
      islandFill: Color(0xFF191E1E),
      islandEdge: Color(0xFF2B3538),
      graticule: Color(0xFF243743),
      meridian: Color(0xFF3A5260),
      labelStrong: Color(0xFFA9B7C1),
      labelSoft: Color(0xFF7F8E99),
      labelFaint: Color(0xFF5C6B75),
      labelHalo: Color(0xFF04080B),
      landContour: Color(0xFF3A4348),
      landContourLabel: Color(0xFF6E7B82),
      roadTrunk: Color(0xFF1F2427),
      roadMinor: Color(0xFF1A1E20),
      roadCasing: Color(0xFF0D1012),
      roadLabel: Color(0xFF4C575E),
      hillshadeShadow: Color(0xFF000000),
      hillshadeHighlight: Color(0xFF39424A),
      hillshadeAccent: Color(0xFF0B0F12),
    ),
    depth: MarineDepth(
      danger: Color(0xFF9E4331),
      caution: Color(0xFF8A6527),
      coastal: Color(0xFF2B5F73),
      shelf: Color(0xFF254A63),
      deep: Color(0xFF1E3550),
      label: Color(0xFF7F8E99),
    ),
    objects: MarineObjects(
      marina: Color(0xFF3E8096),
      anchorage: Color(0xFF2F7561),
      fuel: Color(0xFFA0702C),
      customs: Color(0xFF5B4A85),
      port: Color(0xFF42606F),
      service: Color(0xFF4A6674),
      slipway: Color(0xFF6A5C48),
      ferry: Color(0xFF2A6A72),
      ferryRoute: Color(0xFF17383D),
      dock: Color(0xFF3E7290),
      bridge: Color(0xFF3E7290),
      hazard: Color(0xFFB04434),
      navLight: Color(0xFFA8862F),
      platform: Color(0xFFC65A12),
    ),
    sky: MarineSky(
      sunCore: Color(0xFFA8822E),
      sunRim: Color(0xFFC9A855),
      sunTrack: Color(0xFF6B6255),
      moonCore: Color(0xFF8894A0),
      moonRim: Color(0xFF606C78),
      moonTrack: Color(0xFF4A5763),
    ),
    weather: MarineWeather(
      wind: [
        MarineStop(0, Color(0xFF2E5A63)),
        MarineStop(6, Color(0xFF2C5A47)),
        MarineStop(11, Color(0xFF5B612C)),
        MarineStop(17, Color(0xFF8A6B22)),
        MarineStop(22, Color(0xFF8C5520)),
        MarineStop(28, Color(0xFF893B1D)),
        MarineStop(34, Color(0xFF7D261E)),
        MarineStop(41, Color(0xFF6B1C2F)),
        MarineStop(48, Color(0xFF551D4C)),
        MarineStop(56, Color(0xFF3D1F5E)),
        MarineStop(64, Color(0xFF281F5E)),
      ],
      wave: [
        MarineStop(0, Color(0xFF2B4A56)),
        MarineStop(0.5, Color(0xFF254A5C)),
        MarineStop(1, Color(0xFF1F4460)),
        MarineStop(1.5, Color(0xFF1C3A5C)),
        MarineStop(2.5, Color(0xFF1D2F58)),
        MarineStop(4, Color(0xFF26254F)),
        MarineStop(6, Color(0xFF371E48)),
        MarineStop(9, Color(0xFF4A1839)),
      ],
    ),
  );
}

/// Surfaces, text and accents for panels, buttons and dialogs.
@immutable
class MarineChrome {
  const MarineChrome({
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.outline,
    required this.outlineFaint,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.danger,
    required this.caution,
    required this.positive,
    required this.beacon,
  });

  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color outline;
  final Color outlineFaint;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color danger;
  final Color caution;
  final Color positive;
  final Color beacon;
}

/// Land, water and the lines drawn over them.
@immutable
class MarineChart {
  const MarineChart({
    required this.backdrop,
    required this.landBase,
    required this.landBeach,
    required this.seaBase,
    required this.seaEdge,
    required this.coastline,
    required this.islandFill,
    required this.islandEdge,
    required this.graticule,
    required this.meridian,
    required this.labelStrong,
    required this.labelSoft,
    required this.labelFaint,
    required this.labelHalo,
    required this.landContour,
    required this.landContourLabel,
    required this.roadTrunk,
    required this.roadMinor,
    required this.roadCasing,
    required this.roadLabel,
    required this.hillshadeShadow,
    required this.hillshadeHighlight,
    required this.hillshadeAccent,
  });

  /// Shown where no tile has loaded yet.
  final Color backdrop;
  final Color landBase;
  final Color landBeach;
  final Color seaBase;

  /// Streams and rivers.
  final Color seaEdge;

  /// The land/water boundary. Carries the coast at night, where the two
  /// fills are deliberately close in luminance.
  final Color coastline;
  final Color islandFill;
  final Color islandEdge;
  final Color graticule;

  /// The line of the sun's current latitude.
  final Color meridian;
  final Color labelStrong;
  final Color labelSoft;
  final Color labelFaint;
  final Color labelHalo;
  final Color landContour;
  final Color landContourLabel;

  /// Roads are shore context, not a layer anyone navigates by, so they are
  /// drawn as a tonal step off [landBase] rather than in a colour of their
  /// own. They tell you a harbour is reachable and where a bridge crosses;
  /// they must never pull the eye off the water.
  final Color roadTrunk;
  final Color roadMinor;

  /// Sits under [landBase] so a road reads as cut into the shore instead of
  /// laid on top of it. This is what keeps roads legible at night without
  /// adding any light to the chart.
  final Color roadCasing;
  final Color roadLabel;
  final Color hillshadeShadow;
  final Color hillshadeHighlight;
  final Color hillshadeAccent;
}

/// Sounding bands. Shallow water is warm so a glance finds it; everything
/// safe stays in the blues.
@immutable
class MarineDepth {
  const MarineDepth({
    required this.danger,
    required this.caution,
    required this.coastal,
    required this.shelf,
    required this.deep,
    required this.label,
  });

  /// Shallower than [cautionFrom] metres.
  final Color danger;
  final Color caution;
  final Color coastal;
  final Color shelf;
  final Color deep;
  final Color label;

  /// Band edges in metres below the surface.
  static const cautionFrom = 5.0;
  static const coastalFrom = 20.0;
  static const shelfFrom = 50.0;
  static const deepFrom = 200.0;

  Color forDepth(double metres) {
    if (metres < cautionFrom) return danger;
    if (metres < coastalFrom) return caution;
    if (metres < shelfFrom) return coastal;
    if (metres < deepFrom) return shelf;
    return deep;
  }
}

/// Harbour objects a skipper looks for.
@immutable
class MarineObjects {
  const MarineObjects({
    required this.marina,
    required this.anchorage,
    required this.fuel,
    required this.customs,
    required this.port,
    required this.service,
    required this.slipway,
    required this.ferry,
    required this.ferryRoute,
    required this.dock,
    required this.bridge,
    required this.hazard,
    required this.navLight,
    required this.platform,
  });

  final Color marina;
  final Color anchorage;
  final Color fuel;
  final Color customs;
  final Color port;
  final Color service;
  final Color slipway;

  /// Ferry terminals and the names of ferry routes.
  final Color ferry;

  /// The ferry track itself. Held back from [ferry] because a route crosses
  /// the whole chart, so it has to sit behind the water it runs over rather
  /// than compete with it.
  final Color ferryRoute;
  final Color dock;
  final Color bridge;
  final Color hazard;
  final Color navLight;

  /// Offshore platform mark and its protection circle.
  final Color platform;
}

/// Sun and moon positions on the wide chart.
@immutable
class MarineSky {
  const MarineSky({
    required this.sunCore,
    required this.sunRim,
    required this.sunTrack,
    required this.moonCore,
    required this.moonRim,
    required this.moonTrack,
  });

  final Color sunCore;
  final Color sunRim;
  final Color sunTrack;
  final Color moonCore;
  final Color moonRim;
  final Color moonTrack;
}

/// Ramps for the forecast overlays. Wind stops are knots, wave stops are
/// significant height in metres.
@immutable
class MarineWeather {
  const MarineWeather({required this.wind, required this.wave});

  final List<MarineStop> wind;
  final List<MarineStop> wave;

  /// Flattened into a MapLibre `interpolate` ramp, ready to drop into a
  /// paint property alongside the value expression.
  List<Object> windRamp() => _ramp(wind);

  List<Object> waveRamp() => _ramp(wave);

  static List<Object> _ramp(List<MarineStop> stops) => [
    for (final stop in stops) ...[stop.value, stop.color.hex],
  ];
}

@immutable
class MarineStop {
  const MarineStop(this.value, this.color);

  final double value;
  final Color color;
}

extension MarineColorHex on Color {
  /// `#rrggbb`, the form MapLibre paint properties take.
  String get hex =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
