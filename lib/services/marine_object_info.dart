/// Details for a tapped marine object on the chart.
class MarineObjectInfo {
  const MarineObjectInfo({
    required this.title,
    required this.typeLabel,
    required this.sourceLabel,
    this.detail,
    this.operator,
    this.website,
    this.phone,
    this.category,
    this.ref,
    this.latitude,
    this.longitude,
    this.osmType,
    this.osmId,
    this.layerId,
  });

  final String title;
  final String typeLabel;
  final String sourceLabel;
  final String? detail;
  final String? operator;
  final String? website;
  final String? phone;
  final String? category;
  final String? ref;
  final double? latitude;
  final double? longitude;
  final String? osmType;
  final String? osmId;
  final String? layerId;

  /// OpenStreetMap object page when [osmType] and [osmId] are known.
  String? get osmUrl {
    final type = osmType;
    final id = osmId;
    if (type == null || type.isEmpty || id == null || id.isEmpty) return null;
    return 'https://www.openstreetmap.org/$type/$id';
  }

  /// Builds info from a MapLibre [queryRenderedFeatures] hit.
  static MarineObjectInfo? fromFeature(
    Map<String, dynamic> feature, {
    String? layerId,
    String Function(String kind)? typeLabelOf,
  }) {
    final props = _stringMap(feature['properties']);
    final geometry = _stringMap(feature['geometry']);
    final source = feature['source']?.toString() ?? '';
    final kind = _string(props['kind']) ?? _kindFromLayer(layerId);
    if (kind == null && layerId == null) return null;

    final name = _string(props['name']);
    final typeLabel = typeLabelOf?.call(kind ?? '') ??
        defaultTypeLabel(kind ?? layerId ?? '');
    final title = (name != null && name.isNotEmpty) ? name : typeLabel;

    final coords = geometry['coordinates'];
    double? lon;
    double? lat;
    if (coords is List && coords.length >= 2) {
      final first = coords[0];
      final second = coords[1];
      if (first is num && second is num) {
        lon = first.toDouble();
        lat = second.toDouble();
      }
    }
    lat ??= _num(props['lat']);

    return MarineObjectInfo(
      title: title,
      typeLabel: typeLabel,
      sourceLabel: _sourceLabel(source, props),
      detail: _string(props['detail']),
      operator: _string(props['operator']),
      website: _string(props['website']),
      phone: _string(props['phone']),
      category: _string(props['category']),
      ref: _string(props['ref']),
      latitude: lat,
      longitude: lon,
      osmType: _string(props['osm_type']),
      osmId: _string(props['osm_id']),
      layerId: layerId,
    );
  }

  static String defaultTypeLabel(String kind) {
    switch (kind) {
      case 'marina':
      case 'harbour':
      case 'boat-marinas':
      case 'seamark-marinas':
        return 'Marina';
      case 'anchorage':
      case 'boat-anchorages':
        return 'Anchorage';
      case 'fuel':
      case 'boat-fuel':
        return 'Fuel';
      case 'customs':
      case 'boat-customs':
        return 'Customs';
      case 'harbourmaster':
        return 'Harbour office';
      case 'naval_base':
      case 'boat-port':
        return 'Port';
      case 'ferry_terminal':
        return 'Ferry terminal';
      case 'cruise_terminal':
        return 'Cruise terminal';
      case 'ferry':
      case 'chart-ferry':
      case 'chart-ferry-labels':
        return 'Ferry route';
      case 'slipway':
      case 'slipways':
        return 'Slipway';
      case 'dock':
      case 'boat-dock':
        return 'Dock';
      case 'lighthouse':
      case 'lighthouses':
        return 'Lighthouse';
      case 'light_major':
        return 'Major light';
      case 'beacon':
        return 'Beacon';
      case 'boat':
      case 'boat-service':
        return 'Boat service';
      case 'boat_rental':
        return 'Boat rental';
      case 'boat_repair':
        return 'Boat repair';
      case 'boat_storage':
        return 'Boat storage';
      case 'ship_chandler':
        return 'Chandler';
      case 'life_ring':
        return 'Life ring';
      case 'lock':
        return 'Lock';
      case 'mooring':
        return 'Mooring';
      case 'small_craft_facility':
      case 'seamark-names':
        return 'Small craft';
      case 'offshore_platform':
      case 'oil-platforms':
      case 'oil-platform-zone':
        return 'Offshore oil platforms';
      case 'boat-places':
        return 'Marine object';
      default:
        return kind.replaceAll('_', ' ').replaceAll('-', ' ');
    }
  }

  static String? _kindFromLayer(String? layerId) {
    if (layerId == null) return null;
    switch (layerId) {
      case 'boat-marinas':
      case 'seamark-marinas':
        return 'marina';
      case 'boat-anchorages':
        return 'anchorage';
      case 'boat-fuel':
        return 'fuel';
      case 'boat-customs':
        return 'customs';
      case 'boat-port':
        return 'harbourmaster';
      case 'boat-service':
        return 'boat';
      case 'boat-dock':
        return 'dock';
      case 'slipways':
        return 'slipway';
      case 'lighthouses':
        return 'lighthouse';
      case 'oil-platforms':
      case 'oil-platform-zone':
        return 'offshore_platform';
      case 'chart-ferry':
      case 'chart-ferry-labels':
        return 'ferry';
      case 'seamark-names':
        return 'small_craft_facility';
      default:
        return null;
    }
  }

  static String _sourceLabel(String source, Map<String, dynamic> props) {
    final osmType = _string(props['osm_type']);
    final osmId = _string(props['osm_id']);
    if (source == 'protomaps') {
      return 'OpenStreetMap';
    }
    if (osmType != null && osmId != null) {
      return 'OpenStreetMap ($osmType/$osmId)';
    }
    if (source == 'seamark-names' ||
        source == 'slipways' ||
        source == 'oil-platforms' ||
        source == 'lighthouses') {
      return 'OpenStreetMap';
    }
    final explicit = _string(props['source']);
    if (explicit != null) return explicit;
    if (source.isNotEmpty) return source;
    return 'OpenStreetMap';
  }

  static Map<String, dynamic> _stringMap(dynamic value) {
    if (value is Map) {
      return {
        for (final entry in value.entries) entry.key.toString(): entry.value,
      };
    }
    return {};
  }

  static String? _string(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num) return value.toString();
    return null;
  }

  static double? _num(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
