# Stage 9 before / after the siting model (SIMULATED)

Before = `results/stage9` (4 interrogators at run midpoints, library lookup by the nearest of five distances). After = `results/stage9_siting` (6 interrogators in the sited shelters, lead-in fibre in the optical distance, ONE Pd(d) model `results/siting/pd_model.mat` for the detection decision). Same seed 9090, same common random numbers (the same intruder events day by day), 394 days, 10,004 events per scenario. Source: `scripts/stage9_compare.m`, `results/stage9_siting/comparison*.csv`.

## Cost and devices

| | Before | After |
| --- | --- | --- |
| Interrogators | 4 | 6 |
| C_total (SAR) | 11,373,506 | 12,654,986 |
| Drones | unchanged (3 / 6 / 12) | unchanged |

## System metrics (95 % bootstrap intervals)

| Scenario | Metric | Before | After |
| --- | --- | --- | --- |
| low | Pd (detected by the DAS) | 96.4 % [96.1, 96.8] | 99.6 % [99.5, 99.7] |
| low | Pd x Pc | 94.8 % [94.4, 95.2] | 97.9 % [97.6, 98.2] |
| low | verified within T_resp (all intruders) | 19.5 % [18.7, 20.3] | 19.4 % [18.6, 20.2] |
| low | verified within T_resp (Hot zone) | 25.0 % [23.9, 26.2] | 24.1 % [22.9, 25.2] |
| low | patrol reached | 66.5 % [65.5, 67.5] | 65.8 % [64.8, 66.7] |
| low | median verification time, s | 942 | 1001 |
| medium | Pd (detected by the DAS) | 95.8 % [95.4, 96.2] | 99.6 % [99.5, 99.7] |
| medium | Pd x Pc | 94.2 % [93.8, 94.7] | 97.9 % [97.6, 98.2] |
| medium | verified within T_resp (all intruders) | 37.1 % [36.1, 38.1] | 39.0 % [37.9, 40.0] |
| medium | verified within T_resp (Hot zone) | 48.9 % [47.5, 50.2] | 51.0 % [49.6, 52.4] |
| medium | patrol reached | 84.5 % [83.9, 85.3] | 87.6 % [86.9, 88.3] |
| medium | median verification time, s | 486 | 494 |
| high | Pd (detected by the DAS) | 95.9 % [95.6, 96.3] | 99.6 % [99.5, 99.7] |
| high | Pd x Pc | 94.3 % [93.9, 94.8] | 97.9 % [97.6, 98.2] |
| high | verified within T_resp (all intruders) | 69.5 % [68.6, 70.4] | 73.2 % [72.3, 74.1] |
| high | verified within T_resp (Hot zone) | 89.1 % [88.3, 89.9] | 92.3 % [91.6, 93.0] |
| high | patrol reached | 85.3 % [84.7, 86.0] | 88.6 % [88.0, 89.3] |
| high | median verification time, s | 220 | 202 |

## Share of intruders missed by the DAS, by optical distance to the interrogator (medium; low and high in the csv)

| Distance | Before: events | Before: missed | After: events | After: missed |
| --- | --- | --- | --- | --- |
| 0-5 km | 2977 | 0.00 % | 3899 | 0.03 % |
| 5-10 km | 2363 | 0.00 % | 3952 | 0.30 % |
| 10-14.75 km | 2524 | 5.82 % | 2153 | 1.16 % |
| 14.75-15 km | 111 | 18.92 % | 0 | - |
| 15-20 km | 2029 | 12.22 % | 0 | - |

After the change no event is farther than 14.23 km (maximum optical distance of the siting solution), and the miss share stays below 1.2 % in every band; the overall Pd is above the Pd_DAS = 0.969 assumed by the optimization. Before, events at 12.5-17.5 km used the 15 km library bin (12 windows per type, Pd 0.854) and were missed 5.8-12.2 % of the time (see `report/assumptions.md`).
