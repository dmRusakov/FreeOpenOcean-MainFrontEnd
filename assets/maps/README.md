# Island visibility overlay

Public-domain Natural Earth 1:10m land and minor-island polygons:

- https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_land.geojson
- https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_minor_islands.geojson
- License: https://www.naturalearthdata.com/about/terms-of-use/

Generated with `tool/build_island_overlay.py`. Coordinates are rounded to five
decimal places. Continental polygons larger than 3 million square kilometres
are excluded. Small dots are anchored on each polygon's coastline and shown
only while its approximate size is below three pixels.

These are generalized overview shapes, not survey-grade coastlines or an
exhaustive inventory of every rock/islet. The overlay fades out at zooms 6–8,
where Protomaps supplies detailed coastlines. Do not extend these generalized
polygons to navigation-scale zooms.
