# OSM data fetched for the intruder model (source: osm_contributors, ODbL, https://www.openstreetmap.org/copyright)

Fetched **2026-11-22** (OSM base timestamp 2026-11-22T11:58:21Z) from the Overpass API (https://overpass-api.de), bounding box lat 21.2625 to 21.5828, lon 39.5789 to 40.0619 (the DEM extent).
* `osm_tracks_unclassified_2026-11-22.json`: ways `highway=track|unclassified` with geometry (126 tracks, 814 unclassified). Proxy for dirt / minor roads: OSM does not tag the surface consistently.
* `osm_urban_landuse_place_2026-11-22.json`: `landuse=residential|commercial|industrial|retail|construction` ways and `place=neighbourhood|suburb|quarter|village|hamlet|town` ways and nodes (centre point + tags). Proxy for built-up areas.
Re-fetching gives a newer map; the date in the file name says which one a result used.
