# full-das: unified digital-twin simulation (DAS perimeter security, Makkah / Hajj)

One MATLAB simulation of the capstone *AI-Based Distributed Optical Fiber Sensing (DAS) Network for Autonomous Perimeter Security and
Real-Time Intruder Detection and Tracking: Hajj Season Use Case* (PNU). Everything happens on one map (the digital twin): zones, the
optimized allocation, intruders, DAS detection, drone/camera cueing, AI identification and tracking until a patrol responds.
DAS is the only new infrastructure; cameras, drones and patrols already exist. The AI is a **stub** (TEMPORARY) until the real one is plugged in
through `ai/` (one setting: `use_real_ai`).

> Status: **Stage 0-2 in progress.** Stages are pushed one by one; see `report/` for decisions, key numbers, assumptions and figures.

## Run
```matlab
main            % runs everything from start to end (grows stage by stage)
```
Tests: `run('tests/test_stage0.m')` etc. All values come from `config/parameters_reviewed.tsv` (the only parameter table; column `value_type`
= source / assumption / derived / placeholder / proxy / tbd).

## Requirements
* MATLAB R2026a. Toolboxes: **Optimization** (`intlinprog`), **Mapping**, **Image Processing**, **Statistics and Machine Learning**,
  **Signal Processing**, **Sensor Fusion and Tracking** (tracking stage). The development machine had a *trial* licence, so the optimized
  allocation of each scenario is saved in `results/alloc_<scenario>.mat` and can be loaded without re-solving.
* Python 3.13 for the AI part, called with `pyenv(Version="3.13", ExecutionMode="OutOfProcess")`.
* `git clone --recurse-submodules https://github.com/aljoudm/full-das` (the height-estimation code is the submodule `third_party/yomna_das_height`, tag `v2.2-sim`).

## DEM (terrain)
`data/dem/dem_aoi.mat` (6.8 MB) is in the repo. To rebuild it: Copernicus DEM GLO-30 (`copernicus_dem_glo30`, 1 arc-second, about 30 m), AWS Open Data bucket
`copernicus-dem-30m`, tiles `Copernicus_DSM_COG_10_N21_00_E039_00_DEM.tif` and `..._E040_00_DEM.tif`
(`https://copernicus-dem-30m.s3.amazonaws.com/<tile>/<tile>.tif`), cropped to the boundary bounding box (`data/boundary_perimeter.csv`) plus 0.05 deg margin,
saved as `Z` (single), `lat`, `lon`. The crop code is `prepare_terrain.m` in DAS-map. It is a DSM (includes buildings). Attribution: see `third_party/PROVENANCE.md`.

## Layout
```
main.m                 one entry point
config/                parameters_reviewed.tsv (single table), sim_config.m
third_party/           frozen copies of the source repos + PROVENANCE.md (never edited)
src/{twin,alloc,intruders,das,ai,response,tracking,metrics,viz}
ai/                    Python side of the AI (ai_real.py, same signatures as the stub)
tests/  results/  report/
```
Source repos (read only): aljoudm/DAS-map-, aljoudm/optimization, aljoudm/DAS-Simulation, aljoudm/OTDR-, Engyom/DAS-.

## Brno DAS dataset (classifier training; NOT in git)
* Source: Tomasov et al., figshare DOI 10.6084/m9.figshare.27004732, CC BY (paper: https://doi.org/10.1038/s41597-025-05088-4). File `DAS-dataset.zip`, **47,120,418,495 bytes**, **MD5 77e990a08907c2a4b16997e95f31b55e**, direct link `https://ndownloader.figshare.com/files/52736258`.
* Keep it OUTSIDE the project (the project is inside OneDrive): `C:\data\das_brno`. The Python environment is in `C:\data\venv_das`.
* The zip holds 9 label folders; each has long raw recordings (`*.h5`, 1 to 5.7 GB) plus a small bitmap (`*.npy`) and `*.json` saying which windows carry the label (about 18 MB for all bitmaps).
  `ai/zip_remote.py` reads the zip over HTTP range requests, so the small files and only the needed parts of selected recordings can be fetched without downloading 47 GB
  (`python -I ai/zip_remote.py list`, `... get <member> <out_dir>`). A full download is possible with `curl -L -C - -o DAS-dataset.zip <link>` (about 0.5 MB/s per stream here, many hours); verify with the MD5 above.
* The dataset's own `python/` loader is GPL-3.0; full-das does not copy it (own implementation in `ai/`).
