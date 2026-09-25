# Chart overlays

`island_points.geojson` marks islands under about 600 km², including Samos and
the smaller Fiji islands. Each dot sits on the coastline and stays drawn at
every zoom.

A hillshade from AWS Terrain Tiles covers the basemap land at every zoom. The
same shade is drawn over the ocean until zoom 11, then the water returns to a
flat color.

`island_groups.geojson` labels open-ocean groups used for passagemaking
(Canary Islands, Azores, Madeira, Galápagos Islands, and the other groups
offshore). Islands along a continental coast are omitted. Country names
already drawn by the basemap, such as Cabo Verde, are not repeated.

`maritime_boundaries.geojson` draws country limits on the water: the lines
between neighboring seas, treaty lines, and the 200-mile nautical limit.
They use the same dash and color as the land borders.

`island_names.geojson` repeats small-island names that Protomaps draws only
from zoom 6 or 7, including Umnak Island and Kanaga Island. Each name is
drawn from zoom 4 until the basemap label takes over.

Group labels remain visible from zoom 2 through the full zoom-8 band (hidden
at zoom 9). They are not suppressed by collisions with other map labels.
On web, MapLibre fetches the GeoJSON assets directly to avoid transferring
Dart-backed data objects to its workers.
