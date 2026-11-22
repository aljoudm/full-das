# Re-identification (DAS track <-> camera / drone track): summary of the SIMULATED grid

**SIMULATED. Every error and population spread is ASSUMED** (`config/ai_config.json`, block `reid`; table rows `reid_*`). Drone position error (1 sigma per axis): 1.5 m and 2.5 m are a PROXY from Nalamothu et al. 2024 (arXiv 2410.12556; static target, GPS type not stated, so optimistic), 5 m is ASSUMED. Fixed camera: 1 m (ASSUMED); fixed cameras cover only 1.9 % of the boundary, so most links will be with the drone. Design: `docs/ReID_Design_and_Evaluation_Protocol.pdf`. Full results: `results/reid/reid_grid.csv` (every cell, with 95 % scene-bootstrap limits), `results/reid/ablation.csv`, `results/reid/summary.json`, `results/reid/accuracy_vs_spacing.png`.

**Thresholds: ONE setting for the whole grid and for all four camera sources** (gate 4 sigma, margin 2 in cost), chosen once on development scenes with a different seed (fixed camera, clock 0.2 s, 10 % dropout, spacing 10/5/2 m, pairs 0/25/50 %) as the setting with the highest person-level link rate whose person-level link accuracy was at least 0.97, then frozen. It is not tuned per cell and not per camera type.

## Reference cells (clock offset 0.2 s, people all walking one way, no camera dropout, 300 scenes per cell, 95 % scene bootstrap)

| Camera | Spacing | Pairs | Accuracy of person-level links made [95 %] | Person-level link rate | Decision rate (person or group) | Wrong person-level links per 100 tracks [95 %] | Person-level accuracy (all tracks) | Group-level accuracy | IDF1 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| fixed camera, 1 m | 20 m | 0 % | 0.999 [0.999, 1.000] | 0.930 | 0.935 | 0.1 [0.0, 0.1] | 0.929 | 0.929 | 0.963 |
| fixed camera, 1 m | 20 m | 50 % | 0.971 [0.968, 0.975] | 0.603 | 0.694 | 1.7 [1.5, 2.0] | 0.586 | 0.686 | 0.731 |
| fixed camera, 1 m | 10 m | 0 % | 0.998 [0.997, 0.998] | 0.871 | 0.883 | 0.2 [0.1, 0.3] | 0.869 | 0.869 | 0.929 |
| fixed camera, 1 m | 10 m | 50 % | 0.973 [0.969, 0.976] | 0.567 | 0.668 | 1.6 [1.4, 1.8] | 0.552 | 0.652 | 0.704 |
| fixed camera, 1 m | 2 m | 0 % | 0.987 [0.985, 0.990] | 0.585 | 0.661 | 0.7 [0.6, 0.9] | 0.577 | 0.577 | 0.729 |
| fixed camera, 1 m | 2 m | 50 % | 0.962 [0.957, 0.966] | 0.409 | 0.574 | 1.6 [1.4, 1.8] | 0.393 | 0.484 | 0.558 |
| drone camera, 1.5 m | 20 m | 0 % | 0.999 [0.998, 0.999] | 0.915 | 0.920 | 0.1 [0.1, 0.2] | 0.913 | 0.913 | 0.954 |
| drone camera, 1.5 m | 20 m | 50 % | 0.970 [0.967, 0.973] | 0.577 | 0.657 | 1.7 [1.5, 1.9] | 0.560 | 0.647 | 0.710 |
| drone camera, 1.5 m | 10 m | 0 % | 0.997 [0.996, 0.998] | 0.839 | 0.850 | 0.3 [0.2, 0.4] | 0.836 | 0.836 | 0.909 |
| drone camera, 1.5 m | 10 m | 50 % | 0.970 [0.966, 0.973] | 0.542 | 0.626 | 1.6 [1.4, 1.9] | 0.526 | 0.607 | 0.682 |
| drone camera, 1.5 m | 2 m | 0 % | 0.981 [0.978, 0.984] | 0.518 | 0.592 | 1.0 [0.9, 1.2] | 0.508 | 0.508 | 0.669 |
| drone camera, 1.5 m | 2 m | 50 % | 0.955 [0.948, 0.961] | 0.368 | 0.511 | 1.7 [1.4, 1.9] | 0.351 | 0.424 | 0.513 |
| **drone camera, 2.5 m (base)** | 20 m | 0 % | 0.998 [0.997, 0.999] | 0.881 | 0.885 | 0.2 [0.1, 0.2] | 0.879 | 0.879 | 0.935 |
| **drone camera, 2.5 m (base)** | 20 m | 50 % | 0.966 [0.962, 0.970] | 0.561 | 0.614 | 1.9 [1.7, 2.1] | 0.542 | 0.606 | 0.694 |
| **drone camera, 2.5 m (base)** | 10 m | 0 % | 0.996 [0.995, 0.997] | 0.797 | 0.806 | 0.3 [0.3, 0.4] | 0.794 | 0.794 | 0.883 |
| **drone camera, 2.5 m (base)** | 10 m | 50 % | 0.966 [0.962, 0.970] | 0.515 | 0.576 | 1.7 [1.5, 2.0] | 0.498 | 0.561 | 0.657 |
| **drone camera, 2.5 m (base)** | 2 m | 0 % | 0.975 [0.971, 0.979] | 0.434 | 0.495 | 1.1 [0.9, 1.3] | 0.423 | 0.423 | 0.590 |
| **drone camera, 2.5 m (base)** | 2 m | 50 % | 0.945 [0.938, 0.952] | 0.304 | 0.419 | 1.7 [1.5, 1.9] | 0.288 | 0.345 | 0.441 |
| drone camera, 5 m | 20 m | 0 % | 0.996 [0.995, 0.997] | 0.797 | 0.798 | 0.3 [0.2, 0.4] | 0.794 | 0.794 | 0.884 |
| drone camera, 5 m | 20 m | 50 % | 0.967 [0.963, 0.971] | 0.503 | 0.537 | 1.6 [1.5, 1.8] | 0.487 | 0.530 | 0.648 |
| drone camera, 5 m | 10 m | 0 % | 0.991 [0.990, 0.993] | 0.653 | 0.660 | 0.6 [0.5, 0.7] | 0.648 | 0.648 | 0.783 |
| drone camera, 5 m | 10 m | 50 % | 0.966 [0.962, 0.970] | 0.434 | 0.468 | 1.5 [1.3, 1.7] | 0.419 | 0.454 | 0.584 |
| drone camera, 5 m | 2 m | 0 % | 0.951 [0.945, 0.957] | 0.286 | 0.329 | 1.4 [1.2, 1.6] | 0.272 | 0.272 | 0.423 |
| drone camera, 5 m | 2 m | 50 % | 0.921 [0.913, 0.930] | 0.205 | 0.270 | 1.6 [1.4, 1.8] | 0.189 | 0.216 | 0.313 |

## Does the 0.97 hold? NO, not in every cell
The 0.97 was the target on the development mix (pooled 0.978). On the full grid the accuracy of the person-level links that are made is below 0.97 in many cells:

| Camera | Cells | Point value below 0.97 | Lower 95 % limit below 0.97 | Lowest cell |
| --- | --- | --- | --- | --- |
| fixed camera, 1 m | 648 | 228 (35 %) | 265 | 0.840 |
| drone camera, 1.5 m | 216 | 86 (40 %) | 94 | 0.890 |
| **drone camera, 2.5 m (base)** | 216 | 98 (45 %) | 109 | 0.862 |
| drone camera, 5 m | 216 | 121 (56 %) | 131 | 0.855 |

* **Where it fails:** cells with half of the people walking in pairs (accuracy about 0.95 to 0.97 even at 20 m, because a partner of a pair can be linked with the wrong person), small spacing (2 m and 1 m), and camera dropout of 20 %. With the pessimistic drone camera (5 m) at 2 m spacing the accuracy of the links made is 0.951 (no pairs) and **0.921 [0.913, 0.930] with 50 % pairs**, clearly below 0.97, and only 29 % and 21 % of the tracks get a person-level link.
* **Reading:** the margin keeps the links that are made reliable only when the scene is not crowded and not in pairs; in the hard cells the operator must rely on `ambiguous` and on the group link. Per-cell accuracy and wrong-link rate with limits are in `reid_grid.csv` (columns `person_link_acc*`, `wrong_links_per_100*`).

## Ablation (no pairs, clock 0.2 s, person-level accuracy over all tracks, 300 scenes): what height and cadence add

| Camera | Spacing | all cues | height adds (points) | cadence adds (points) | speed removed | position only |
| --- | --- | --- | --- | --- | --- | --- |
| fixed camera, 1 m | 20 m | 0.935 | 1.1 | 5.6 | 0.887 | 0.743 |
| fixed camera, 1 m | 10 m | 0.879 | 2.0 | 11.6 | 0.797 | 0.552 |
| fixed camera, 1 m | 5 m | 0.776 | 3.1 | 18.7 | 0.650 | 0.309 |
| fixed camera, 1 m | 2 m | 0.573 | 5.2 | 24.7 | 0.398 | 0.075 |
| **drone camera, 2.5 m (base)** | 20 m | 0.885 | 2.0 | 11.2 | 0.805 | 0.568 |
| **drone camera, 2.5 m (base)** | 10 m | 0.787 | 2.9 | 18.0 | 0.662 | 0.327 |
| **drone camera, 2.5 m (base)** | 5 m | 0.640 | 4.7 | 23.9 | 0.469 | 0.116 |
| **drone camera, 2.5 m (base)** | 2 m | 0.412 | 6.8 | 24.1 | 0.227 | 0.015 |

* **Height adds 1 to 7 points** (about 1 point at 20 m, 5 to 7 points at 2 m); it is exploratory (+/- 8 cm) and is used here only inside an event.
* **Cadence adds 6 to 25 points** (about 11 points at 20 m for the base drone camera, 24 points at 2 m) **IF the camera can measure it to +/- 3 steps/min**: that is an ASSUMPTION (open question 1 of the protocol); without camera cadence the result equals the "no cadence" row.

## Main sentence (base drone camera, 2.5 m)
With the base drone camera (2.5 m position error, ASSUMED / proxy), people 10 m apart and nobody walking in a pair, **99.6 % [99.5, 99.7] of the person-level links that are made are correct, 79.7 % of the tracks get such a link and 0.3 wrong links are made per 100 tracks**; with half of the people walking in pairs, the links made are 96.6 % [96.2, 97.0] correct, only 51.5 % of the tracks get a person-level link (57.6 % get any link, person or group) and 1.7 wrong links per 100 tracks are made. At 2 m spacing the figures are 97.5 % and 43.4 % (no pairs) and 94.5 % and 30.4 % (50 % pairs): the 0.97 target is not kept there. All SIMULATED.

