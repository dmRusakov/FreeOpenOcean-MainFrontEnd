# Island visibility overlay

Public-domain Natural Earth 1:10m land and minor-island polygons:

- https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_land.geojson
- https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_minor_islands.geojson
- License: https://www.naturalearthdata.com/about/terms-of-use/

Generated with `tool/build_island_overlay.py`. Coordinates are rounded to five
decimal places. Continental polygons larger than 3 million square kilometres
are excluded. Islands of 150 km² and larger keep the Protomaps landcover
(vegetation green and urban gray) on Cuba, the Bahamas, and other islands of
that size. Islands up to about 600 km², including Samos and the smaller Fiji
islands, also get a coastline marker. Shapes and markers stay drawn at every
zoom.

These are generalized overview shapes, not survey-grade coastlines or an
exhaustive inventory of every rock/islet. A hillshade from AWS Terrain Tiles
covers the basemap land at every zoom. The same shade is drawn over the ocean
until zoom 11, then the water returns to a flat color.

`island_groups.geojson` labels open-ocean groups used for passagemaking
(Canary Islands, Azores, Madeira, Galápagos Islands, and the other groups
offshore). Islands along a continental coast are omitted. Country names
already drawn by the basemap, such as Cabo Verde, are not repeated.
