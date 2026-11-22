# Assumptions of the event model (all in `config/parameters_reviewed.tsv`, column value_type)
* Wadis come from the DEM (cell lower than its 300 m Gaussian mean by `wadi_depth_m` with a gentle floor): a PROXY, the 30 m DSM includes buildings and no wadi map exists.
* Dirt roads = OSM `highway=track|unclassified` (surface is not tagged, so this is a proxy); built-up = distance to the centre of an OSM urban area or place (centre points only, so the 1 km radius is coarse).
* Entry weights (x3 wadi, x2 track, x2 urban), type proportions per terrain class, speeds, durations, heading random walk and the non-intrusion rates are ASSUMED / PLACEHOLDER; none has a source.
* Intrusion arrival is uniform over the 24 h of a day (no night preference modelled).
* A trajectory ends 600 m inside (measured on the local normal) or after 1800 s; about 7 % of the walks leave the boundary polygon at concave bends.
