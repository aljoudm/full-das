# Final parameter table (single table of the project: `config/parameters_reviewed.tsv`; full 10-column copy in `parameters_final.tsv`)

171 rows. Status counts: ASSUMED 79, PLACEHOLDER 17, TBD 11, مبدئي 10, مقترح 9, مفترض 9, معتمد 6, مفترض (مبني على مصدر) 5, SIMULATED 5, SOURCED 4, اقتراح 4, proxy 3, مختار في الريبو 2, توضيحي 2, مشكوك في امره للغايه جدا 1, اقتراح – المدى الفعلي حول مكة 1, مفترض (موزع، VERIFY) 1, ان شاء الله 1, decided 1.

Status legend: PLACEHOLDER = a value kept only to let the model run, to be replaced by data or a quotation; ASSUMED = engineering assumption with no source; SIMULATED / DERIVED = computed by the model; the rest are sourced (the source column names it).

| Symbol | Value | Unit | Status | value_type | Source |
| --- | --- | --- | --- | --- | --- |
| `AD0` | 98 | % | معتمد | source | هدف المشروع |
| `AC0` | 98 | % | معتمد | source | هدف المشروع |
| `FAR` | 2 | % (1 − precision) | مبدئي | assumption | هدف المشروع؛ تعريف zeng2024 |
| `P0` | 29100 | W | مبدئي | derived | [DERIVED] نظام CCTV-only يغطي نفس الطول = ceil(L_boundary ÷ Cov_CCTV) × P_CCTV = 1455 × 20 W |
| `T_alert` | TBD | s | TBD | tbd |  |
| `L_loc` | TBD | m | TBD | tbd |  |
| `L_boundary` | 145.5 | km | مبدئي | derived | osm_contributors، das_map (data/boundary_perimeter.csv) |
| `C_DAS_int` | 636000 | SAR/unit | مبدئي | source | اجتماع مع FEBUS (150,000 EUR) × سعر صرف 4.24 SAR/EUR (مفترض، سعر 15 أكتوبر 2026) |
| `C_fiber` | 60700 | SAR/km | مشكوك في امره للغايه جدا | assumption |  |
| `R_DAS` | 20 | km | مختار في الريبو | source | Datasheet A1-NEO (خيار 20 km، توهين 0.2 dB/km) |
| `N_ch_DAS` | 4 | channels | مختار في الريبو | source | Datasheet A1-NEO (الجهاز يجي بـ 1 أو 2 أو 4 قنوات) |
| `N_ch_active` | 2 | channels | مقترح | derived | [DERIVED] اتجاهين على الحد |
| `P_DAS` | 170 | W/unit | معتمد | source | Datasheet A1-NEO |
| `N_DAS_int` | 4 | units | مقترح | derived | [DERIVED] ceil(L_boundary ÷ (N_ch_active × R_DAS)) = ceil(145.47 ÷ 40) |
| `L_channel` | 18.18 | km | مقترح | derived | [DERIVED] L_boundary ÷ (N_DAS_int × N_ch_active) |
| `P_DAS_total` | 680 | W | مقترح | derived | [DERIVED] N_DAS_int × P_DAS |
| `P_shelter` | 170 | W | مفترض (مبني على مصدر) | assumption | gsma_coolsure: التبريد 30–50% من حمل الموقع ← 0.43 إلى 1.0 × P_DAS = 73 إلى 170 W |
| `C_shelter` | 120000 | SAR/unit | PLACEHOLDER | placeholder | PLACEHOLDER: no published Saudi price found (searched 24 Nov 2026; only cabinet-AC installation 500 SAR, labour only). Order of magnitude for an air-conditioned |
| `L_leadin` | 0 | m | مفترض | assumption | افتراض: الكابينة على الحد نفسه |
| `Pd_DAS` | 0.969 | - | مفترض (مبني على مصدر) | source | zeng2024: IDR = 96.9% (موقع مزعج)؛ liu2016: 100% ميداني |
| `Pc_DAS` | 0.983 – 0.993 | - | مفترض (مبني على مصدر) | assumption | wang2024 (عبر مراجعة Shao 2025): 99.3% بنقطة إزعاج وحدة، و98.3% مع أكثر من نقطة |
| `C_CCTV` | 1900.90 | SAR/unit | SOURCED | source | KeyStone (k-stone.sa) – Hikvision DS-2DE4425IW-DE(T5) price and installation |
| `Cov_CCTV` | 100 | m | ASSUMED | assumption |  |
| `P_CCTV` | 20 | W/unit | SOURCED | source | Hikvision DS-2DE4425IW-DE(T5) + Dahua SD4A425DB-HNY datasheets |
| `Pd_CCTV` | 90.9 | % | SOURCED | source | Park et al. – nighttime person detection, Table 3 (PMC6983221) |
| `Pc_CCTV` | 85 | % | SOURCED | source | Jebur et al. – surveillance video classification, Table 5 |
| `C_drone` | 148887 | SAR/unit | اقتراح | source | Avg of DJI Dock 3 + Matrice 4TD (94,461 SAR) & Skydio X10 + Dock (203,313 SAR), USD×3.75, accessed 14/11/2026 |
| `Cov_drone` | 11 | km | اقتراح – المدى الفعلي حول مكة | source | Avg of DJI Dock 3 max operating radius (10 km, DJI official specs) & Skydio Dock for X10 max range (12 km, Skydio datasheet), accessed 14/11/2026 |
| `P_drone` | 1500 | W/unit | اقتراح | source | Avg of DJI Dock 3 max input power (800 W, DJI official specs) & Skydio Dock for X10 peak power draw (2200 W, Skydio operational readiness guide), accessed 14/11 |
| `T_drone` | 47 | min | اقتراح | source | Avg of DJI Matrice 4TD max flight time (54 min, DJI official specs) & Skydio X10 max flight time (40 min, Skydio datasheet), accessed 14/11/2026 |
| `T_charge` | 27 | min | مفترض (مبني على مصدر) | source | dji_dock3_specs: من 15% إلى 95% عند 25 °C |
| `v_drone` | 15 | m/s | مفترض (مبني على مصدر) | source | dji_dock3_specs: Matrice 4D/4TD، الوضع Normal (الوحيد المسموح مع الـ Dock)، حساس العوائق شغال. وضع Sport (21 m/s) غير متاح مع الـ Dock |
| `T_launch` | 10 | s | مفترض (موزع، VERIFY) | source | advexure_dock3 (موزع DJI): 10-second takeoff |
| `T_resp` | 300 | s | PLACEHOLDER | placeholder | (فاضي: PLACEHOLDER) |
| `A_ver_min` | 0.9 | - | PLACEHOLDER | placeholder | (فاضي: PLACEHOLDER) |
| `R_resp` | 4350 | m | مقترح | derived | [DERIVED] min(Cov_drone, v_drone × (T_resp − T_launch)) = min(11000, 15 × (300 − 10)) |
| `Pd_drone` | 88.5 | % | اقتراح | source | Avg of 3 UAV thermal human-detection studies: J. Imaging 2025 YOLOv8X (85%), Zhao et al. 2024 (recall 88.6%), YOLO-FLIR UAV study 2025 (recall 92%) |
| `Pc_drone` | 0.89 | - | proxy | proxy | khan_uav_thermal: YOLOv8s على HIT-UAV، precision = 0.891 |
| `C_PS` | TBD | SAR/unit | TBD | tbd |  |
| `Cov_PS` | TBD | m | TBD | tbd |  |
| `P_PS` | TBD | W/unit | TBD | tbd |  |
| `Pd_PS` | TBD | % | TBD | tbd |  |
| `Pc_PS` | TBD | % | TBD | tbd |  |
| `N_drone_avail` | 3 | units | توضيحي | assumption | الريبو: 3 درونز (ASSUMED: ILLUSTRATIVE، يعني رقم توضيحي للشكل) |
| `Loc_existing` | 16 كاميرا (توضيحي) | — | توضيحي | assumption | الريبو: كاميرا عند كل نقطة يقطع فيها طريق رئيسي الحد (بدل نقاط التفتيش)، والباقي على طول الحد قرب الطرق (أقل من 500 m) |
| `w_k` | Acc 35 / Cov 25 / Env 15 / Cost 10 / Pwr 10 / Priv 5 | % | مبدئي | assumption | قرار الفريق، مبرر بالمتطلبات (AD₀، AC₀، P₀) |
| `cell_size` | 1000 | m | مبدئي | assumption | [CHOSEN] ≥ Cov_CCTV و>> دقة الـ DAS (10 m) |
| `R_hot` | 0.464 | risk score | مبدئي | derived | [COMPUTED] main_zones.m: k-means على درجة خطر الخلايا |
| `R_cold` | 0.263 | risk score | مبدئي | derived | [COMPUTED] main_zones.m: k-means على درجة خطر الخلايا |
| `N_cells` | 139 (36 / 56 / 47) | cells | مبدئي | derived | [COMPUTED] main_zones.m، cell_size = 1 km |
| `L_zone` | 39.4 / 59.0 / 47.1 | km | مبدئي | derived | [COMPUTED] main_zones.m |
| `lambda_hot` | 11-20 | events/day لكل الزون | TBD | assumption | افتراض |
| `lambda_neutral` | 8-10 | events/day لكل الزون | TBD | assumption | افتراض |
| `lambda_cold` | 1-2 | events/day لكل الزون | مفترض | assumption | افتراض |
| `C_total` | TBD | SAR | TBD | tbd |  |
| `L_fiber_sim` | 18.18 | km | مقترح | assumption | الريبو: طول القناة الفعلي (L_channel) |
| `tau_pulse` | 97.9 | ns | مقترح | derived | [DERIVED] τ = 2·n_g·dz_res / c، مع dz_res = 10 m وn_g = 1.4682 |
| `f_s` | 51 | MHz | مقترح | derived | [DERIVED] من channel spacing = 2 m: f_s = c / (2·n_g·Δz) |
| `f_PRR` | ≤ 5.6 | kHz | مقترح | derived | [DERIVED] f_PRR ≤ c / (2·n_g·L_channel) |
| `N_MC` | 10000 | runs | ان شاء الله | derived | حساب إحصائي: N = z²·p(1−p)/E²، بثقة 95% وهامش ±0.27% |
| `lambda_op` | 1550 | nm | معتمد | source | Datasheet A1-NEO |
| `T_op` | 5 – 40 (رطوبة لين 80%) | °C | معتمد | source | Datasheet A1-NEO |
| `T_store` | −10 – 60 | °C | معتمد | source | Datasheet A1-NEO |
| `FAR_per_km_day` | 0.01 | alarms/km/day | PLACEHOLDER | placeholder |  |
| `dx_prof` | 0.4 | m | مفترض | source | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md); FEBUS A1-NEO datasheet |
| `GL_prof` | 0.8 | m | مفترض | source | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md) |
| `fs_prof` | 500 | Hz | مفترض | source | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md) |
| `SNR_min_prof` | 12 | dB | مفترض | assumption | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md) |
| `n_steps_min` | 8 | steps | مفترض | source | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md) |
| `d_lane_max` | 3 | m | مفترض | source | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md) |
| `height_unc` | 8 | cm | مفترض | assumption | Engyom/DAS- v2.2-sim (docs/TECHNICAL_REPORT.md, integration/README.md) + literature review of Yomna |
| `dh_reid_max` | 25 | cm | PLACEHOLDER | placeholder | Yomna (literature review), 22 Nov 2026 |
| `Pc_DAS_public` | TBD | - | TBD | tbd | our experiment on the figshare 10.6084/m9.figshare.27004732 dataset |
| `d_track_m` | 300 | m | ASSUMED | assumption | ASSUMED (no source) |
| `d_urban_m` | 1000 | m | ASSUMED | assumption | ASSUMED (no source) |
| `slope_steep_deg` | 20 | deg | ASSUMED | assumption | ASSUMED (no source) |
| `wadi_depth_m` | 3 | m | ASSUMED | proxy | ASSUMED (no source) |
| `wadi_slope_max_deg` | 12 | deg | ASSUMED | proxy | ASSUMED (no source) |
| `w_entry_wadi` | 3 | - | ASSUMED | assumption | ASSUMED (no source) |
| `w_entry_track` | 2 | - | ASSUMED | assumption | ASSUMED (no source) |
| `w_entry_urban` | 2 | - | ASSUMED | assumption | ASSUMED (no source) |
| `p_type_wadi` | 0.45/0.20/0.25/0.05/0.05 | - | ASSUMED | assumption | ASSUMED (no source) |
| `p_type_track` | 0.30/0.10/0.50/0.05/0.05 | - | ASSUMED | assumption | ASSUMED (no source) |
| `p_type_urban` | 0.55/0.20/0.10/0.05/0.10 | - | ASSUMED | assumption | ASSUMED (no source) |
| `p_type_slope` | 0.55/0.15/0.00/0.10/0.20 | - | ASSUMED | assumption | ASSUMED (no source) |
| `p_type_flat` | 0.50/0.20/0.15/0.05/0.10 | - | ASSUMED | assumption | ASSUMED (no source) |
| `v_walk` | 1.4 | m/s | ASSUMED | assumption | ASSUMED (no source) |
| `v_run` | 3.5 | m/s | ASSUMED | assumption | ASSUMED (no source) |
| `v_vehicle_off` | 8 | m/s | ASSUMED | assumption | ASSUMED (no source) |
| `dur_dig_s` | 300 | s | ASSUMED | assumption | ASSUMED (no source) |
| `dur_climb_s` | 60 | s | ASSUMED | assumption | ASSUMED (no source) |
| `heading_sigma` | 0.12 | rad/sqrt(s) | ASSUMED | assumption | ASSUMED (no source) |
| `heading_pull` | 0.02 | 1/s | ASSUMED | assumption | ASSUMED (no source) |
| `d_inward_end_m` | 600 | m | ASSUMED | assumption | ASSUMED (no source) |
| `t_traj_max_s` | 1800 | s | ASSUMED | assumption | ASSUMED (no source) |
| `lam_animal_km_day` | 3 | events/km/day | PLACEHOLDER | placeholder | ASSUMED (no source) |
| `n_vehicle_site_day` | 100 | vehicles/day/site | PLACEHOLDER | placeholder | ASSUMED (no source) |
| `v_vehicle_road` | 22 | m/s | ASSUMED | assumption | ASSUMED (no source) |
| `lam_noise_km_day` | 20 | events/km/day | PLACEHOLDER | placeholder | ASSUMED (no source) |
| `L_win_m` | 300 | m | PLACEHOLDER | placeholder | design choice (DAS-Simulation engine on a short window) |
| `T_win_s` | 2.0 | s | PLACEHOLDER | placeholder | design choice; DAS-Simulation default recording 2 s |
| `fs_win_hz` | 510 | Hz | PLACEHOLDER | placeholder | design choice (footstep content 30 to 120 Hz) |
| `det_k_sigma` | 6 | - | ASSUMED | assumption | ASSUMED (no source) |
| `coupling_sigma` | 0.4 | - | ASSUMED | assumption | ASSUMED (no source) |
| `lib_n_per_bin` | 12 | sims | ASSUMED | assumption | ASSUMED (no source) |
| `p_along` | 0.10 | - | ASSUMED | assumption | ASSUMED (no source) |
| `d_along_m` | 60 | m | ASSUMED | assumption | ASSUMED (no source) |
| `d_lane_mean_m` | 1.5 | m | ASSUMED | assumption | ASSUMED (no source) |
| `step_len_m` | 0.7 | m | ASSUMED | assumption | Yomna simulation (step length = 0.415 x height, 170 cm) |
| `T_clf_s` | 1.0 | s | ASSUMED | assumption | design choice |
| `Pc_animal_placeholder` | 0.80 | - | PLACEHOLDER | placeholder | none (PLACEHOLDER) |
| `t_proc_s` | 1.0 | s | PLACEHOLDER | placeholder | none (PLACEHOLDER) |
| `t_ai_s` | 0.13 | s | ASSUMED | assumption | DASViT1D README (repository), accessed 2026-11-22 |
| `d_road_nonthreat_m` | 30 | m | ASSUMED | assumption | ASSUMED (no source) |
| `t_cam_s` | 5 | s | PLACEHOLDER | placeholder | none (PLACEHOLDER) |
| `T_mission_s` | 900 | s | PLACEHOLDER | placeholder | none (PLACEHOLDER) |
| `v_patrol` | 20 | m/s | ASSUMED | assumption | ASSUMED (no source) |
| `k_road_patrol` | 1.4 | - | ASSUMED | assumption | ASSUMED (no source) |
| `T_patrol_busy_s` | 1800 | s | PLACEHOLDER | placeholder | none (PLACEHOLDER) |
| `d_site_nonthreat_m` | 100 | m | ASSUMED | assumption | ASSUMED (no source) |
| `p_site_clear` | 0.99 | - | PLACEHOLDER | placeholder | none (PLACEHOLDER) |
| `dual_verify` | 0 | - | ASSUMED | assumption | scenario switch |
| `reid_pos_sd_das_m` | 1.0 | m | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pos_sd_cam_fixed_m` | 1.0 | m | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_speed_sd_das` | 0.05 | m/s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_speed_sd_cam` | 0.1 | m/s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_cad_sd_das` | 2.0 | steps/min | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_cad_sd_cam` | 3.0 | steps/min | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_cad_cam_available` | 1 | - | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_height_sd_das` | 8.0 | cm | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_height_sd_cam` | 5.0 | cm | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pop_speed_mean` | 1.3 | m/s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pop_speed_sd` | 0.2 | m/s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pop_height_mean` | 165.0 | cm | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pop_height_sd` | 8.0 | cm | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pop_cad_mean` | 110.0 | steps/min | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pop_cad_sd` | 8.0 | steps/min | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pair_gap_m` | 1.0 | m | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pair_dv` | 0.02 | m/s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pair_dcad` | 1.0 | steps/min | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_n_people` | 20 | people | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_n_windows` | 3 | windows | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_window_s` | 10.0 | s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_group_dist_m` | 2.0 | m | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_group_dv` | 0.15 | m/s | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_gate_sigma` | 3.0 | sigma | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_margin` | 4.0 | cost | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_target_decided_acc` | 0.97 | - | ASSUMED | assumption | docs/ReID_Design_and_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), section 1 and 3 |
| `reid_pos_sd_cam_drone_base_m` | 2.5 | m | proxy | proxy | Nalamothu et al. 2024, arXiv 2410.12556 (mean horizontal error 1.3 / 2.5 / 2.9 m at 10 / 20 / 30 m altitude, 3.6 m at 45 deg), converted to a per-axis sigma by  |
| `reid_pos_sd_cam_drone_opt_m` | 1.5 | m | proxy | proxy | Nalamothu et al. 2024, arXiv 2410.12556 (mean horizontal error 1.3 / 2.5 / 2.9 m at 10 / 20 / 30 m altitude, 3.6 m at 45 deg), converted to a per-axis sigma by  |
| `reid_pos_sd_cam_drone_pess_m` | 5.0 | m | ASSUMED | assumption | none yet (source pending) |
| `D3_installation` | buried | - | decided | source | project decision 23 Nov 2026 |
| `p_group` | 0 | - | ASSUMED | assumption | ASSUMED (no source) |
| `persons_per_patrol` | 2 | persons/patrol | ASSUMED | assumption | ASSUMED (no source) |
| `group_gap_m` | 1.5 | m | ASSUMED | assumption | ASSUMED (no source) |
| `siting_road_m` | 200 | m | ASSUMED | assumption | ASSUMED (no source) |
| `siting_slope_pct` | 10 | % | ASSUMED | assumption | ASSUMED (no source) |
| `siting_water_m` | 50 | m | ASSUMED | assumption | ASSUMED (no source) |
| `siting_search_km` | 3 | km | ASSUMED | assumption | ASSUMED (no source) |
| `siting_leadin_factor` | 1.4 | - | ASSUMED | assumption | ASSUMED (no source) |
| `siting_dstar_rule` | lower 95 % limit of monotone Pd(d) >= Pd_DAS | - | ASSUMED | assumption | Project lead decision 23 Nov 2026 (rule set before seeing the dense result) |
| `siting_inside_min_m` | 50 | m | ASSUMED | assumption | ASSUMED (no source) |
| `siting_inside_max_m` | 200 | m | ASSUMED | assumption | ASSUMED (no source) |
| `siting_checkpoint_exempt` | yes (5 checkpoints) | - | ASSUMED | assumption | ASSUMED (project lead 23 Nov 2026: a checkpoint already has buildings and infrastructure) |
| `d_star_DAS` | 14.75 | km | SIMULATED | derived | SIMULATED (rule siting_dstar_rule; FEBUS A1-NEO, alpha 0.2 dB/km datasheet, other engine inputs ASSUMED) |
| `N_DAS_int_siting` | 6 | units | SIMULATED | derived | DERIVED (siting MILP, branch interrogator-siting 42eadb7) |
| `C_total_siting` | 13014986 | SAR | SIMULATED | derived | DERIVED (siting MILP) |
| `C_shelter_checkpoint` | 30000 | SAR/unit | ASSUMED | assumption | ASSUMED: 25 % of C_shelter (no source) |
| `shelter_temp_range` | 5-40 | degC | ASSUMED | assumption | Project lead 24 Nov 2026 (cabin must keep the device at 5-40 degC); datasheet value to be confirmed |
| `cooling_share_of_site_load` | 0.5 | - | SIMULATED | derived | [DERIVED] P_shelter / (P_DAS + P_shelter); gsma_coolsure: 30-50 % |
| `E_shelter_cooling_kWh_yr` | 1489.2 | kWh/yr | SIMULATED | derived | [DERIVED] 170 W x 8760 h / 1000 |
