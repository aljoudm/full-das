# Stage 9: full Monte Carlo (SIMULATED)

**SIMULATED.** Every case ran 394 simulated days (until at least 10,000 real intruder EVENTS: low 10004, medium 10004, high 10004), seed 9090, 22 interdiction sites, 100 authorized vehicles per site per day (PLACEHOLDER), p_site_clear 0.99 (PLACEHOLDER), along-boundary walk p_along 0.10 (ASSUMED). Base classifier: temporary uniform stub, Pc 0.983 (ASSUMED, literature). 95 % intervals: bootstrap over DAYS (2,000 resamples). **Common random numbers:** day d of every case uses the same generator streams, so all cases see the SAME intruders and the same non-intrusion events (checked: the intruder times are identical in the three scenarios and the non-intrusion events are identical in 394 of 394 days); differences between scenarios come from the assets only. Sources: `results/stage9/metrics_summary.csv`, `reid_in_simulation.csv`, code `src/metrics/`, `scripts/stage9_run.m`.

## 1. The three scenarios (base classifier stub)

| Metric | low (3 drones) | medium (6) | high (12) | Source |
| --- | --- | --- | --- | --- |
| Pd: detected by the DAS | 96.4 % [96.1, 96.8] | 95.8 % [95.4, 96.2] | 95.9 % [95.6, 96.3] | `metrics_summary.csv` |
| Pc: classified correctly, given detection | 98.3 % [98.0, 98.6] | 98.3 % [98.1, 98.6] | 98.4 % [98.1, 98.6] | `metrics_summary.csv` |
| Pd x Pc: detected and classified correctly (end to end, of all intruders) | 94.8 % [94.4, 95.2] | 94.2 % [93.8, 94.7] | 94.3 % [93.9, 94.8] | `metrics_summary.csv` |
| alarm raised (detected and classified as a threat; includes alerts routed to site guards) | 95.9 % [95.5, 96.3] | 95.3 % [94.9, 95.7] | 95.4 % [94.9, 95.8] | `metrics_summary.csv` |
| verified within T_resp (300 s), all intruders | 19.5 % [18.7, 20.3] | 37.1 % [36.1, 38.1] | 69.5 % [68.6, 70.4] | `metrics_summary.csv` |
| verified within T_resp, Hot-zone intruders | 25.0 % [23.9, 26.2] | 48.9 % [47.5, 50.2] | 89.1 % [88.3, 89.9] | `metrics_summary.csv` |
| verified within T_resp, of the intruders that raised an alarm | 20.4 % [19.5, 21.2] | 38.9 % [37.9, 40.0] | 72.9 % [72.0, 73.8] | `metrics_summary.csv` |
| patrol reached (after a confirmed verification, ANY delay), all intruders | 66.5 % [65.5, 67.5] | 84.5 % [83.9, 85.3] | 85.3 % [84.7, 86.0] | `metrics_summary.csv` |
| patrol reached, of the intruders that raised an alarm | 69.4 % [68.4, 70.4] | 88.7 % [88.1, 89.4] | 89.5 % [88.9, 90.1] | `metrics_summary.csv` |
| height measurable (all intruders, p_along 10 %) | 4.2 % [3.8, 4.6] | 4.2 % [3.8, 4.6] | 4.3 % [3.9, 4.7] | `metrics_summary.csv` |
| median verification time, s (alarm to asset on scene) | 942 [928, 967] | 486 [474, 504] | 220 [219, 224] | `metrics_summary.csv` |
| 90th percentile of the verification time, s | 1671 [1661, 1695] | 1233 [1224, 1244] | 611 [589, 632] | `metrics_summary.csv` |
| median alarm-to-patrol time, s | 1488 [1484, 1492] | 684 [662, 696] | 406 [404, 408] | `metrics_summary.csv` |
| 90th percentile of the alarm-to-patrol time, s | 2494 [2486, 2517] | 1405 [1400, 1419] | 746 [729, 754] | `metrics_summary.csv` |
| false alarms before verification, drone- or camera-cued, per km per day | 0.320 [0.315, 0.325] | 0.319 [0.314, 0.324] | 0.322 [0.318, 0.327] | `metrics_summary.csv` |
| false alarms before verification, routed to site guards (low priority), per km per day | 17.669 [17.637, 17.701] | 17.609 [17.576, 17.642] | 17.898 [17.865, 17.930] | `metrics_summary.csv` |
| false alarms before verification, all, per km per day | 17.989 [17.957, 18.021] | 17.928 [17.894, 17.962] | 18.220 [18.186, 18.253] | `metrics_summary.csv` |
| false alarms AFTER verification (reaching a patrol), per km per day (target 0.01) | 0.213 [0.209, 0.216] | 0.217 [0.213, 0.221] | 0.220 [0.216, 0.224] | `metrics_summary.csv` |

## 2. Sensitivities (medium)

| Metric | base (uniform stub, singles) | Brno matrix, "Brno, 4 test recordings, SENSITIVITY" | groups: p_group 25 % (ASSUMED) | groups: p_group 50 % (ASSUMED) |
| --- | --- | --- | --- | --- |
| Intruder EVENTS / PERSONS | 10004 / 10004 | 10004 / 10004 | 10004 / 16089 | 10004 / 22547 |
| Pd | 95.8 % [95.4, 96.2] | 95.8 % [95.4, 96.2] | 96.1 % [95.7, 96.5] | 95.8 % [95.4, 96.2] |
| Pc given detection | 98.3 % [98.1, 98.6] | 58.7 % [57.4, 60.1] | 98.1 % [97.9, 98.4] | 98.2 % [97.9, 98.5] |
| verified within T_resp (events) | 37.1 % [36.1, 38.1] | 32.0 % [31.1, 33.0] | 37.4 % [36.4, 38.3] | 37.6 % [36.6, 38.6] |
| verified within T_resp, Hot | 48.9 % [47.5, 50.2] | 42.0 % [40.6, 43.3] | 49.2 % [47.8, 50.5] | 49.5 % [48.1, 50.8] |
| persons in verified events (share of persons) | 37.1 % | 32.0 % | 37.4 % | 37.3 % |
| patrol reached (events, any delay) | 84.5 % [83.9, 85.3] | 71.6 % [70.6, 72.7] | 84.7 % [84.0, 85.5] | 84.4 % [83.6, 85.1] |
| patrol fully staffed (all needed patrols sent), of confirmed events | 100.0 % [100.0, 100.0] | 100.0 % [100.0, 100.0] | 100.0 % [100.0, 100.0] | 100.0 % [100.0, 100.0] |
| median alarm-to-patrol, s | 684 [662, 696] | 747 [740, 766] | 751 [742, 772] | 831 [806, 838] |
| 90th percentile alarm-to-patrol, s | 1405 [1400, 1419] | 1436 [1417, 1471] | 1530 [1497, 1590] | 1612 [1591, 1637] |
| false alarms before verification, drone/camera-cued, per km per day | 0.319 [0.314, 0.324] | 7.673 [7.354, 8.006] | 0.321 [0.317, 0.326] | 0.322 [0.317, 0.326] |
| false alarms reaching a patrol, per km per day | 0.217 [0.213, 0.221] | 1.211 [1.160, 1.260] | 0.217 [0.214, 0.221] | 0.217 [0.213, 0.221] |

**Re-identification in the simulation (SIMULATED lookups):** singles use the spacing to the nearest simultaneous intruder in `reid_grid.csv`; groups use their size in `results/reid/group_events.csv` (group scenes: members 1 to 2 m apart among single walkers 50 m apart, camera clock offset 0.2 s); drone base 2.5 m, fixed camera 1 m when a camera verified. All persons of a verified event count (weights = persons).

| Case | Verified persons | Share of verified events that are groups | Accuracy of the person-level links made | Person-level link rate | Decision rate (person or group) | Group-level accuracy | Wrong person-level links per 100 persons |
| --- | --- | --- | --- | --- | --- | --- | --- |
| base (singles) | 9443 | 0.0 % | 99.9 % | 95.0 % | 95.2 % | 94.9 % | 0.07 |
| p_group 25 % | 15204 | 24.4 % | 98.0 % | 50.3 % | 59.6 % | 59.3 % | 0.98 |
| p_group 50 % | 21165 | 49.9 % | 95.2 % | 29.3 % | 43.0 % | 42.6 % | 1.40 |
