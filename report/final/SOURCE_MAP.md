# Source map: every headline number, its value (read from the file when this was built), its tag and where it comes from

Part A: **every parameter** is in `parameters_final.tsv` / `parameters_final.md` (symbol, value, unit, status, source). Status tags: sourced, ASSUMED, PLACEHOLDER, SIMULATED, DERIVED. Arabic statuses of the original table: مفترض = assumed, مفترض (مبني على مصدر) = assumed from a source, معتمد = approved, مقترح / اقتراح = proposed, مبدئي = preliminary. Nothing is untagged (checked by this script).
Part B: the result numbers below. The value column is read programmatically from the file in the third column; to refresh everything run `python scripts/make_final_package.py`.

## Part B: results
| Number | Value | Tag | File | Script / how |
| --- | --- | --- | --- | --- |
| Boundary length | 145.5 km (table, rounded); exact ring 145.4735 km | sourced (OSM boundary) | `config/parameters_reviewed.tsv` row `L_boundary` | DAS-map `boundary_perimeter.csv` (a25fd0c); planar ring 145,461 m vs haversine 145,473.5 m |
| Pd_DAS (literature, used by the optimization) | 0.969 | مفترض (مبني على مصدر) | table row `Pd_DAS` | zeng2024: IDR = 96.9% (موقع مزعج)؛ liu2016: 100% ميداني |
| Pc_DAS (classifier accuracy, base stub) | 0.983 – 0.993 | مفترض (مبني على مصدر) | table row `Pc_DAS` | wang2024 (عبر مراجعة Shao 2025): 99.3% بنقطة إزعاج وحدة، و98.3% مع أكثر من نقطة |
| d* (reach of one interrogator) | 14.75 km | SIMULATED (rule fixed before the run) | `results/siting/d_star.json`; table row `d_star_DAS`; rule in row `siting_dstar_rule` | `scripts/siting_pd_dense.m` (windows) then `scripts/siting_pd_analyze.m` (isotonic fit, 2000 bootstrap, lower 95 % limit >= Pd_DAS); engine third_party/das_engine 3a8862b |
| d* under the weakest-type rule (information) | 13 km | SIMULATED | `results/siting/d_star.json`, `results/siting/dstar_rule_table.csv` | same script, per-type fits |
| N_min = ceil(L / 2d*) | 5 | DERIVED | `results/siting/d_star.json` | ceil(145.47 / 29.5) |
| N from the MILP with candidate shelters | 6 (low, medium and high identical) | SIMULATED (MILP) | `results/siting/cost_with_shelters.csv`; `results/alloc_<scenario>_22_siting.mat` | `src/siting/get_allocation_siting.m` -> optimization repo branch `interrogator-siting` 1b385aa (copy `third_party/optimization_siting`) |
| Chosen sites (boundary arc, km) | 108.89 (road), 58.44 (road), 85.95 (checkpoint), 8.70 (checkpoint), 29.58 (checkpoint), 125.19 (checkpoint) | SIMULATED (MILP) | `results/siting/siting_sites_medium.csv` | `src/siting/siting_report.m` |
| New-cabin cost C_shelter | 120,000 SAR | PLACEHOLDER | table row `C_shelter` | no Saudi price found (24 Nov 2026 search); replace by a quotation |
| Checkpoint-room cost C_shelter_checkpoint | 30,000 SAR | ASSUMED | table row `C_shelter_checkpoint` | 25 % of C_shelter |
| Shelter cost of the siting solution | 360,000 SAR (4 checkpoint rooms + 2 new cabins) | DERIVED | `results/siting/cost_with_shelters.csv` | `scripts/siting_cost_table.m` |
| C_total, siting model | 13,014,986 SAR | SIMULATED (MILP) | `results/siting/cost_with_shelters.csv`; table row `C_total_siting` | interrogators 3,816,000 + sensing fibre 8,829,506 + lead-in 9,480 + shelters 360,000; C_DAS_int 636,000, C_fiber 60700 per km (table) |
| C_total, main model (4 interrogators, no shelter cost) | 11,373,506 SAR | SIMULATED (frozen MILP f51b223) | `results/stage9_siting/comparison.csv` column C_total; `tests/test_stage2.m` | reproduces optimization/report/key_results.md; computed with C_shelter = 0 |
| Cabin price sensitivity (50,000 / 120,000 / 300,000 SAR) | 12,774,986 / 13,014,986 / 13,854,986 SAR, same N and sites | SIMULATED (MILP re-solved) | `results/siting/cost_with_shelters.csv` (cases medium_shello, medium_shelhi) | `scripts/siting_run_scn.m` with env SHEL, SHELCHK |
| N = 5 forced | C_total 12,285,758 SAR; 4 cells (135 of 139 with DAS) uncovered | SIMULATED (MILP, Nfix = 5) | `results/siting/cost_with_shelters.csv`; `results/alloc_medium_22_siting_N5.mat` | `Siting.Nfix` option; difference to N = 6: 729,228 SAR |
| d* = 13 km (weakest-type rule) | N = 7, C_total 13,963,473 SAR | SIMULATED (MILP) | `results/siting/cost_with_shelters.csv` (case medium_d13) | `scripts/siting_run_scn.m` DSTAR=13 |
| Eight siting sensitivities (slope / road / waterway / inside distance) | N = 6 in all; C_total 13,014,814 to 13,015,748 SAR (+ base) | SIMULATED (MILP) | `results/siting/cost_with_shelters.csv`, `results/siting/sensitivity.csv` | `scripts/run_siting_sens.sh`, `scripts/siting_sens_table.m`; solved with C_shelter = 0, site kinds identical so the shelter cost is added from the kinds |
| Shelter air-conditioning power / energy | 170 W per cabin; 1,489.2 kWh/yr per cabin; six cabins 8,935 kWh/yr; whole site draw 2,040 W | sourced range (gsma_coolsure 30-50 %) / DERIVED | table rows `P_shelter`, `E_shelter_cooling_kWh_yr`, `cooling_share_of_site_load`; `results/siting/cost_with_shelters.csv` | 170 W x 8,760 h |
| Pd of the simulated DAS chain, medium: before -> after the siting model | 95.8 % -> 99.6 % | SIMULATED (Monte Carlo, 394 days, 10,004 intruders, common random numbers) | `results/stage9_siting/comparison.csv` | `scripts/stage9_run.m`, `scripts/stage9_compare.m`, `scripts/make_stage9_comparison.py` |
| Pd x Pc (end to end), medium: before -> after the siting model | 94.2 % -> 97.9 % | SIMULATED (Monte Carlo, 394 days, 10,004 intruders, common random numbers) | `results/stage9_siting/comparison.csv` | `scripts/stage9_run.m`, `scripts/stage9_compare.m`, `scripts/make_stage9_comparison.py` |
| Intruders verified within T_resp, medium: before -> after the siting model | 37.1 % -> 39.0 % | SIMULATED (Monte Carlo, 394 days, 10,004 intruders, common random numbers) | `results/stage9_siting/comparison.csv` | `scripts/stage9_run.m`, `scripts/stage9_compare.m`, `scripts/make_stage9_comparison.py` |
| Patrol reached, medium: before -> after the siting model | 84.5 % -> 87.6 % | SIMULATED (Monte Carlo, 394 days, 10,004 intruders, common random numbers) | `results/stage9_siting/comparison.csv` | `scripts/stage9_run.m`, `scripts/stage9_compare.m`, `scripts/make_stage9_comparison.py` |
| Intruders NOT verified within T_resp (medium), before -> after | 62.9 % -> 61.0 % | SIMULATED | `results/stage9_siting/comparison.csv` (1 - verified_Tresp) | includes DAS misses and classifier non-alarms; T_resp = 300 s (table) |
| DAS miss share 10-14.75 km, before -> after | 5.8 % -> 1.16 % | SIMULATED | `results/stage9_siting/comparison_by_distance.csv` | no event farther than 14.23 km after the change |
| DAS miss share 15-20 km (before) | 12.2 % | SIMULATED | `results/stage9_siting/comparison_by_distance.csv` |  |
| Height measurable, all intruders (p_along 10 %) | 4.1 % (walkers 8.3 %) | SIMULATED; p_along ASSUMED | `results/stage7_height_share.csv` | `scripts/stage7_height_share.m`; height model (Engyom/DAS- v2.2-sim) NOT called, only its conditions |
| Group sensitivity p_group 25 % / 50 % (persons) | 16,089 / 22,547 persons for 10,004 events | SIMULATED; p_group ASSUMED | `results/stage9_siting/metrics_summary.csv` |  |
| Brno confusion matrix (SENSITIVITY only): Pc given detection | 58.4 % (base uniform stub 98.3 %) | SIMULATED; matrix from published dataset | `results/stage9_siting/metrics_summary.csv`; `config/ai_config.json` | base = uniform stub from Pc_DAS (ASSUMED); the matrix is a sensitivity |
| Re-identification target 0.97 kept in the hard cells | NOT kept (see `report/reid_summary.md`) | SIMULATED, ASSUMED errors | `results/reid/summary.json`, `results/reid/reid_grid.csv` | 1296 cells x 300 scenes; design is Yomna's, run only through her protocol in `reid/` |
| Number of table rows with status PLACEHOLDER or TBD | 28 | - | `report/final/OPEN_ITEMS.md` | listed one by one |
| Not in this map: numbers of the AI summary | - | - | `report/final/ai_summary.md` | each has its own bib key (`report/references_additions.bib`) |
| Numbers of the Stages 1-9 text in key_numbers.md | see file | SIMULATED / DERIVED | `report/key_numbers.md` | each section names its test or script (`tests/test_stage1.m` ... `tests/test_stage6.m`, `scripts/`); re-running the test reproduces the value |

## Notes
* Costs: `results/stage9_siting/comparison.csv` still stores C_total = 12,654,986 for the siting model (the Stage 9 rerun was made before the shelter cost was added); the current cost is `results/siting/cost_with_shelters.csv` (13,014,986). The allocation did not change, so no Stage 9 result changed.
* All SIMULATED values depend on ASSUMED inputs (coupling spread, intruder rates, speeds); they are results of the model, not measurements. Phase 0 (field measurements) is where they would be replaced.
* Frozen sources: see `third_party/PROVENANCE.md` for every repository, commit and date.
