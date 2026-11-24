# Values still PLACEHOLDER or TBD (need data, a quotation or a decision)

| Symbol | Value | Unit | What is missing |
| --- | --- | --- | --- |
| `T_alert` | TBD | s |  |
| `L_loc` | TBD | m | للعلم: الـ spatial resolution للجهاز من 1 إلى 50 m حسب الداتاشيت، فالرقم لازم يكون في هالمدى |
| `C_shelter` | 120000 | SAR/unit | [full-das 2026-11-24] 120,000 SAR per NEW cabin (road sites): PLACEHOLDER, needs a supplier quotation (no Saudi price found). Entrance checkpoints use C_shelter_checkpoint = 30,000 SAR (ASSUMED, exist |
| `T_resp` | 300 | s | مرتبط بـ T_alert (لسا TBD عند الطالبة 1). الحساسية: 180 و600 s. قرار 22 نوفمبر |
| `A_ver_min` | 0.9 | - | قيمة مؤقتة. الحساسية: 0.8 و0.95. قرار 22 نوفمبر |
| `C_PS` | TBD | SAR/unit | ما تدخل في التغطية في هذي النسخة (موجودة عند المنافذ مع الكاميرات)، ومطفية بـ use_PS. قرار 21 نوفمبر |
| `Cov_PS` | TBD | m | ما تدخل في التغطية في هذي النسخة (موجودة عند المنافذ مع الكاميرات)، ومطفية بـ use_PS. قرار 21 نوفمبر |
| `P_PS` | TBD | W/unit | ما تدخل في التغطية في هذي النسخة (موجودة عند المنافذ مع الكاميرات)، ومطفية بـ use_PS. قرار 21 نوفمبر |
| `Pd_PS` | TBD | % | ما تدخل في التغطية في هذي النسخة (موجودة عند المنافذ مع الكاميرات)، ومطفية بـ use_PS. قرار 21 نوفمبر |
| `Pc_PS` | TBD | % | ما تدخل في التغطية في هذي النسخة (موجودة عند المنافذ مع الكاميرات)، ومطفية بـ use_PS. قرار 21 نوفمبر |
| `lambda_hot` | 11-20 | events/day لكل الزون | من الريبو: المدى مقصود. الـ Monte Carlo يسحب رقم عشوائي من المدى كل مرة، والمعدل ينوزع على خلايا الزون حسب خطر كل خلية وطول الحد فيها (results_zones/cells.csv) |
| `lambda_neutral` | 8-10 | events/day لكل الزون | صححت (Warm) إلى (Neutral) حسب جدول الرموز الموحدة. وملاحظة المدى نفس اللي فوق |
| `C_total` | TBD | SAR | هذا مخرج من الـ optimization، مو مدخل |
| `FAR_per_km_day` | 0.01 | alarms/km/day | [full-das 2026-11-22] Reported as a result; no target yet. |
| `dh_reid_max` | 25 | cm | [full-das 2026-11-22] Value from Yomna; to be revisited with real data. |
| `Pc_DAS_public` | TBD | - | [full-das 2026-11-22] If below AC0 = 98% it is reported as a result; the target is not changed. |
| `lam_animal_km_day` | 3 | events/km/day | [full-das 2026-11-22]  |
| `n_vehicle_site_day` | 100 | vehicles/day/site | [full-das 2026-11-22]  |
| `lam_noise_km_day` | 20 | events/km/day | [full-das 2026-11-22]  |
| `L_win_m` | 300 | m | [full-das 2026-11-22] Event at the centre; channels every dz_samp = 2 m. |
| `T_win_s` | 2.0 | s | [full-das 2026-11-22]  |
| `fs_win_hz` | 510 | Hz | [full-das 2026-11-22]  |
| `Pc_animal_placeholder` | 0.80 | - | [full-das 2026-11-22] Never a measured value. |
| `t_proc_s` | 1.0 | s | [full-das 2026-11-22] Detection-to-alert time = T_win_s + t_proc_s + t_ai_s. |
| `t_cam_s` | 5 | s | [full-das 2026-11-22]  |
| `T_mission_s` | 900 | s | [full-das 2026-11-22] The optimization uses the steady-state availability A(n) (D8); the simulation uses the explicit state, so the two can differ. |
| `T_patrol_busy_s` | 1800 | s | [full-das 2026-11-22]  |
| `p_site_clear` | 0.99 | - | [full-das 2026-11-22] First run used Pc_CCTV = 0.85 for clearing: about 355 false patrol dispatches per day, not credible for guarded sites. |
| `C_shelter_checkpoint` | 30000 | SAR/unit | [full-das 2026-11-24] Project lead 24 Nov 2026. Sensitivity 10-50 % of C_shelter. Needs a quotation for the equipment room. |
