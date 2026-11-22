# AI summary for the report (all numbers come from result files; each is labelled SIMULATED or Brno, with its source)

## 1. Event classifier on the Brno dataset (label: **Brno, not FEBUS, not system accuracy**)

Source: `results/classifier/T1s/metrics.json` (window 1 s, ASSUMED), protocol `docs/Classifier_Evaluation_Protocol.pdf`, splits `config/splits.json` (seed 20261122). **4 test recordings only, 16 test events**; evaluation at event level (mean probability over the windows of an event); leakage checks passed (disjoint groups, no event across a split, no duplicate windows).

| Class | Test events | Test recordings | Events correct | Recall | Clopper-Pearson 95 % on events | Best provable lower bound if all correct (0.05^(1/n)) |
| --- | --- | --- | --- | --- | --- | --- |
| walking | 4 | 1 | 4 | 1.000 | [0.398, 1.000] | 0.473 |
| vehicle | 2 | 1 | 2 | 1.000 | [0.158, 1.000] | 0.224 |
| climbing | 7 | 1 | 0 | 0.000 | [0.000, 0.410] | 0.652 |
| other | 3 | 1 | 3 | 1.000 | [0.292, 1.000] | 0.368 |

* **Balanced accuracy 0.750** over the 4 evaluable classes (walking, vehicle, climbing, other); the cluster bootstrap [0.50, 1.00] is not meaningful with 4 recordings.
* Running, digging (construction), tampering and background have ONE recording each: trained, **not evaluable on Brno**, out of the headline. Running is an alarm class and has priority for FEBUS data. Animal is absent from every public set.
* **Per test recording:** auto4_2023-06-06T144655+0100 (vehicle): 2 of 2; fence_2023-04-17T123117+0100 (climbing): 0 of 7; longboard_2023-04-17T123543+ (other): 3 of 3; walking_2023-04-17T121933+01 (walking): 4 of 4.
* **Random vs grouped (diagnostic, window level, run once):** random 80/10/10 window split 0.750 against 0.623 on the grouped locked test: a gap of 12.7 points. Windows overlap and are not independent.
* **What Brno can prove:** the largest class has 17 events with a 1 s window (all recordings); even if every one of them were classified correctly, the one-sided 95 % lower bound on recall is 0.05^(1/17) = **83.8 %**. In the locked test the best case is 0.652. So Brno shows that the classifier works on these data; **the real accuracy has to come from FEBUS** (a 98 % claim needs at least 149 error-free independent events per class).
* **Climbing scored 0 of 7**: expected, because the training has only 2 climbing events from 2 recordings (momentary fence impacts); the result cannot tell a weak classifier from an unusual fence recording.
* **Background (diagnostic, [DIAGNOSTIC - SAME RECORDING], same recording, optimistic):** 0 alarm-class events among 1 background events over 1.5e-05 km-days; 24 s prove nothing about false alarms. The operational rate needs at least 30 km-days of clean FEBUS background without a false alarm to show an upper bound of 0.1 per km per day.
* [DIAGNOSTIC - SAME RECORDING, optimistic] running: 2 events in the last 20 % of its only recording, recall 1.00.
* [DIAGNOSTIC - SAME RECORDING, optimistic] digging: 2 events in the last 20 % of its only recording, recall 1.00.
* [DIAGNOSTIC - SAME RECORDING, optimistic] tampering: 3 events in the last 20 % of its only recording, recall 0.33.
* [DIAGNOSTIC - SAME RECORDING, optimistic] no_event: 1 events in the last 20 % of its only recording, recall 1.00.

**Window length sensitivity (2 s, `results/classifier/T2s/metrics.json`):** balanced accuracy 0.750 over 10 test events (1 s: 0.750 over 16); recall per class walking 1.00 (4 ev.), vehicle 1.00 (2 ev.), climbing 0.00 (1 ev.), other 1.00 (3 ev.). The base stays 1 s (chosen from event counts before training).

**The base stub (Pc_DAS 0.983 to 0.993, literature) is ASSUMED** (table row `Pc_DAS`, value_type ASSUMED; reference wang2024 via Shao 2025). These literature figures usually come from random-window splits and are probably optimistic; our own evidence is the 12.7-point gap between a random-window split and the grouped locked test on Brno (diagnostic, window level, label: Brno). The optimization keeps these values.

**Decision on the confusion matrix:** the uniform stub (Pc from the literature, 0.983 to 0.993) stays the BASE of the unified simulation. The Brno matrix (`results/classifier/T1s/confusion_matrix.csv`, counts) is a SENSITIVITY only, labelled "Brno, 4 test recordings, SENSITIVITY"; classes missing from it (running, digging, tampering, background, animal) fall back to the uniform stub (`config/ai_config.json`, mode `confusion_counts`). The optimization keeps the literature Pc_DAS.

## 2. DAS-camera re-identification (label: **SIMULATED**, all errors assumed)

Source: `results/reid/reid_grid.csv` (1,296 cells, 300 scenes per cell, 95 % scene bootstrap), `report/reid_summary.md`. Thresholds: ONE setting (gate 4 sigma, margin 2) for the whole grid and all camera types, chosen on development scenes. Drone position error 1.5 / 2.5 m: PROXY (Nalamothu et al. 2024, arXiv 2410.12556, static target, optimistic); 5 m and the fixed camera 1 m: ASSUMED.

* **Main sentence (base drone camera, 2.5 m):** with people 10 m apart and nobody in a pair, 99.6 % [99.5, 99.7] of the person-level links made are correct, 79.7 % of the tracks get such a link and 0.3 wrong links are made per 100 tracks; with half walking in pairs: 96.6 % [96.2, 97.0] correct, 51.5 % linked, 1.7 wrong per 100. At 2 m: 97.5 % (no pairs) and 94.5 % (50 % pairs).
* **Cells below the 0.97 target** (accuracy of the person-level links made, point value / lower 95 % limit): fixed: 228 / 265 of 648; drone_optimistic: 86 / 94 of 216; drone_base: 98 / 109 of 216; drone_pessimistic: 121 / 131 of 216.
* **Worst cases:** base drone camera, spacing 1 m, 50 % pairs, dropout 20 %: 0.862 [0.849, 0.874]; over all sources: fixed, 0.840. Pessimistic drone (5 m) at 2 m with 50 % pairs: 0.921 [0.913, 0.930].
* **Ablation (base drone camera, no pairs, person-level accuracy over all tracks):** 20 m: height adds 2.0 points, cadence adds 11.2 points; 10 m: height adds 2.9 points, cadence adds 18.0 points; 5 m: height adds 4.7 points, cadence adds 23.9 points; 2 m: height adds 6.8 points, cadence adds 24.1 points. Cadence helps only if the camera can measure it to +/- 3 steps/min (ASSUMED, untested).

**Where the 0.97 is lost (the limits).** Cells where the accuracy of the person-level links made is below 0.97, with the group-level accuracy of the SAME cells (point values; accuracy over all tracks counts an ambiguous track as not linked; the last column is the accuracy of all decisions made):

| Camera | Cells below 0.97 | with pairs | with spacing 2 m or 1 m | with dropout 20 % | Person-level accuracy, median [min] | Group-level accuracy, median [min] | Accuracy of all decisions (person or group), median [min] |
| --- | --- | --- | --- | --- | --- | --- | --- |
| fixed camera, 1 m | 228 | 198 | 126 | 151 | 0.48 [0.15] | 0.51 [0.17] | 0.92 [0.60] |
| drone, 1.5 m | 86 | 74 | 50 | 57 | 0.49 [0.24] | 0.54 [0.31] | 0.92 [0.65] |
| drone, 2.5 m (base) | 98 | 86 | 57 | 60 | 0.42 [0.18] | 0.47 [0.23] | 0.92 [0.60] |
| drone, 5 m | 121 | 97 | 69 | 72 | 0.34 [0.13] | 0.36 [0.15] | 0.92 [0.60] |

Limits as conditions: **people walking in pairs, spacing of 2 m or less, camera dropout.** There the person-level claim does not hold and the operator relies on `ambiguous` and the group link.
* Fixed cameras cover only 1.9 % of the boundary, so most links will be with the drone. An `ambiguous` link never sends a patrol to a specific person; a DAS-only track is an alarm and goes to the drone.

## 3. Dual verification before a patrol is sent (label: SIMULATED, Stage 6; 20 days, 100 authorized vehicles per site per day and p_site_clear 0.99, both PLACEHOLDERS)

| Scenario | Option | False patrols per km per day | Median verification time (s) | Median alarm-to-patrol (s) | Patrol reached | Intruders not verified within T_resp |
| --- | --- | --- | --- | --- | --- | --- |
| low | A single check | 0.217 | 970 | 1487 | 64.8 % | 81.7 % |
| low | B dual everywhere | 0.189 | 1294 | 1852 | 38.2 % | 93.0 % |
| low | C dual in Neutral+Cold | 0.191 | 1194 | 1657 | 38.5 % | 90.2 % |
| medium | A single check | 0.200 | 518 | 734 | 87.5 % | 63.2 % |
| medium | B dual everywhere | 0.199 | 1193 | 1384 | 59.6 % | 84.7 % |
| medium | C dual in Neutral+Cold | 0.183 | 943 | 1061 | 70.7 % | 79.0 % |
| high | A single check | 0.210 | 225 | 407 | 88.2 % | 29.4 % |
| high | B dual everywhere | 0.188 | 445 | 591 | 80.3 % | 59.2 % |
| high | C dual in Neutral+Cold | 0.194 | 234 | 424 | 85.4 % | 41.6 % |

**Decision: ONE check (option A).** Dual verification lowers the false patrols only by 0 to 13 % while it delays the verification and lets more intruders escape it, because a second drone is a second mission that uses the scarce drones. Most false patrols come from the site-routed alerts, governed by the PLACEHOLDER `p_site_clear` (0.9 -> 1.77, 0.99 -> 0.212, 0.999 -> 0.0525 false patrols per km per day, medium): **the target FAR_km = 0.01 is not reachable with the present assets** (drone / camera verification errors alone give about 0.03 per km per day). Source: `results/stage6_dual.csv`, `report/key_numbers.md`.

## 4. Height from gait and the along-the-boundary walk (label: SIMULATED, Stage 7; `results/stage7_height_share.csv`)

| p_along (ASSUMED) | Walking | Along-boundary path | Height measurable, all intruders | of along-boundary paths | of crossing walkers | of all walkers |
| --- | --- | --- | --- | --- | --- | --- |
| 0 % | 49.7 % | 0.0 % | 0.0 % | n/a | 0.0 % | 0.0 % |
| 10 % | 49.7 % | 4.7 % | 4.1 % | 88.1 % | 0.0 % | 8.3 % |
| 30 % | 49.4 % | 15.2 % | 13.4 % | 87.9 % | 0.0 % | 27.0 % |

A person crossing the fibre never qualifies (the height method needs a walk parallel to the fibre within 3 m with at least 8 footsteps and a detection SNR of at least 12 dB; the SNR condition never binds in simulation). Height is a secondary, exploratory indicator (+/- 8 cm); the primary claim of the DAS is stride, speed and cadence.

## 5. Related system results (SIMULATED, Stage 6)
* Medium scenario: 48.7 to 51.5 % of the Hot alarms verified within T_resp against 61 % of the Hot cells in the optimization: the static availability model is optimistic (it ignores the time a drone is busy, the charge and simultaneous alarms). Source: `report/key_numbers.md`.
* Simulated Pd of the DAS 0.977 (intrusion types) next to the literature 0.969; it depends on the ASSUMED ground coupling and is not a measured Pd. Source: `tests/test_stage4.m`, `report/decisions.md`.
