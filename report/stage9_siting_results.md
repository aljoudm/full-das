# Stage 9: full Monte Carlo (SIMULATED)

**SIMULATED.** Every case ran 394 simulated days (until at least 10,000 real intruder EVENTS: low 10004, medium 10004, high 10004), seed 9090, 22 interdiction sites, 100 authorized vehicles per site per day (PLACEHOLDER), p_site_clear 0.99 (PLACEHOLDER), along-boundary walk p_along 0.10 (ASSUMED). Base classifier: temporary uniform stub, Pc 0.983 (ASSUMED, literature). 95 % intervals: bootstrap over DAYS (2,000 resamples). **Common random numbers:** day d of every case uses the same generator streams, so all cases see the SAME intruders and the same non-intrusion events (checked: the intruder times are identical in the three scenarios and the non-intrusion events are identical in 394 of 394 days); differences between scenarios come from the assets only. Sources: `results/stage9/metrics_summary.csv`, `reid_in_simulation.csv`, code `src/metrics/`, `scripts/stage9_run.m`.

## 1. The three scenarios (base classifier stub)

| Metric | low (3 drones) | medium (6) | high (12) | Source |
| --- | --- | --- | --- | --- |
| Pd: detected by the DAS | 99.6 % [99.5, 99.7] | 99.6 % [99.5, 99.7] | 99.6 % [99.5, 99.7] | `metrics_summary.csv` |
| Pc: classified correctly, given detection | 98.3 % [98.1, 98.6] | 98.3 % [98.1, 98.6] | 98.3 % [98.1, 98.6] | `metrics_summary.csv` |
| Pd x Pc: detected and classified correctly (end to end, of all intruders) | 97.9 % [97.6, 98.2] | 97.9 % [97.6, 98.2] | 97.9 % [97.6, 98.2] | `metrics_summary.csv` |
| alarm raised (detected and classified as a threat; includes alerts routed to site guards) | 99.0 % [98.8, 99.2] | 99.0 % [98.8, 99.2] | 99.0 % [98.8, 99.2] | `metrics_summary.csv` |
| verified within T_resp (300 s), all intruders | 19.4 % [18.6, 20.2] | 39.0 % [37.9, 40.0] | 73.2 % [72.3, 74.1] | `metrics_summary.csv` |
| verified within T_resp, Hot-zone intruders | 24.1 % [22.9, 25.2] | 51.0 % [49.6, 52.4] | 92.3 % [91.6, 93.0] | `metrics_summary.csv` |
| verified within T_resp, of the intruders that raised an alarm | 19.6 % [18.7, 20.4] | 39.3 % [38.3, 40.4] | 73.9 % [73.0, 74.8] | `metrics_summary.csv` |
| patrol reached (after a confirmed verification, ANY delay), all intruders | 65.8 % [64.8, 66.7] | 87.6 % [86.9, 88.3] | 88.6 % [88.0, 89.3] | `metrics_summary.csv` |
| patrol reached, of the intruders that raised an alarm | 66.4 % [65.5, 67.3] | 88.4 % [87.8, 89.1] | 89.5 % [88.9, 90.1] | `metrics_summary.csv` |
| height measurable (all intruders, p_along 10 %) | 4.5 % [4.1, 5.0] | 4.5 % [4.1, 5.0] | 4.5 % [4.1, 5.0] | `metrics_summary.csv` |
| median verification time, s (alarm to asset on scene) | 1001 [979, 1033] | 494 [484, 508] | 202 [201, 204] | `metrics_summary.csv` |
| 90th percentile of the verification time, s | 1683 [1660, 1708] | 1251 [1218, 1294] | 575 [554, 617] | `metrics_summary.csv` |
| median alarm-to-patrol time, s | 1669 [1664, 1674] | 675 [654, 694] | 403 [401, 405] | `metrics_summary.csv` |
| 90th percentile of the alarm-to-patrol time, s | 2555 [2543, 2570] | 1420 [1361, 1495] | 680 [656, 702] | `metrics_summary.csv` |
| false alarms before verification, drone- or camera-cued, per km per day | 0.353 [0.348, 0.358] | 0.353 [0.348, 0.358] | 0.353 [0.348, 0.358] | `metrics_summary.csv` |
| false alarms before verification, routed to site guards (low priority), per km per day | 18.232 [18.199, 18.264] | 18.232 [18.199, 18.264] | 18.232 [18.199, 18.264] | `metrics_summary.csv` |
| false alarms before verification, all, per km per day | 18.584 [18.551, 18.617] | 18.584 [18.551, 18.617] | 18.584 [18.551, 18.617] | `metrics_summary.csv` |
| false alarms AFTER verification (reaching a patrol), per km per day (target 0.01) | 0.221 [0.217, 0.225] | 0.227 [0.223, 0.231] | 0.227 [0.223, 0.231] | `metrics_summary.csv` |

## 2. Sensitivities (medium)

| Metric | base (uniform stub, singles) | Brno matrix, "Brno, 4 test recordings, SENSITIVITY" | groups: p_group 25 % (ASSUMED) | groups: p_group 50 % (ASSUMED) |
| --- | --- | --- | --- | --- |
| Intruder EVENTS / PERSONS | 10004 / 10004 | 10004 / 10004 | 10004 / 16089 | 10004 / 22547 |
| Pd | 99.6 % [99.5, 99.7] | 99.6 % [99.5, 99.7] | 99.7 % [99.6, 99.8] | 99.6 % [99.5, 99.7] |
| Pc given detection | 98.3 % [98.1, 98.6] | 58.4 % [57.2, 59.7] | 98.2 % [97.9, 98.4] | 98.2 % [97.9, 98.5] |
| verified within T_resp (events) | 39.0 % [37.9, 40.0] | 33.5 % [32.6, 34.5] | 38.5 % [37.5, 39.5] | 38.9 % [37.9, 39.9] |
| verified within T_resp, Hot | 51.0 % [49.6, 52.4] | 43.9 % [42.5, 45.1] | 50.4 % [49.0, 51.8] | 51.2 % [49.8, 52.6] |
| persons in verified events (share of persons) | 39.0 % | 33.5 % | 38.6 % | 38.7 % |
| patrol reached (events, any delay) | 87.6 % [86.9, 88.3] | 74.5 % [73.5, 75.5] | 87.5 % [86.9, 88.2] | 87.5 % [86.8, 88.1] |
| patrol fully staffed (all needed patrols sent), of confirmed events | 100.0 % [100.0, 100.0] | 100.0 % [100.0, 100.0] | 100.0 % [100.0, 100.0] | 100.0 % [100.0, 100.0] |
| median alarm-to-patrol, s | 675 [654, 694] | 768 [754, 773] | 769 [757, 776] | 820 [812, 826] |
| 90th percentile alarm-to-patrol, s | 1420 [1361, 1495] | 1512 [1481, 1525] | 1559 [1525, 1601] | 1629 [1619, 1661] |
| false alarms before verification, drone/camera-cued, per km per day | 0.353 [0.348, 0.358] | 7.963 [7.632, 8.308] | 0.354 [0.349, 0.359] | 0.355 [0.350, 0.360] |
| false alarms reaching a patrol, per km per day | 0.227 [0.223, 0.231] | 1.259 [1.208, 1.310] | 0.228 [0.224, 0.231] | 0.228 [0.224, 0.231] |

**Re-identification in the simulation (SIMULATED lookups):** singles use the spacing to the nearest simultaneous intruder in `reid_grid.csv`; groups use their size in `results/reid/group_events.csv` (group scenes: members 1 to 2 m apart among single walkers 50 m apart, camera clock offset 0.2 s); drone base 2.5 m, fixed camera 1 m when a camera verified. All persons of a verified event count (weights = persons).

| Case | Verified persons | Share of verified events that are groups | Accuracy of the person-level links made | Person-level link rate | Decision rate (person or group) | Group-level accuracy | Wrong person-level links per 100 persons |
| --- | --- | --- | --- | --- | --- | --- | --- |
| base (singles) | 9790 | 0.0 % | 99.9 % | 95.0 % | 95.2 % | 94.9 % | 0.07 |
| p_group 25 % | 15756 | 24.6 % | 98.0 % | 50.0 % | 59.4 % | 59.1 % | 0.98 |
| p_group 50 % | 22040 | 50.3 % | 95.2 % | 29.0 % | 42.8 % | 42.5 % | 1.40 |
