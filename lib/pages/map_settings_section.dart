import 'package:flutter/material.dart';

import 'package:free_open_ocean/common/element/app_button.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/theme/marine_palette.dart';
import 'package:free_open_ocean/services/map_chart_settings.dart';

// Palette field and zoom controls belonging to each switchable chart group.
const _layerFields = <String, String>{
  'land': 'landBase',
  'islands': 'islandFill',
  'graticule': 'graticule',
  'sky': 'sunCore',
  'coast': 'seaBase',
  'roads': 'roadTrunk',
  'roadNames': 'roadLabel',
  'contours': 'danger',
  'marinas': 'marina',
  'places': 'port',
  'slipways': 'slipway',
  'bridges': 'bridge',
  'harbour': 'dock',
  'ferries': 'ferryRoute',
  'waterNames': 'labelSoft',
  'seamarks': 'hazard',
  'platforms': 'platform',
  'platformZones': 'platform',
  'lighthouses': 'navLight',
};

/// Extra day and night colours shown inside a layer row.
const _lineOnly = <String>{
  'coastline',
  'graticule',
  'meridian',
  'landContour',
  'roadTrunk',
  'roadMinor',
  'roadCasing',
  'ferryRoute',
  'bridge',
  'sunTrack',
  'moonTrack',
};

const _fills = <String>{
  'landBase',
  'landBeach',
  'seaBase',
  'islandFill',
  'danger',
  'caution',
  'coastal',
  'shelf',
  'deep',
  'marina',
  'anchorage',
  'fuel',
  'customs',
  'port',
  'service',
  'slipway',
  'ferry',
  'dock',
  'hazard',
  'navLight',
  'platform',
  'sunCore',
  'moonCore',
};

/// A drawn edge that belongs on the same element as its fill.
const _lineForFill = <String, String>{
  'islandFill': 'islandEdge',
  'sunCore': 'sunRim',
  'moonCore': 'moonRim',
  'seaBase': 'seaEdge',
};

const _layerExtraColors = <String, List<String>>{
  'land': [
    'roadTrunk',
    'roadMinor',
    'roadCasing',
    'roadLabel',
    'landBeach',
    'islandFill',
    'coastline',
    'landContour',
    'landContourLabel',
    'hillshadeShadow',
    'hillshadeHighlight',
    'hillshadeAccent',
  ],
  'sky': ['meridian', 'sunTrack', 'moonCore', 'moonTrack'],
  'contours': ['caution', 'coastal', 'shelf', 'deep', 'label'],
  'marinas': ['anchorage'],
  'places': ['fuel', 'customs', 'service'],
  'ferries': ['ferry'],
  'waterNames': ['labelStrong', 'labelFaint', 'labelHalo'],
};

const _swatchSize = 16.0;
const _roleSlot = 24.0;
const _roleGap = 2.0;
const _themeGap = 16.0;
const _themeWidth = _roleSlot * 2 + _roleGap;

const _layerZooms = <String, List<String>>{
  'waterways': ['streams', 'rivers'],
  'roads': ['smallDetail'],
  'roadNames': ['roadNames'],
  'marinas': ['iconFull', 'marinaIcon', 'marinaName'],
  'places': ['places'],
  'slipways': ['slipway'],
  'bridges': ['bridges'],
  'ferries': ['ferry', 'ferryNames'],
  'waterNames': ['waterNames'],
  'seamarks': ['seamarks'],
  'platforms': ['platformIcon', 'platformName'],
  'platformZones': ['platformZone'],
  'lighthouses': ['lighthouseIcon', 'lighthouseName'],
};

/// Layers drawn inside another layer's tile instead of their own row.
const _nestedLayers = <String, List<String>>{
  'platforms': ['platformZones'],
};

/// Several layer rows that share one tile. The first id is the anchor.
const _sharedTiles = <String, List<String>>{
  'graticule': ['graticule', 'sky'],
  'coast': ['coast', 'waterways', 'contours', 'ferries'],
};

/// Shared tiles drawn immediately after another layer, not at the anchor.
const _sharedTileAfter = <String, String>{
  'land': 'coast',
};

/// Shared tiles drawn before the layer list.
const _sharedTilesFirst = <String>['graticule'];

bool _followsSharedTile(String id) => _sharedTiles.values.any(
  (ids) => ids.length > 1 && ids.first != id && ids.contains(id),
);

/// Layers with no own tile; their colours and zooms sit on the parent.
const _absorbedLayers = <String, String>{
  'islands': 'land',
  'roads': 'land',
  'roadNames': 'land',
};

bool _hidesOwnTile(String id) =>
    _absorbedLayers.containsKey(id) ||
    _nestedLayers.values.any((ids) => ids.contains(id));

/// Chart visibility id for a colour row. Some colours share one switch.
String _elementIdForColor(String field) => switch (field) {
  'islandFill' => 'islands',
  'roadLabel' => 'roadNames',
  'hillshadeShadow' || 'hillshadeHighlight' || 'hillshadeAccent' => 'hillshade',
  'seaBase' => 'coast',
  'danger' => 'contours',
  'sunCore' => 'sky',
  'graticule' => 'graticule',
  'marina' => 'marinas',
  'port' => 'places',
  'slipway' => 'slipways',
  'bridge' => 'bridges',
  'dock' => 'harbour',
  'ferryRoute' => 'ferries',
  'labelSoft' => 'waterNames',
  'hazard' => 'seamarks',
  'platform' => 'platforms',
  'navLight' => 'lighthouses',
  'landBase' => 'land',
  'roadTrunk' => 'roads',
  _ => field,
};

String _elementIdForZoom(String id) => switch (id) {
  'platformZone' => 'platformZones',
  _ => id,
};

class _ElementSwitch extends StatelessWidget {
  const _ElementSwitch(this.id, {this.header = false});

  final String id;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final on = MapChartSettings.instance.layerOn(id);
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 36,
        child: Transform.scale(
          scale: header ? 0.68 : 0.68 * 0.6,
          child: Switch(
            value: on,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) => MapChartSettings.instance.setLayer(id, value),
          ),
        ),
      ),
    );
  }
}

/// Icon mapping for each layer tile header.
const IconData _kIsland = IconData(0xe9d3, fontFamily: 'MaterialIcons');

IconData _getIcon(String id) {
  switch (id) {
    case 'land': return Icons.map;
    case 'islands': return _kIsland;
    case 'graticule': return Icons.grid_on;
    case 'sky': return Icons.wb_sunny;
    case 'coast': return Icons.water;
    case 'waterways': return Icons.radar;
    case 'roads': return Icons.directions_car;
    case 'roadNames': return Icons.label;
    case 'contours': return Icons.trending_up;
    case 'marinas': return Icons.terrain;
    case 'places': return Icons.location_on;
    case 'slipways': return Icons.directions_boat;
    case 'bridges': return Icons.architecture;
    case 'harbour': return Icons.dock;
    case 'ferries': return Icons.terrain;
    case 'waterNames': return Icons.text_fields;
    case 'seamarks': return Icons.navigation;
    case 'platforms': return Icons.factory;
    case 'platformZones': return Icons.circle;
    case 'lighthouses': return Icons.light;
    default: return Icons.layers;
  }
}

/// Background color tint for each layer tile.
const _layerTints = <String, Color>{
  'land': Color(0xFFA5D6A7),
  'islands': Color(0xFF81C784),
  'graticule': Color(0xFFB39DDB),
  'sky': Color(0xFF90CAF9),
  'coast': Color(0xFF4FC3F7),
  'waterways': Color(0xFF4DD0E1),
  'roads': Color(0xFFFFB74D),
  'roadNames': Color(0xFFFFA726),
  'contours': Color(0xFFEF5350),
  'marinas': Color(0xFFEC407A),
  'places': Color(0xFFAB47BC),
  'slipways': Color(0xFF26A69A),
  'bridges': Color(0xFF78909C),
  'harbour': Color(0xFF8D6E63),
  'ferries': Color(0xFF66BB6A),
  'waterNames': Color(0xFF29B6F6),
  'seamarks': Color(0xFFD4E157),
  'platforms': Color(0xFF5C6BC0),
  'platformZones': Color(0xFF3F51B5),
  'lighthouses': Color(0xFFFFEE58),
};

class MapSettingsSection extends StatelessWidget {
  const MapSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListenableBuilder(
        listenable: MapChartSettings.instance,
        builder: (context, _) => SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.translate('map_chart'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l.translate('map_chart_lead')),
              const SizedBox(height: 20),
              for (final id in _sharedTilesFirst)
                _SharedTile(ids: _sharedTiles[id]!),
              // Full-width layer tiles (100% width, stacked vertically)
              for (final layer in MapChartSettings.layers) ...[
                if (!_hidesOwnTile(layer.id) &&
                    !_followsSharedTile(layer.id) &&
                    !_sharedTileAfter.containsValue(layer.id) &&
                    !_sharedTilesFirst.contains(layer.id))
                  _sharedTiles[layer.id] == null
                      ? _LayerTile(layer: layer)
                      : _SharedTile(ids: _sharedTiles[layer.id]!),
                if (_sharedTileAfter[layer.id] != null)
                  _SharedTile(ids: _sharedTiles[_sharedTileAfter[layer.id]!]!),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  icon: Icons.restart_alt,
                  size: 'm',
                  text: l.translate('map_reset'),
                  theme: 'info',
                  showTextOnBigScreen: true,
                  onPressed: MapChartSettings.instance.reset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary colour plus extras for one layer tile, including nested layers.
List<MapColorSetting> _colorsForLayer(String layerId) {
  // platformZones shares the platforms primary; do not repeat it as its own row.
  if (layerId == 'platformZones') return const [];
  final fields = <String>[
    if (_layerFields[layerId] != null) _layerFields[layerId]!,
    ..._layerExtraColors[layerId] ?? const <String>[],
    for (final nestedId in _nestedLayers[layerId] ?? const <String>[]) ...[
      if (_layerFields[nestedId] != null) _layerFields[nestedId]!,
      ..._layerExtraColors[nestedId] ?? const <String>[],
    ],
  ];
  // Absorbed layers that only add extras already listed on the parent
  // (roads / islands on land) must not repeat their primary field.
  final seen = <String>{};
  return [
    for (final field in fields)
      if (seen.add(field))
        MapChartSettings.colors.firstWhere((c) => c.field == field),
  ];
}

/// Zooms that belong on a tile: its own, nested children, and absorbed layers.
List<MapZoomSetting> _zoomsForLayer(String layerId) {
  final ids = <String>{
    ..._layerZooms[layerId] ?? const <String>[],
    for (final nestedId in _nestedLayers[layerId] ?? const <String>[])
      ..._layerZooms[nestedId] ?? const <String>[],
    for (final entry in _absorbedLayers.entries)
      if (entry.value == layerId) ..._layerZooms[entry.key] ?? const <String>[],
  };
  // Keep Local streets (smallDetail) before Road names so road colours can
  // sit under Local streets in the land tile.
  const prefer = ['smallDetail', 'roadNames'];
  final ordered = [
    for (final id in prefer)
      if (ids.contains(id)) id,
    for (final id in ids)
      if (!prefer.contains(id)) id,
  ];
  return [
    for (final id in ordered)
      MapChartSettings.zooms.firstWhere((z) => z.id == id),
  ];
}

/// One bordered tile holding several layer rows.
class _SharedTile extends StatelessWidget {
  const _SharedTile({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    final layers = [
      for (final id in ids)
        MapChartSettings.layers.firstWhere((item) => item.id == id),
    ];
    return _SettingsBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < layers.length; i++) ...[
            if (i > 0)
              Divider(
                height: 16,
                thickness: 0.5,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            _LayerTile(layer: layers[i], boxed: false),
          ],
        ],
      ),
    );
  }
}

class _LayerTile extends StatefulWidget {
  const _LayerTile({required this.layer, this.boxed = true});
  final MapLayerSetting layer;
  final bool boxed;

  @override
  State<_LayerTile> createState() => _LayerTileState();
}

class _LayerTileState extends State<_LayerTile> {
  bool _expanded = false;
  MapLayerSetting get layer => widget.layer;

  @override
  Widget build(BuildContext context) {
    final name = AppLocalizations.of(context)!.translate(layer.labelKey);
    final nested = [
      for (final id in _nestedLayers[layer.id] ?? const <String>[])
        MapChartSettings.layers.firstWhere((item) => item.id == id),
    ];
    final zoomSettings = _zoomsForLayer(layer.id);
    final colors = _colorsForLayer(layer.id);
    // Road colours sit under Local streets, not after hillshade.
    const roadFields = {'roadTrunk', 'roadMinor', 'roadCasing', 'roadLabel'};
    final roadColors = [
      for (final color in colors)
        if (roadFields.contains(color.field)) color,
    ];
    final otherColors = [
      for (final color in colors)
        if (!roadFields.contains(color.field)) color,
    ];
    final hasBody =
        zoomSettings.isNotEmpty || colors.isNotEmpty || nested.isNotEmpty;

    // Calculate tile icon color based on layer type
    final iconColor = _layerTints[layer.id] ?? Colors.grey;

    final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tile header row
          Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(layer.id),
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Semantics(
                label: name,
                child: _ElementSwitch(layer.id, header: true),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.translate(
                  _expanded ? 'map_collapse_details' : 'map_expand_details',
                ),
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          // Divider under header. A shared tile draws its own rule.
          if (widget.boxed || _expanded)
            Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          // Expandable content — related zooms and colours stay together
          if (_expanded && hasBody) ...[
            const _ParameterLine(),
            // Keep zoom headers together; road colours follow that block.
            for (final zoom in zoomSettings)
              _ZoomRange(
                setting: zoom,
                trailing: null,
                inlineLabel: null,
              ),
            ...roadColors.map((color) => _ColorRow(setting: color)),
            if (nested.isNotEmpty) ...[
              const _ParameterLine(),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  AppLocalizations.of(context)!.translate('map_nested_layers'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final nestedLayer in nested)
                _NestedLayerControl(
                  nestedLayer: nestedLayer,
                  parentLayer: layer,
                ),
            ],
            ...otherColors.map((color) => _ColorRow(setting: color)),
          ],
        ],
    );
    if (!widget.boxed) return column;
    return _SettingsBox(child: column);
  }
}

/// A compact nested layer control shown inside its parent tile.
class _NestedLayerControl extends StatelessWidget {
  const _NestedLayerControl({
    required this.nestedLayer,
    required this.parentLayer,
  });
  final MapLayerSetting nestedLayer;
  final MapLayerSetting parentLayer;

  @override
  Widget build(BuildContext context) {
    final name = AppLocalizations.of(context)!.translate(nestedLayer.labelKey);
    final zooms = MapChartSettings.zooms.where(
      (z) => (_layerZooms[nestedLayer.id] ?? []).contains(z.id),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Small indent marker
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _ElementSwitch(nestedLayer.id),
            ],
          ),
          // Show zoom ranges for nested layer
          for (final zoom in zooms)
            _ZoomRange(
              setting: zoom,
              trailing: null,
              inlineLabel: null,
            ),
        ],
      ),
    );
  }
}

class _SettingsBox extends StatelessWidget {
  const _SettingsBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _ParameterLine extends StatelessWidget {
  const _ParameterLine();

  @override
  Widget build(BuildContext context) => Divider(
    height: 8,
    thickness: 0.5,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _ZoomRange extends StatefulWidget {
  const _ZoomRange({required this.setting, this.trailing, this.inlineLabel});
  final MapZoomSetting setting;
  final Widget? trailing;

  /// When set, the range and its colour sit on one line under this label.
  final String? inlineLabel;

  @override
  State<_ZoomRange> createState() => _ZoomRangeState();
}

class _ZoomRangeState extends State<_ZoomRange> {
  RangeValues? _drag;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = l.translate(widget.setting.labelKey);
    final stored = MapChartSettings.instance.zoomRange(widget.setting.id);
    final values =
        _drag ?? RangeValues(stored.$1.toDouble(), stored.$2.toDouble());
    final scheme = Theme.of(context).colorScheme;
    final minLabel = values.start.round().toString();
    final maxLabel = values.end.round().toString();
    final slider = Expanded(
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: scheme.primary,
          inactiveTrackColor: scheme.outlineVariant,
          thumbColor: scheme.primary,
          overlayColor: scheme.primary.withValues(alpha: 0.16),
          rangeThumbShape: const RoundRangeSliderThumbShape(
            enabledThumbRadius: 6,
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        ),
        child: RangeSlider(
          values: values,
          min: 2,
          max: 22,
          divisions: 20,
          padding: EdgeInsets.zero,
          semanticFormatterCallback: (value) => '$name ${value.round()}',
          onChanged: (next) => setState(() => _drag = next),
          onChangeEnd: (next) async {
            await MapChartSettings.instance.setZoomRange(
              widget.setting.id,
              next.start.round(),
              next.end.round(),
            );
            if (mounted) setState(() => _drag = null);
          },
        ),
      ),
    );
    final value = SizedBox(width: 52, child: Text('$minLabel - $maxLabel'));
    final trailing = widget.trailing;
    final switchId = _elementIdForZoom(widget.setting.id);
    final inlineLabel = widget.inlineLabel;
    if (inlineLabel != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ElementSwitch(switchId),
              SizedBox(
                width: 132,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(l.translate(inlineLabel), maxLines: 1),
                ),
              ),
              slider,
              const SizedBox(width: 12),
              value,
              ?trailing,
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ElementSwitch(switchId),
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 41),
                slider,
                const SizedBox(width: 12),
                value,
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.setting, this.swatchesOnly = false});

  final bool swatchesOnly;

  final MapColorSetting setting;

  @override
  Widget build(BuildContext context) {
    final day = MarinePalette.of(Brightness.light);
    final night = MarinePalette.of(Brightness.dark);
    final line = _linePartner(setting);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: swatchesOnly ? 0 : 1),
      child: Row(
        children: [
          if (!swatchesOnly) ...[
            _ElementSwitch(_elementIdForColor(setting.field)),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.translate(setting.labelKey),
              ),
            ),
          ],
          _roleMarks(context, day, night, line, asLine: false),
          const SizedBox(width: _themeGap),
          _roleMarks(context, day, night, line, asLine: true),
        ],
      ),
    );
  }

  MapColorSetting? _linePartner(MapColorSetting fill) {
    final field = _lineForFill[fill.field];
    if (field == null) return null;
    for (final color in MapChartSettings.colors) {
      if (color.field == field) return color;
    }
    return null;
  }

  Widget _roleMarks(
    BuildContext context,
    MarinePalette day,
    MarinePalette night,
    MapColorSetting? line, {
    required bool asLine,
  }) {
    final lineOnly = line == null && _lineOnly.contains(setting.field);
    Widget slot(String theme, MarinePalette palette, MapColorSetting? item) {
      return SizedBox(
        width: _roleSlot,
        child: item == null
            ? null
            : Center(
                child: _swatch(
                  context,
                  theme,
                  item,
                  _read(palette, item),
                  asLine,
                ),
              ),
      );
    }

    final MapColorSetting? shown = asLine
        ? (line ?? (lineOnly ? setting : null))
        : (lineOnly ? null : setting);
    return SizedBox(
      width: _themeWidth,
      child: Row(
        children: [
          slot('day', day, shown),
          const SizedBox(width: _roleGap),
          slot('night', night, shown),
        ],
      ),
    );
  }

  Color _read(MarinePalette palette, MapColorSetting item) {
    final group = switch (item.group) {
      'chart' => _chart(palette, item),
      'depth' => _depth(palette, item),
      'objects' => _objects(palette, item),
      _ => _sky(palette, item),
    };
    return group;
  }

  Color _chart(MarinePalette palette, MapColorSetting item) {
    final chart = palette.chart;
    return switch (item.field) {
      'landBase' => chart.landBase,
      'landBeach' => chart.landBeach,
      'seaBase' => chart.seaBase,
      'seaEdge' => chart.seaEdge,
      'coastline' => chart.coastline,
      'islandFill' => chart.islandFill,
      'islandEdge' => chart.islandEdge,
      'graticule' => chart.graticule,
      'meridian' => chart.meridian,
      'labelStrong' => chart.labelStrong,
      'labelSoft' => chart.labelSoft,
      'labelFaint' => chart.labelFaint,
      'labelHalo' => chart.labelHalo,
      'landContour' => chart.landContour,
      'landContourLabel' => chart.landContourLabel,
      'hillshadeShadow' => chart.hillshadeShadow,
      'hillshadeHighlight' => chart.hillshadeHighlight,
      'hillshadeAccent' => chart.hillshadeAccent,
      'roadTrunk' => chart.roadTrunk,
      'roadMinor' => chart.roadMinor,
      'roadCasing' => chart.roadCasing,
      _ => chart.roadLabel,
    };
  }

  Color _depth(MarinePalette palette, MapColorSetting item) {
    final depth = palette.depth;
    return switch (item.field) {
      'danger' => depth.danger,
      'caution' => depth.caution,
      'coastal' => depth.coastal,
      'shelf' => depth.shelf,
      'deep' => depth.deep,
      _ => depth.label,
    };
  }

  Color _objects(MarinePalette palette, MapColorSetting item) {
    final objects = palette.objects;
    return switch (item.field) {
      'marina' => objects.marina,
      'anchorage' => objects.anchorage,
      'fuel' => objects.fuel,
      'customs' => objects.customs,
      'port' => objects.port,
      'service' => objects.service,
      'slipway' => objects.slipway,
      'ferry' => objects.ferry,
      'ferryRoute' => objects.ferryRoute,
      'dock' => objects.dock,
      'bridge' => objects.bridge,
      'hazard' => objects.hazard,
      'navLight' => objects.navLight,
      _ => objects.platform,
    };
  }

  Color _sky(MarinePalette palette, MapColorSetting item) {
    final sky = palette.sky;
    return switch (item.field) {
      'sunCore' => sky.sunCore,
      'sunRim' => sky.sunRim,
      'sunTrack' => sky.sunTrack,
      'moonCore' => sky.moonCore,
      'moonRim' => sky.moonRim,
      _ => sky.moonTrack,
    };
  }

  Widget _swatch(
    BuildContext context,
    String theme,
    MapColorSetting item,
    Color color,
    bool line,
  ) {
    final l = AppLocalizations.of(context)!;
    final role = l.translate(line ? 'map_color_line' : 'map_color_fill');
    final when = l.translate(
      theme == 'day' ? 'map_color_day' : 'map_color_night',
    );
    final mark = line
        ? Container(
            width: _swatchSize,
            height: _swatchSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          )
        : Material(
            color: color,
            shape: const CircleBorder(),
            child: const SizedBox(width: _swatchSize, height: _swatchSize),
          );
    return Tooltip(
      message: '${l.translate(setting.labelKey)} · $role · $when',
      child: GestureDetector(onTap: () => _edit(context, theme), child: mark),
    );
  }

  Future<void> _edit(BuildContext context, String theme) async {
    final partner = _linePartner(setting);
    final palette = MarinePalette.of(
      theme == 'day' ? Brightness.light : Brightness.dark,
    );
    final picked = await showDialog<_PaintColors>(
      context: context,
      builder: (context) => _PaintPicker(
        title: AppLocalizations.of(context)!.translate(setting.labelKey),
        fill: _read(palette, setting),
        line: partner == null ? null : _read(palette, partner),
        singleRole: partner != null
            ? null
            : _lineOnly.contains(setting.field)
                ? 'map_color_line'
                : _fills.contains(setting.field)
                    ? 'map_color_fill'
                    : null,
      ),
    );
    if (picked == null) return;
    final settings = MapChartSettings.instance;
    await settings.setColor(
      theme,
      setting.group,
      setting.field,
      picked.fill.toARGB32(),
    );
    if (partner != null && picked.line != null) {
      await settings.setColor(
        theme,
        partner.group,
        partner.field,
        picked.line!.toARGB32(),
      );
    }
  }
}

class _PaintColors {
  const _PaintColors(this.fill, this.line);
  final Color fill;
  final Color? line;
}

class _PaintPicker extends StatefulWidget {
  const _PaintPicker({
    required this.title,
    required this.fill,
    required this.line,
    this.singleRole,
  });

  final String title;
  final Color fill;
  final Color? line;

  /// Set when the element is only a fill or only a line.
  final String? singleRole;

  @override
  State<_PaintPicker> createState() => _PaintPickerState();
}

class _PaintPickerState extends State<_PaintPicker> {
  late HSVColor _fill = HSVColor.fromColor(widget.fill);
  late HSVColor? _line = widget.line == null
      ? null
      : HSVColor.fromColor(widget.line!);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fillName = _line == null
        ? (widget.singleRole == null
              ? widget.title
              : l.translate(widget.singleRole!))
        : l.translate('map_color_fill');
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pane(fillName, _fill, (next) => setState(() => _fill = next)),
            if (_line != null)
              _pane(
                l.translate('map_color_line'),
                _line!,
                (next) => setState(() => _line = next),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.translate('map_cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _PaintColors(_fill.toColor(), _line?.toColor()),
          ),
          child: Text(l.translate('map_save')),
        ),
      ],
    );
  }

  Widget _pane(String name, HSVColor color, ValueChanged<HSVColor> onChanged) {
    Widget channel(
      String label,
      double value,
      double max,
      ValueChanged<double> set,
    ) {
      return Row(
        children: [
          SizedBox(width: 16, child: Text(label)),
          Expanded(
            child: Slider(
              min: 0,
              max: max,
              value: value.clamp(0, max),
              onChanged: set,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 18,
                decoration: BoxDecoration(
                  color: color.toColor(),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(name),
            ],
          ),
          channel('H', color.hue, 360, (value) {
            onChanged(color.withHue(value));
          }),
          channel('S', color.saturation, 1, (value) {
            onChanged(color.withSaturation(value));
          }),
          channel('B', color.value, 1, (value) {
            onChanged(color.withValue(value));
          }),
        ],
      ),
    );
  }
}