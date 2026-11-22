# Stage 8: system-level metrics (SIMULATED)

**SIMULATED.** 60 simulated days per case, seed 8080, 22 interdiction sites, 100 authorized vehicles per site per day (PLACEHOLDER), p_site_clear 0.99 (PLACEHOLDER), along-boundary walk p_along 0.10 (ASSUMED). 95 % intervals: bootstrap over DAYS (2,000 resamples; days are the independent units). Base classifier: temporary uniform stub, Pc 0.983 (ASSUMED, literature); the last column group is the **Brno confusion matrix as a SENSITIVITY only** ("Brno, 4 test recordings, SENSITIVITY"; classes without a row fall back to the uniform stub). Sources: `results/stage8/metrics_summary.csv`, `results/stage8/reid_in_simulation.csv`, code `src/metrics/`, `scripts/stage8_run.m`. This is a 60-day check of the metrics before the full Monte Carlo (Stage 9).

| Metric | low (3 drones) | medium (6) | high (12) | medium, Brno matrix (SENSITIVITY) |
| --- | --- | --- | --- | --- |
| Real intruders simulated | 1564 | 1610 | 1549 | 1502 |
| Pd: detected by the DAS | 96.7 % [95.8, 97.5] | 96.3 % [95.4, 97.1] | 95.7 % [94.4, 96.8] | 95.9 % [94.9, 96.8] |
| Pc: classified correctly, given detection | 98.2 % [97.5, 98.8] | 97.9 % [97.3, 98.4] | 97.9 % [97.2, 98.6] | 59.1 % [55.8, 62.3] |
| Pd x Pc: detected and classified correctly (end to end) | 94.9 % [93.9, 96.0] | 94.2 % [93.3, 95.1] | 93.7 % [92.2, 95.0] | 56.7 % [53.6, 59.8] |
| alarm raised (detected and classified as a threat; includes alerts routed to site guards) | 96.2 % [95.2, 97.0] | 95.5 % [94.6, 96.4] | 95.1 % [93.8, 96.3] | 80.9 % [78.2, 83.4] |
| verified within T_resp (300 s), all intruders | 19.4 % [17.5, 21.5] | 36.6 % [34.3, 39.0] | 68.0 % [65.6, 70.4] | 31.4 % [29.3, 33.7] |
| verified within T_resp, Hot-zone intruders only | 25.4 % [22.7, 28.1] | 48.9 % [45.9, 51.9] | 89.9 % [87.8, 91.5] | 41.7 % [38.5, 45.2] |
| verified within T_resp, of the intruders that raised an alarm | 20.2 % [18.3, 22.2] | 38.3 % [35.9, 40.8] | 71.6 % [69.2, 73.8] | 38.8 % [36.4, 41.4] |
| patrol reached (after a confirmed verification, any delay), all intruders | 66.5 % [64.4, 68.7] | 84.1 % [82.5, 85.7] | 84.4 % [82.2, 86.7] | 70.8 % [68.0, 73.5] |
| patrol reached, of the intruders that raised an alarm | 69.1 % [67.2, 71.3] | 88.0 % [86.4, 89.6] | 88.8 % [86.9, 90.5] | 87.5 % [85.8, 89.2] |
| height measurable (all intruders) | 3.5 % [2.7, 4.3] | 3.8 % [2.9, 4.7] | 4.3 % [3.3, 5.4] | 3.8 % [2.9, 4.9] |
| height measurable (of walkers) | 7.0 % [5.4, 8.6] | 7.5 % [5.8, 9.4] | 8.8 % [6.8, 10.8] | 7.6 % [5.9, 9.4] |
| median verification time, s (alarm to asset on scene) | 979 [923, 1051] | 501 [471, 543] | 224 [220, 227] | 485 [433, 523] |
| median alarm-to-patrol time, s | 1493 [1483, 1606] | 688 [634, 731] | 406 [402, 416] | 723 [681, 754] |
| false alarms before verification, drone- or camera-cued, per km per day | 0.318 [0.307, 0.330] | 0.325 [0.312, 0.338] | 0.323 [0.312, 0.335] | 6.958 [6.162, 7.746] |
| false alarms before verification, routed to site guards (low priority), per km per day | 17.761 [17.659, 17.856] | 17.612 [17.529, 17.701] | 17.920 [17.825, 18.017] | 7.544 [6.728, 8.318] |
| false alarms before verification, all, per km per day | 18.079 [17.976, 18.173] | 17.936 [17.847, 18.022] | 18.243 [18.144, 18.344] | 14.501 [13.809, 15.194] |
| false alarms AFTER verification (reaching a patrol), per km per day (target 0.01) | 0.218 [0.208, 0.228] | 0.218 [0.208, 0.228] | 0.218 [0.208, 0.227] | 1.104 [0.993, 1.216] |

## Re-identification inside the simulation (SIMULATED lookup in `results/reid/reid_grid.csv`)
Each verified intruder is given the spacing to the nearest other intruder tracked at the same time (600 s after entry, ASSUMED); the person-level link accuracy and link rate are looked up in the re-id grid at that spacing (no pairs, clock 0.2 s, base drone camera 2.5 m, or the fixed camera 1 m when a camera verified it).

| Case | Verified intruders | share with a neighbour within 50 m | within 20 m | within 10 m | share with no simultaneous intruder | implied person-level link accuracy | implied person-level link rate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low | 1175 | 0.00 % | 0.00 % | 0.00 % | 72 % | 99.9 % | 95.0 % |
| medium | 1523 | 0.13 % | 0.00 % | 0.00 % | 70 % | 99.9 % | 95.0 % |
| high | 1473 | 0.00 % | 0.00 % | 0.00 % | 70 % | 99.9 % | 95.0 % |

Intruders enter one at a time (about 27 per day over 145 km, independently): almost none has a neighbour within 50 m, so the simulation sits in the EASY cells of the re-id grid. Pairs and groups are not modelled in the unified simulation; the hard cells (pairs, spacing 2 m or less, dropout) are in `report/reid_summary.md` and are not exercised here.

## Figures (SIMULATED)
* `results/figures/stage8_map_intruders_medium.png`: boundary with Hot / Neutral / Cold cells and the intruders: detected and verified within T_resp, detected but not verified in time, missed by the DAS.
* `results/figures/stage8_timeline_incident.png`: one incident from the crossing to the patrol.
* `results/figures/stage8_scenarios_bars.png`: bars for low / medium / high (+ the Brno-matrix sensitivity) with 95 % limits.
* `results/figures/stage8_false_alarms.png`: false alarms before / after verification against the target.

## Reading notes (read before using the numbers)
* **Brno-matrix column = SENSITIVITY, driven by the tiny counts, not a statement about the classifier.** Each matrix row rests on 2 to 4 events and is drawn per simulated day from Dirichlet(counts + 0.5 per class) (`dirichlet_prior`, ASSUMED); with 2 vehicle events, the probability of "vehicle" given a vehicle is only about 0.42, so many authorized vehicles are classified as alarm classes and the drone- or camera-cued false alarms rise from 0.32 to 7.0 per km per day. Classes without a row (running, digging, tampering, background, animal) use the uniform stub. A smaller prior would give a milder result; it is shown only to show how much the classifier uncertainty can matter.
* **Pd here (95.7 to 96.7 %) is the whole-chain value** (all event types, distances to the interrogator up to 19 km, ground-coupling spread ASSUMED); it is not the literature Pd_DAS (0.969) that the optimization uses, and not the 0.977 of the window library, which has a different distance mix.
* **Patrol reached counts any delay** (a patrol is sent after the asset confirms, even after T_resp); the share verified within T_resp is the timeliness measure.
* **The 60 days give intervals of +/- 2 points on most ratios** (bootstrap over days). Stage 9 runs until at least 10,000 intruders per case.
