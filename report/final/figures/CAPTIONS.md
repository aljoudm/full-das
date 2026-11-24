# Figure captions (all SIMULATED unless stated)

* `twin3d_overview_light.png` : 3D digital twin, whole boundary, white background (report). SIMULATED intruders of the Stage 9 siting run, medium scenario; six interrogators (green edge = at an entrance checkpoint).  Source file: `report/figures/twin3d_overview_light.png`
* `twin3d_overview_dark.png` : Same, black background (presentation).  Source file: `report/figures/twin3d_overview_dark.png`
* `twin3d_zoom_hot_light.png` : 3D zoom on a Hot stretch north-east of Makkah (24 km of boundary), white background.  Source file: `report/figures/twin3d_zoom_hot_light.png`
* `twin3d_zoom_hot_dark.png` : Same, black background.  Source file: `report/figures/twin3d_zoom_hot_dark.png`
* `siting_map_medium.png` : 2D map of the interrogator siting (d* = 14.75 km, N_min = 5, N = 6): candidates, chosen shelters, boundary coloured by the serving shelter. Same result in low and high.  Source file: `results/siting/siting_map_medium.png`
* `pd_curve.png` : Pd against the optical distance with the monotone fit and its 95 % limits; d* = 14.75 km. SIMULATED.  Source file: `results/siting/pd_curve.png`
* `stage9_before_after.png` : Stage 9 before / after the siting model (medium): DAS misses by distance, Pd, Pd x Pc, verified in T_resp, patrol reached. SIMULATED, same random numbers.  Source file: `report/figures/stage9_before_after.png`
* `reid_accuracy_vs_spacing.png` : Re-identification (DAS <-> camera) accuracy against the spacing of people (Yomna's protocol, SIMULATED).  Source file: `results/reid/accuracy_vs_spacing.png`

The 3D figures are 1895 px wide (16 cm at 300 dpi); imagery attribution is printed on each. Made by `scripts/stage9_figures3d.m`, `scripts/final_stage9_chart.m`, `src/siting/siting_report.m`, `scripts/siting_pd_analyze.m`.
