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

Group labels remain visible from zoom 2 through the full zoom-8 band (hidden
at zoom 9). They are not suppressed by collisions with other map labels.
On web, MapLibre fetches the GeoJSON assets directly to avoid transferring
Dart-backed data objects to its workers.
