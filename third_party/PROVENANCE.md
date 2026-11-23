# Provenance of third_party/ (READ-ONLY copies; never edit, re-copy from the source repo)

| Folder | Source repo | Commit | Date | Notes |
| --- | --- | --- | --- | --- |
| `optimization/src`, `optimization/inputs` | https://github.com/aljoudm/optimization | `f51b2236d3eed2399c742c4c9318d2ea869972b1` | 2026-11-22 | FROZEN here (project lead decision 22 Nov 2026; replaces the earlier bbce36a, the difference is map drawing only). Byte-for-byte copy of `src/` and `inputs/dasmap/`. `run_optimization` reads the parameter table of **full-das** (`config/parameters_reviewed.tsv`) through `src/load_params_fd.m`, not the table of the source repo. |
| `dasmap_data/` | https://github.com/aljoudm/DAS-map- | `a25fd0c049b885904fc58288d21ea3840e9f0427` | 2026-11-15 | `results_zones/cells.csv`, `zones.mat`, `data/boundary_perimeter.csv`, `roads_osm.{mat,json}`, `holy_sites.csv`, plus `zone_classify.m`, `map_params.m`, `intrinsic_risk_grid.m`, `main_zones.m` (for re-computing the per-cell lambda). Same commit as `optimization/inputs/dasmap` (checked by `tests/test_stage0.m`). |
| `das_engine/` | https://github.com/aljoudm/DAS-Simulation | `3a8862b2c77bca9c638bed08fe799cb36cc7171e` | 2026-11-15 | `src/*.m` (phi-OTDR engine, FEBUS A1-NEO parameters in `das_params.m`). Wrappers live in `src/das/`, the engine files are not edited. |
| `yomna_das_height/` | https://github.com/Engyom/DAS- (git submodule) | tag `v2.2-sim` = `285b5ad1e76b4f1f55c539caef30626277ea8783` | 2026-11-22 | Height / gait estimation (SIMULATED data only). Used only through `das_height_v2/integration/bridge.py: estimate_height`; its `classify_event` / `profile_person` are stubs and are NOT used. |
| `OTDR-` (not copied) | https://github.com/aljoudm/OTDR- | `8d7331cfb61faf803634a3b0d0fc5dc5c093cb8c` | 2026-11-15 | Simulink model, used only as a physical sanity check of the DAS engine (trace slope 0.400 dB/km, resolution 10.2 m, alias). |

## Data outside git history
* `data/dem/dem_aoi.mat` (6.8 MB): Copernicus DEM GLO-30 (AWS Open Data `copernicus-dem-30m`, tiles N21 E039 and N21 E040), cropped by DAS-map `prepare_terrain.m` to the boundary bounding box +/- 0.05 deg. Copied from the local DAS-map run (2026-11-01). Attribution wording: see DAS-map `data/SOURCES.md` (adapted GLO-30 data). It is a DSM (includes buildings).
* OSM data: `third_party/dasmap_data/roads_osm.*` (fetched by DAS-map) and `data/osm/` (tracks, unclassified roads, urban landuse / place, fetched 2026-11-22, see `data/osm/README.md`): osm_contributors, ODbL. Each fetch is stored with its date.

## Table
`config/parameters_reviewed.tsv` started as a copy of `optimization/parameters_reviewed.tsv` at f51b223 and is now THE single parameter table of full-das (10th column `value_type`, rows added 22 Nov 2026 are tagged `[full-das 2026-11-22]`).

## 3D rendering style (added 24 Nov 2026)
| Folder | Source | Commit | Notes |
| --- | --- | --- | --- |
| `dasmap_viz/set_camera.m`, `dasmap_viz/draw_terrain.m` | https://github.com/aljoudm/DAS-map- (`set_camera.m`, `draw_terrain.m`) | `a25fd0c049b885904fc58288d21ea3840e9f0427` | Byte-for-byte copies (the oblique perspective camera and the textured terrain surface of the DAS-map digital twin). `src/viz/draw_twin3d.m` follows the same style (satellite texture draped on the Copernicus DEM, vertical exaggeration 2, perspective camera, fibre lifted above a ridge-dilated mesh); `config.m` of DAS-map was read, not copied. |
| `data/imagery/esri_zoom_hot_nw.jpg` | crop of DAS-map `data/dem/tex_base.jpg` (Esri World Imagery export made by `prepare_terrain.m` on 2026-11-01, not tracked in the DAS-map repo) | a25fd0c (script) | Higher-resolution crop (about 6 m/px) used only by the zoomed 3D view. Attribution: Esri, Vantor, Earthstar Geographics, and the GIS User Community (terms still to be confirmed, see `data/imagery/README.md`). |

## Interrogator siting (added 23 Nov 2026)
| Folder | Source | Commit | Notes |
| --- | --- | --- | --- |
| `optimization_siting/` | https://github.com/aljoudm/optimization, branch `interrogator-siting` (main untouched) | `42eadb75f7922d71c3911086d34a25d4dc131063` (was d39f6b7 until the optional Nfix test option was added) | Byte-for-byte copy of `src/` and `inputs/` of the branch: MILP with candidate shelter sites (lead-in fibre, reach d* - lead-in), analytic N_min, lexicographic stages 2b/2c. Without the `Siting` option it gives the results of f51b223 (tests/test_siting_equivalence.m: low, medium). Pushed 23 Nov 2026. |
