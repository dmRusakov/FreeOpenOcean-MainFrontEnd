import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:free_open_ocean/common/element/app_button.dart';
import 'package:free_open_ocean/core/localization/app_localizations.dart';
import 'package:free_open_ocean/core/theme/marine_palette.dart';
import 'package:free_open_ocean/pages/screen_color.dart';
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
  'equator',
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
  'graticule': [
    'equator',
    'sunCore',
    'sunTrack',
    'meridian',
    'moonCore',
    'moonTrack',
  ],
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

/// Zoom and a pixel line width, kept with that line's colour.
/// Prefer [_detailTiles] for the full standard row (zoom, type, width, colours).
const _linePxFor = <String, List<String>>{};

/// Detail tiles: Name (18), Zoom, Line type, Line width, Fill, Line.
const _detailTiles = <String>{'land', 'graticule'};

/// Fixed title column width for every parameter name in a detail tile.
const _detailTitleChars = 18;

/// Fields that expose line type and line width menus.
bool _hasLineStrokeControls(String field) =>
    _lineOnly.contains(field) || _lineForFill.containsKey(field);

/// Width for a compact dropdown: label sample plus the chevron.
double _menuSlotWidth(BuildContext context, String sample) {
  final painter = TextPainter(
    text: TextSpan(
      text: sample,
      style: Theme.of(context).textTheme.bodySmall,
    ),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return painter.width + 18;
}

double _lineTypeSlotWidth(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  var widest = 0.0;
  for (final type in ChartLineType.choices) {
    final width = _menuSlotWidth(context, l.translate(type.labelKey));
    if (width > widest) widest = width;
  }
  return widest;
}

double _lineWidthSlotWidth(BuildContext context) {
  var widest = 0.0;
  for (final px in MapChartSettings.lineWidthChoices) {
    final width = _menuSlotWidth(context, _lineWidthLabel(px));
    if (width > widest) widest = width;
  }
  return widest;
}

/// An existing zoom that already belongs to this colour.
String _rowZoomId(String field) => switch (field) {
  'roadMinor' => 'smallDetail',
  'roadLabel' => 'roadNames',
  'hillshadeShadow' || 'hillshadeHighlight' || 'hillshadeAccent' => 'hillshade',
  _ => field,
};

MapZoomSetting _zoomSetting(String id) {
  for (final zoom in MapChartSettings.zooms) {
    if (zoom.id == id) return zoom;
  }
  return MapZoomSetting(id, id, 2);
}

const _layerZooms = <String, List<String>>{
  'graticule': ['graticule', 'equator'],
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
  'coast': ['coast', 'waterways', 'contours', 'ferries', 'slipways', 'bridges'],
  'marinas': [
    'marinas',
    'places',
    'harbour',
    'waterNames',
    'seamarks',
    'platforms',
    'lighthouses',
  ],
};

/// Title shown on a shared tile. Single-layer tiles use their own row name.
const _sharedTileTitles = <String, String>{
  'coast': 'map_tile_sea',
  'marinas': 'map_tile_places',
};

/// Shared tiles drawn immediately after another layer, not at the anchor.
const _sharedTileAfter = <String, String>{'land': 'coast'};

/// Single tiles drawn before the layer list.
const _tilesFirst = <String>['graticule'];

/// Single tiles drawn after every other tile.
const _tilesLast = <String>[];

/// One header and one collapse, the same as a single layer tile.
const _singleCollapseTiles = <String>{'coast', 'marinas'};

bool _followsSharedTile(String id) => _sharedTiles.values.any(
  (ids) => ids.length > 1 && ids.first != id && ids.contains(id),
);

/// Layers with no own tile; their colours and zooms sit on the parent.
const _absorbedLayers = <String, String>{
  'islands': 'land',
  'roads': 'land',
  'roadNames': 'land',
  'sky': 'graticule',
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
  'equator' => 'equator',
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
  'roadTrunk' => 'roadTrunk',
  _ => field,
};

String _elementIdForZoom(String id) => switch (id) {
  'platformZone' => 'platformZones',
  _ => id,
};

class _ElementSwitch extends StatelessWidget {
  const _ElementSwitch(this.id, {this.header = false}) : ids = null;

  /// One switch for every layer in a tile.
  const _ElementSwitch.group(this.ids, {this.header = false}) : id = '';

  final String id;
  final List<String>? ids;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final members = ids ?? [id];
    final settings = MapChartSettings.instance;
    final on = members.every(settings.layerOn);
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 36,
        child: Transform.scale(
          scale: header ? 0.68 : 0.68 * 0.6,
          child: Switch(
            value: on,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) async {
              for (final member in members) {
                await settings.setLayer(member, value);
              }
            },
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
    case 'land':
      return Icons.map;
    case 'islands':
      return _kIsland;
    case 'graticule':
      return Icons.grid_on;
    case 'sky':
      return Icons.wb_sunny;
    case 'coast':
      return Icons.water;
    case 'waterways':
      return Icons.radar;
    case 'roads':
      return Icons.directions_car;
    case 'roadNames':
      return Icons.label;
    case 'contours':
      return Icons.trending_up;
    case 'marinas':
      return Icons.terrain;
    case 'places':
      return Icons.location_on;
    case 'slipways':
      return Icons.directions_boat;
    case 'bridges':
      return Icons.architecture;
    case 'harbour':
      return Icons.dock;
    case 'ferries':
      return Icons.terrain;
    case 'waterNames':
      return Icons.text_fields;
    case 'seamarks':
      return Icons.navigation;
    case 'platforms':
      return Icons.factory;
    case 'platformZones':
      return Icons.circle;
    case 'lighthouses':
      return Icons.light;
    default:
      return Icons.layers;
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
              for (final id in _tilesFirst)
                _LayerTile(
                  layer: MapChartSettings.layers.firstWhere(
                    (item) => item.id == id,
                  ),
                ),
              // Full-width layer tiles (100% width, stacked vertically)
              for (final layer in MapChartSettings.layers) ...[
                if (!_hidesOwnTile(layer.id) &&
                    !_followsSharedTile(layer.id) &&
                    !_sharedTileAfter.containsValue(layer.id) &&
                    !_tilesFirst.contains(layer.id) &&
                    !_tilesLast.contains(layer.id))
                  _sharedTiles[layer.id] == null
                      ? _LayerTile(layer: layer)
                      : _SharedTile(ids: _sharedTiles[layer.id]!),
                if (_sharedTileAfter[layer.id] != null)
                  _SharedTile(ids: _sharedTiles[_sharedTileAfter[layer.id]!]!),
              ],
              for (final id in _tilesLast)
                _LayerTile(
                  layer: MapChartSettings.layers.firstWhere(
                    (item) => item.id == id,
                  ),
                ),
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
class _SharedTile extends StatefulWidget {
  const _SharedTile({required this.ids});

  final List<String> ids;

  @override
  State<_SharedTile> createState() => _SharedTileState();
}

class _SharedTileState extends State<_SharedTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final layers = [
      for (final id in widget.ids)
        MapChartSettings.layers.firstWhere((item) => item.id == id),
    ];
    if (_singleCollapseTiles.contains(widget.ids.first)) {
      return _SettingsBox(child: _folded(context, layers));
    }
    final titleKey = _sharedTileTitles[widget.ids.first];
    final title = titleKey == null
        ? null
        : AppLocalizations.of(context)!.translate(titleKey);
    return _SettingsBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Divider(
              height: 16,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
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

  /// One header and one chevron. Member rows appear only while it is open.
  Widget _folded(BuildContext context, List<MapLayerSetting> layers) {
    final anchor = layers.first;
    final name = AppLocalizations.of(
      context,
    )!.translate(_sharedTileTitles[anchor.id] ?? anchor.labelKey);
    // Sea rows are a name and a switch. The header switch covers the tile.
    final switchesOnly = anchor.id == 'coast';
    final iconColor = _layerTints[anchor.id] ?? Colors.grey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIcon(anchor.id), color: iconColor, size: 24),
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
              child: _ElementSwitch.group([
                for (final layer in layers) layer.id,
              ], header: true),
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
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        if (_expanded)
          for (var i = 0; i < layers.length; i++) ...[
            if (i > 0)
              Divider(
                height: 16,
                thickness: 0.5,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            _LayerTile(
              layer: layers[i],
              boxed: false,
              collapsible: false,
              showIcon: !switchesOnly,
            ),
          ],
      ],
    );
  }
}

class _LayerTile extends StatefulWidget {
  const _LayerTile({
    required this.layer,
    this.boxed = true,
    this.collapsible = true,
    this.showIcon = true,
  });
  final MapLayerSetting layer;
  final bool boxed;

  /// A folded group supplies the one chevron, so the row stays open.
  final bool collapsible;

  /// Sea rows keep the name and the switch.
  final bool showIcon;

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
    final lineIds = _linePxFor[layer.id] ?? const <String>[];
    final detailTile = _detailTiles.contains(layer.id);
    final embeddedZooms = {
      ...lineIds,
      if (detailTile) ...[for (final color in colors) _rowZoomId(color.field)],
    };
    final roadColors = [
      for (final color in colors)
        if (roadFields.contains(color.field)) color,
    ];
    final otherColors = [
      for (final color in colors)
        if (!roadFields.contains(color.field) && !lineIds.contains(color.field))
          color,
    ];
    final hasBody =
        zoomSettings.isNotEmpty ||
        colors.isNotEmpty ||
        nested.isNotEmpty ||
        lineIds.isNotEmpty;
    final open = widget.collapsible ? _expanded : true;

    // Calculate tile icon color based on layer type
    final iconColor = _layerTints[layer.id] ?? Colors.grey;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tile header row
        Row(
          children: [
            if (widget.showIcon) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIcon(layer.id), color: iconColor, size: 24),
              ),
              const SizedBox(width: 8),
            ],
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
            if (widget.collapsible)
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
        if (widget.boxed || open)
          Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        // Expandable content — related zooms and colours stay together
        if (open && hasBody) ...[
          const _ParameterLine(),
          if (colors.isNotEmpty || lineIds.isNotEmpty)
            _InputColumnHeaders(
              titleChars: detailTile ? _detailTitleChars : null,
              showZoom: detailTile || lineIds.isNotEmpty,
              showLineMenus: detailTile || lineIds.isNotEmpty,
            ),
          for (final zoom in zoomSettings)
            if (!embeddedZooms.contains(zoom.id))
              _ZoomRange(
                setting: zoom,
                trailing: null,
                inlineLabel: null,
                titleChars: detailTile ? _detailTitleChars : null,
              ),
          if (!detailTile)
            for (final id in lineIds)
              for (final color in colors)
                if (color.field == id)
                  _ColorRow(setting: color, lineWidthId: id, zoomId: id),
          if (detailTile)
            for (final color in colors)
              _ColorRow(
                setting: color,
                lineWidthId: color.field,
                zoomId: _rowZoomId(color.field),
                titleChars: _detailTitleChars,
              )
          else
            ...roadColors.map((color) => _ColorRow(setting: color)),
          if (nested.isNotEmpty) ...[
            const _ParameterLine(),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                AppLocalizations.of(context)!.translate('map_nested_layers'),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final nestedLayer in nested)
              _NestedLayerControl(nestedLayer: nestedLayer, parentLayer: layer),
          ],
          if (!detailTile)
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
            _ZoomRange(setting: zoom, trailing: null, inlineLabel: null),
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

/// Column titles under a tile header, aligned with the input row below.
class _InputColumnHeaders extends StatelessWidget {
  const _InputColumnHeaders({
    this.titleChars,
    this.showZoom = false,
    this.showLineMenus = false,
  });

  final int? titleChars;
  final bool showZoom;
  final bool showLineMenus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final dayNightStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final typeWidth = showLineMenus ? _lineTypeSlotWidth(context) : null;
    final widthWidth = showLineMenus ? _lineWidthSlotWidth(context) : null;
    final name = Text(
      l.translate('map_column_name'),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    Widget themeLabel(String key) {
      return SizedBox(
        width: _roleSlot,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l.translate(key),
            style: dayNightStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      );
    }

    Widget pair(String top) {
      return SizedBox(
        width: _themeWidth,
        child: Column(
          children: [
            Text(top, style: style, textAlign: TextAlign.center),
            Row(
              children: [
                themeLabel('map_color_day'),
                const SizedBox(width: _roleGap),
                themeLabel('map_color_night'),
              ],
            ),
          ],
        ),
      );
    }

    Widget slotLabel(String key, double? width) {
      final text = Text(
        l.translate(key),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
      );
      if (width == null) return text;
      return SizedBox(
        width: width,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: text,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          // Matches _ElementSwitch: 36 wide + 5 right padding.
          const SizedBox(width: 41),
          if (titleChars != null)
            _charsTitle(context, name, titleChars!)
          else if (showZoom)
            name
          else
            Expanded(child: name),
          if (showZoom) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.translate('map_column_zoom'),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (showLineMenus) ...[
            slotLabel('map_line_type', typeWidth),
            const SizedBox(width: 8),
            slotLabel('map_line_width', widthWidth),
            const SizedBox(width: 8),
          ],
          pair(l.translate('map_color_fill')),
          const SizedBox(width: _themeGap),
          pair(l.translate('map_color_line')),
        ],
      ),
    );
  }
}


class _ZoomRange extends StatefulWidget {
  const _ZoomRange({
    required this.setting,
    this.trailing,
    this.inlineLabel,
    this.showSwitch = true,
    this.barOnly = false,
    this.titleChars,
  });
  final MapZoomSetting setting;
  final Widget? trailing;

  /// Slider and range only, for a row that already shows the name.
  final bool barOnly;

  /// When set, the range and its colour sit on one line under this label.
  final String? inlineLabel;

  final bool showSwitch;

  /// Fixed title width in characters when the zoom shows its own name.
  final int? titleChars;

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
    if (widget.barOnly) {
      return SizedBox(
        height: 28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [slider, const SizedBox(width: 12), value],
        ),
      );
    }
    if (inlineLabel != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showSwitch) _ElementSwitch(switchId),
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
    final title = Text(
      name,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final titleSlot = widget.titleChars == null
        ? Expanded(child: title)
        : _charsTitle(context, title, widget.titleChars!);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.showSwitch) _ElementSwitch(switchId),
              titleSlot,
            ],
          ),
          SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.showSwitch) const SizedBox(width: 41),
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

/// Width locked to [chars] character cells; short names keep the slot.
Widget _charsTitle(BuildContext context, Widget label, int chars) {
  final painter = TextPainter(
    text: TextSpan(
      text: '0' * chars,
      style: DefaultTextStyle.of(context).style,
    ),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return SizedBox(width: painter.width, child: label);
}

String _lineWidthLabel(double px) {
  final text = px == px.roundToDouble()
      ? px.toStringAsFixed(0)
      : px.toStringAsFixed(1);
  return '$text px';
}

class _LineTypeMenu extends StatelessWidget {
  const _LineTypeMenu({required this.id, this.width});

  final String id;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final type = MapChartSettings.instance.lineType(id);
    final style = Theme.of(context).textTheme.bodySmall;
    final button = PopupMenuButton<ChartLineType>(
      tooltip: l.translate('map_line_type'),
      padding: EdgeInsets.zero,
      initialValue: type,
      onSelected: (next) => MapChartSettings.instance.setLineType(id, next),
      itemBuilder: (context) => [
        for (final choice in ChartLineType.choices)
          PopupMenuItem<ChartLineType>(
            value: choice,
            height: 32,
            child: Text(l.translate(choice.labelKey), style: style),
          ),
      ],
      child: Row(
        mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (width == null)
            Text(l.translate(type.labelKey), style: style)
          else
            Expanded(
              child: Text(
                l.translate(type.labelKey),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
    final slot = width;
    if (slot == null) return button;
    return SizedBox(width: slot, child: button);
  }
}

class _LineWidthMenu extends StatelessWidget {
  const _LineWidthMenu({required this.id, this.width});

  final String id;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = l.translate('map_line_width');
    final value = MapChartSettings.instance.linePx(id);
    final style = Theme.of(context).textTheme.bodySmall;
    final button = PopupMenuButton<double>(
      tooltip: name,
      padding: EdgeInsets.zero,
      initialValue: value,
      onSelected: (next) => MapChartSettings.instance.setLinePx(id, next),
      itemBuilder: (context) => [
        for (final px in MapChartSettings.lineWidthChoices)
          PopupMenuItem<double>(
            value: px,
            height: 32,
            child: Text(_lineWidthLabel(px), style: style),
          ),
      ],
      child: Row(
        mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (width == null)
            Text(_lineWidthLabel(value), style: style)
          else
            Expanded(
              child: Text(
                _lineWidthLabel(value),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
    final slot = width;
    if (slot == null) return button;
    return SizedBox(width: slot, child: button);
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.setting,
    this.swatchesOnly = false,
    this.lineWidthId,
    this.zoomId,
    this.titleChars,
  });

  final bool swatchesOnly;

  final MapColorSetting setting;

  /// When set, the line-width menu sits beside this row's colours.
  final String? lineWidthId;

  /// Zoom slider drawn between the name and the line-width menu.
  final String? zoomId;

  /// Fixed title width, in characters. Short names keep the slot; longer
  /// names end in an ellipsis.
  final int? titleChars;

  @override
  Widget build(BuildContext context) {
    final day = MarinePalette.of(Brightness.light);
    final night = MarinePalette.of(Brightness.dark);
    final line = _linePartner(setting);
    // Land detail rows always reserve line-type / line-width slots.
    final reserveLineMenus = titleChars != null;
    final showLineMenus =
        lineWidthId != null && _hasLineStrokeControls(setting.field);
    final typeWidth = reserveLineMenus || showLineMenus
        ? _lineTypeSlotWidth(context)
        : null;
    final widthWidth = reserveLineMenus || showLineMenus
        ? _lineWidthSlotWidth(context)
        : null;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: swatchesOnly ? 0 : 1),
      child: Row(
        children: [
          if (!swatchesOnly) ...[
            _ElementSwitch(_elementIdForColor(setting.field)),
            if (zoomId == null)
              titleChars == null
                  ? Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.translate(setting.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : _charsTitle(
                      context,
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.translate(setting.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      titleChars!,
                    )
            else ...[
              titleChars == null
                  ? Text(
                      AppLocalizations.of(context)!.translate(setting.labelKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : _charsTitle(
                      context,
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.translate(setting.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      titleChars!,
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: _ZoomRange(
                  setting: _zoomSetting(zoomId!),
                  showSwitch: false,
                  barOnly: true,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ],
          if (reserveLineMenus || showLineMenus) ...[
            SizedBox(
              width: typeWidth,
              child: showLineMenus
                  ? _LineTypeMenu(id: lineWidthId!, width: typeWidth)
                  : null,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: widthWidth,
              child: showLineMenus
                  ? _LineWidthMenu(id: lineWidthId!, width: widthWidth)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // Fill day/night always keep the same width; line-only rows stay empty.
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
      'equator' => chart.equator,
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
  late Color _fill = widget.fill;
  late Color? _line = widget.line;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fillName = _line == null
        ? (widget.singleRole == null ? null : l.translate(widget.singleRole!))
        : l.translate('map_color_fill');
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fillName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(fillName),
                ),
              _ToneEditor(
                color: _fill,
                onChanged: (next) => setState(() => _fill = next),
              ),
              if (_line != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(l.translate('map_color_line')),
                ),
                _ToneEditor(
                  color: _line!,
                  onChanged: (next) => setState(() => _line = next),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.translate('map_cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _PaintColors(_fill, _line)),
          child: Text(l.translate('map_save')),
        ),
      ],
    );
  }
}

class _ToneEditor extends StatefulWidget {
  const _ToneEditor({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ToneEditor> createState() => _ToneEditorState();
}

class _ToneEditorState extends State<_ToneEditor> {
  late final TextEditingController _hex = TextEditingController(
    text: _hexText(widget.color),
  );
  final FocusNode _hexFocus = FocusNode();

  @override
  void didUpdateWidget(_ToneEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _hexText(widget.color);
    if (!_hexFocus.hasFocus && _hex.text != text) _hex.text = text;
  }

  @override
  void dispose() {
    _hex.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  HSVColor get _hsv => HSVColor.fromColor(widget.color);

  void _paint(HSVColor hsv, double alpha) {
    widget.onChanged(hsv.toColor().withValues(alpha: alpha.clamp(0, 1)));
  }

  void _fromHex(String raw) {
    final parsed = _parseHex(raw);
    if (parsed == null) return;
    widget.onChanged(parsed);
  }

  void _step(int delta) {
    final argb = widget.color.toARGB32();
    final rgb = (argb & 0xFFFFFF) + delta;
    final next = rgb.clamp(0, 0xFFFFFF);
    final alpha = (argb >> 24) & 0xFF;
    widget.onChanged(Color((alpha << 24) | next));
  }

  Future<void> _sample() async {
    final hex = await pickScreenHex();
    if (!mounted || hex == null) return;
    final parsed = _parseHex(hex);
    if (parsed == null) return;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final hsv = _hsv;
    final alpha = widget.color.a;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SvPlane(hsv: hsv, onChanged: (next) => _paint(next, alpha)),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              tooltip: 'Pick from the screen',
              visualDensity: VisualDensity.compact,
              onPressed: _sample,
              icon: const Icon(Icons.colorize, size: 20),
            ),
            _PreviewDot(color: widget.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  _HueBar(
                    hue: hsv.hue,
                    onChanged: (hue) => _paint(hsv.withHue(hue), alpha),
                  ),
                  const SizedBox(height: 8),
                  _AlphaBar(
                    color: hsv.toColor(),
                    alpha: alpha,
                    onChanged: (next) => _paint(hsv, next),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _hex,
          focusNode: _hexFocus,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepButton(
                  icon: Icons.keyboard_arrow_up,
                  onTap: () => _step(1),
                ),
                _StepButton(
                  icon: Icons.keyboard_arrow_down,
                  onTap: () => _step(-1),
                ),
              ],
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.primary),
            ),
          ),
          onChanged: _fromHex,
          onSubmitted: _fromHex,
        ),
        const SizedBox(height: 4),
        Text(
          'HEX',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Icon(icon, size: 16));
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _CheckerPainter(),
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _SvPlane extends StatelessWidget {
  const _SvPlane({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  void _take(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = (1 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return SizedBox(
      height: 150,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onPanDown: (details) => _take(details.localPosition, size),
            onPanUpdate: (details) => _take(details.localPosition, size),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: [Colors.white, hue]),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: (hsv.saturation * size.width - 7).clamp(
                        0.0,
                        size.width - 14,
                      ),
                      top: ((1 - hsv.value) * size.height - 7).clamp(
                        0.0,
                        size.height - 14,
                      ),
                      child: IgnorePointer(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  static final _colors = [
    for (var step = 0; step <= 12; step++)
      HSVColor.fromAHSV(1, step * 30, 1, 1).toColor(),
  ];

  @override
  Widget build(BuildContext context) {
    return _SlideBar(
      fraction: hue / 360,
      onChanged: (fraction) => onChanged(fraction * 360),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(colors: _colors),
        ),
      ),
    );
  }
}

class _AlphaBar extends StatelessWidget {
  const _AlphaBar({
    required this.color,
    required this.alpha,
    required this.onChanged,
  });

  final Color color;
  final double alpha;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SlideBar(
      fraction: alpha,
      onChanged: onChanged,
      child: CustomPaint(
        painter: _CheckerPainter(cell: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0), color.withValues(alpha: 1)],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideBar extends StatelessWidget {
  const _SlideBar({
    required this.fraction,
    required this.onChanged,
    required this.child,
  });

  final double fraction;
  final ValueChanged<double> onChanged;
  final Widget child;

  void _take(Offset local, double width) {
    onChanged((local.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onPanDown: (details) => _take(details.localPosition, width),
            onPanUpdate: (details) => _take(details.localPosition, width),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: child),
                Positioned(
                  left: (fraction.clamp(0.0, 1.0) * width - 8).clamp(
                    0.0,
                    width - 16,
                  ),
                  top: -1,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter({this.cell = 6});

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFBDBDBD);
    final dark = Paint()..color = const Color(0xFF8D8D8D);
    canvas.drawRect(Offset.zero & size, light);
    for (var y = 0.0; y < size.height; y += cell) {
      for (
        var x = (y / cell).floor().isEven ? cell : 0.0;
        x < size.width;
        x += cell * 2
      ) {
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => oldDelegate.cell != cell;
}

String _hexText(Color color) {
  final argb = color.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final alpha = (argb >> 24) & 0xFF;
  if (alpha == 0xFF) return '#$rgb';
  return '#$rgb${alpha.toRadixString(16).padLeft(2, '0')}';
}

Color? _parseHex(String raw) {
  var text = raw.trim();
  if (text.startsWith('#')) text = text.substring(1);
  if (text.length == 3 || text.length == 4) {
    text = text.split('').map((char) => '$char$char').join();
  }
  final String argb;
  if (text.length == 6) {
    argb = 'ff$text';
  } else if (text.length == 8) {
    argb = '${text.substring(6)}${text.substring(0, 6)}';
  } else {
    return null;
  }
  final value = int.tryParse(argb, radix: 16);
  if (value == null) return null;
  return Color(value);
}
