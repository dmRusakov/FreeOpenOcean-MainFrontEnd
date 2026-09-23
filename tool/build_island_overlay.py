"""Build the low-zoom overlay from Natural Earth 10m land and minor islands.

Usage: python3 tool/build_island_overlay.py land.geojson minor_islands.geojson
See assets/maps/README.md for sources and limitations.
"""
import json
import math
from pathlib import Path
import sys

polygons = []
for source in sys.argv[1:]:
    for feature in json.loads(Path(source).read_text())["features"]:
        geometry = feature["geometry"]
        polygons.extend(geometry["coordinates"] if geometry["type"] == "MultiPolygon"
                        else [geometry["coordinates"]])

shapes, points = [], []
for polygon in polygons:
    ring = polygon[0]
    area = abs(sum((b[0] - a[0]) * (2 + math.sin(math.radians(a[1]))
                   + math.sin(math.radians(b[1]))) for a, b in zip(ring, ring[1:])))
    area *= math.pi / 180 * 6371 ** 2 / 2
    # Continents stay on the basemap. Islands of about 150 km² and up keep
    # the Protomaps landcover (vegetation green and urban gray) instead of a
    # flat earth fill. Samos-sized islands (up to about 600 km²) still get a
    # marker so they stay visible at every zoom, including world view, where
    # the basemap drops them.
    if area > 3_000_000:
        continue
    coordinates = [[[round(x, 5), round(y, 5)] for x, y in r] for r in polygon]
    if area < 150:
        shapes.append({"type": "Feature", "properties": {}, "geometry": {
            "type": "Polygon", "coordinates": coordinates}})
    if area < 600:
        # Anchor on the coastline: a polygon centroid may lie in open water.
        points.append({"type": "Feature", "properties": {"dotUntil": 24},
                       "geometry": {"type": "Point", "coordinates": coordinates[0][0]}})

output = Path(__file__).resolve().parents[1] / "assets/maps"
output.mkdir(parents=True, exist_ok=True)
for name, features in [("island_shapes", shapes), ("island_points", points)]:
    (output / f"{name}.geojson").write_text(json.dumps(
        {"type": "FeatureCollection", "features": features}, separators=(",", ":")))
print(f"Built {len(shapes)} island polygons and visibility markers")
