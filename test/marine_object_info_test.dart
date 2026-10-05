import 'package:flutter_test/flutter_test.dart';
import 'package:free_open_ocean/services/marine_object_info.dart';

void main() {
  test('parses OSM marine feature with source and osm link', () {
    final info = MarineObjectInfo.fromFeature(
      {
        'source': 'lighthouses',
        'geometry': {
          'type': 'Point',
          'coordinates': [-78.01, 33.88],
        },
        'properties': {
          'name': 'Bald Head Light',
          'kind': 'lighthouse',
          'detail': 'Fl W 10s',
          'source': 'OpenStreetMap',
          'osm_type': 'node',
          'osm_id': '12345',
          'operator': 'USCG',
        },
      },
      layerId: 'lighthouses',
    );

    expect(info, isNotNull);
    expect(info!.title, 'Bald Head Light');
    expect(info.typeLabel, 'Lighthouse');
    expect(info.detail, 'Fl W 10s');
    expect(info.operator, 'USCG');
    expect(info.sourceLabel, 'OpenStreetMap (node/12345)');
    expect(info.osmUrl, 'https://www.openstreetmap.org/node/12345');
    expect(info.latitude, closeTo(33.88, 0.0001));
  });

  test('labels OpenStreetMap marina source', () {
    final info = MarineObjectInfo.fromFeature(
      {
        'source': 'protomaps',
        'geometry': {
          'type': 'Point',
          'coordinates': [-78.0, 33.9],
        },
        'properties': {
          'name': 'Southport Marina',
          'kind': 'marina',
        },
      },
      layerId: 'boat-marinas',
    );

    expect(info, isNotNull);
    expect(info!.sourceLabel, 'OpenStreetMap');
    expect(info.typeLabel, 'Marina');
  });
}
