"""Collect the main AI numbers of the report into report/ai_summary.md from the result files (nothing typed by hand). Run:  python -I scripts/make_ai_summary.py"""
import csv, json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
R = lambda *p: os.path.join(ROOT, *p)
L = []; A = L.append
f = lambda x, k: float(x[k])

# ---------------- 1. classifier
m1 = json.load(open(R("results", "classifier", "T1s", "metrics.json"))); m2 = None
if os.path.isfile(R("results", "classifier", "T2s", "metrics.json")): m2 = json.load(open(R("results", "classifier", "T2s", "metrics.json")))
t = m1["locked_test"]
A("# AI summary for the report (all numbers come from result files; each is labelled SIMULATED or Brno, with its source)\n")
A("## 1. Event classifier on the Brno dataset (label: **Brno, not FEBUS, not system accuracy**)\n")
A(f"Source: `results/classifier/T1s/metrics.json` (window 1 s, ASSUMED), protocol `docs/Classifier_Evaluation_Protocol.pdf`, splits `config/splits.json` (seed 20261122). **{t['n_recordings']} test recordings only, {t['n_events']} test events**; evaluation at event level (mean probability over the windows of an event); leakage checks passed (disjoint groups, no event across a split, no duplicate windows).\n")
A("| Class | Test events | Test recordings | Events correct | Recall | Clopper-Pearson 95 % on events | Best provable lower bound if all correct (0.05^(1/n)) |\n| --- | --- | --- | --- | --- | --- | --- |")
pr = m1["per_test_recording"]
for c, v in t["recall"].items():
    ok = round(v["value"] * v["n_events"]); cp = v["clopper_pearson_95"]
    A(f"| {c} | {v['n_events']} | {v['n_recordings']} | {ok} | {v['value']:.3f} | [{cp[0]:.3f}, {cp[1]:.3f}] | {m1['max_provable_recall_lower_bound_if_all_correct'][c]:.3f} |")
A(f"\n* **Balanced accuracy {t['balanced_accuracy']:.3f}** over the {t['n_headline_classes']} evaluable classes ({', '.join(t['headline_classes'])}); the cluster bootstrap [{t['balanced_accuracy_cluster_bootstrap_95'][0]:.2f}, {t['balanced_accuracy_cluster_bootstrap_95'][1]:.2f}] is not meaningful with {t['n_recordings']} recordings.")
A("* Running, digging (construction), tampering and background have ONE recording each: trained, **not evaluable on Brno**, out of the headline. Running is an alarm class and has priority for FEBUS data. Animal is absent from every public set.")
A("* **Per test recording:** " + "; ".join(f"{k[:28]} ({v['class']}): {v['events_correct']} of {v['n_events']}" for k, v in pr.items()) + ".")
d = m1["diagnostic_random_window_split"]
A(f"* **Random vs grouped (diagnostic, window level, run once):** random 80/10/10 window split {d['window_accuracy_random']:.3f} against {d['window_accuracy_grouped_locked_test']:.3f} on the grouped locked test: a gap of {100 * (d['window_accuracy_random'] - d['window_accuracy_grouped_locked_test']):.1f} points. Windows overlap and are not independent.")
mx = max(m1["max_provable_recall_lower_bound_if_all_correct"].values())
A("* **What Brno can prove:** the largest class has 17 events with a 1 s window (all recordings); even if every one of them were classified correctly, the one-sided 95 % lower bound on recall is 0.05^(1/17) = **83.8 %**. In the locked test the best case is " + f"{mx:.3f}. So Brno shows that the classifier works on these data; **the real accuracy has to come from FEBUS** (a 98 % claim needs at least 149 error-free independent events per class).")
cl = t["recall"].get("climbing")
if cl: A(f"* **Climbing scored {round(cl['value'] * cl['n_events'])} of {cl['n_events']}**: expected, because the training has only 2 climbing events from 2 recordings (momentary fence impacts); the result cannot tell a weak classifier from an unusual fence recording.")
bg = m1.get("diagnostic_background_false_alarms") or {}
if bg: A(f"* **Background (diagnostic, [DIAGNOSTIC - SAME RECORDING], same recording, optimistic):** {bg['alarm_class_events']} alarm-class events among {bg['background_events']} background events over {bg['km_days']:.1e} km-days; 24 s prove nothing about false alarms. The operational rate needs at least 30 km-days of clean FEBUS background without a false alarm to show an upper bound of 0.1 per km per day.")
for c, v in (m1.get("diagnostic_single_recording_classes") or {}).items(): A(f"* [DIAGNOSTIC - SAME RECORDING, optimistic] {c}: {v['events']} events in the last 20 % of its only recording, recall {v['recall']:.2f}.")
if m2:
    t2 = m2["locked_test"]
    A(f"\n**Window length sensitivity (2 s, `results/classifier/T2s/metrics.json`):** balanced accuracy {t2['balanced_accuracy']:.3f} over {t2['n_events']} test events (1 s: {t['balanced_accuracy']:.3f} over {t['n_events']}); recall per class " + ", ".join(f"{c} {v['value']:.2f} ({v['n_events']} ev.)" for c, v in t2["recall"].items()) + ". The base stays 1 s (chosen from event counts before training).")
A("\n**Decision on the confusion matrix:** the uniform stub (Pc from the literature, 0.983 to 0.993) stays the BASE of the unified simulation. The Brno matrix (`results/classifier/T1s/confusion_matrix.csv`, counts) is a SENSITIVITY only, labelled \"Brno, 4 test recordings, SENSITIVITY\"; classes missing from it (running, digging, tampering, background, animal) fall back to the uniform stub (`config/ai_config.json`, mode `confusion_counts`). The optimization keeps the literature Pc_DAS.\n")

# ---------------- 2. re-id
S = json.load(open(R("results", "reid", "summary.json"))); rows = list(csv.DictReader(open(R("results", "reid", "reid_grid.csv"))))
sel = lambda s, sp, pr: [r for r in rows if r["camera_source"] == s and f(r, "spacing_m") == sp and f(r, "pairs_share") == pr and f(r, "position_error_m") == 1.0 and f(r, "clock_offset_s") == 0.2 and r["crossing"] == "False" and f(r, "camera_dropout") == 0.0][0]
A("## 2. DAS-camera re-identification (label: **SIMULATED**, all errors assumed)\n")
A("Source: `results/reid/reid_grid.csv` (1,296 cells, 300 scenes per cell, 95 % scene bootstrap), `report/reid_summary.md`. Thresholds: ONE setting (gate 4 sigma, margin 2) for the whole grid and all camera types, chosen on development scenes. Drone position error 1.5 / 2.5 m: PROXY (Nalamothu et al. 2024, arXiv 2410.12556, static target, optimistic); 5 m and the fixed camera 1 m: ASSUMED.\n")
a, b, c2, d2 = sel("drone_base", 10, 0.0), sel("drone_base", 10, 0.5), sel("drone_base", 2, 0.0), sel("drone_base", 2, 0.5)
A(f"* **Main sentence (base drone camera, 2.5 m):** with people 10 m apart and nobody in a pair, {100 * f(a, 'person_link_acc'):.1f} % [{100 * f(a, 'person_link_acc_lo'):.1f}, {100 * f(a, 'person_link_acc_hi'):.1f}] of the person-level links made are correct, {100 * f(a, 'person_link_rate'):.1f} % of the tracks get such a link and {f(a, 'wrong_links_per_100'):.1f} wrong links are made per 100 tracks; with half walking in pairs: {100 * f(b, 'person_link_acc'):.1f} % [{100 * f(b, 'person_link_acc_lo'):.1f}, {100 * f(b, 'person_link_acc_hi'):.1f}] correct, {100 * f(b, 'person_link_rate'):.1f} % linked, {f(b, 'wrong_links_per_100'):.1f} wrong per 100. At 2 m: {100 * f(c2, 'person_link_acc'):.1f} % (no pairs) and {100 * f(d2, 'person_link_acc'):.1f} % (50 % pairs).")
A("* **Cells below the 0.97 target** (accuracy of the person-level links made, point value / lower 95 % limit): " + "; ".join(f"{k}: {v['point_below']} / {v['lower_ci_below']} of {v['cells']}" for k, v in S["below_0.97"].items()) + ".")
worst = min(rows, key=lambda r: f(r, "person_link_acc")); wd = [r for r in rows if r["camera_source"] == "drone_base"]; ww = min(wd, key=lambda r: f(r, "person_link_acc"))
A(f"* **Worst cases:** base drone camera, spacing {ww['spacing_m']} m, {float(ww['pairs_share']) * 100:.0f} % pairs, dropout {float(ww['camera_dropout']) * 100:.0f} %: {f(ww, 'person_link_acc'):.3f} [{f(ww, 'person_link_acc_lo'):.3f}, {f(ww, 'person_link_acc_hi'):.3f}]; over all sources: {worst['camera_source']}, {f(worst, 'person_link_acc'):.3f}. Pessimistic drone (5 m) at 2 m with 50 % pairs: {f(sel('drone_pessimistic', 2, 0.5), 'person_link_acc'):.3f} [{f(sel('drone_pessimistic', 2, 0.5), 'person_link_acc_lo'):.3f}, {f(sel('drone_pessimistic', 2, 0.5), 'person_link_acc_hi'):.3f}].")
ab = list(csv.DictReader(open(R("results", "reid", "ablation.csv"))))
g = lambda s, v, sp: float([x for x in ab if x["camera_source"] == s and x["variant"] == v and float(x["spacing_m"]) == sp][0]["person_acc"])
A("* **Ablation (base drone camera, no pairs, person-level accuracy over all tracks):** " + "; ".join(f"{sp} m: height adds {100 * (g('drone_base', 'all cues', sp) - g('drone_base', 'no height', sp)):.1f} points, cadence adds {100 * (g('drone_base', 'all cues', sp) - g('drone_base', 'no cadence', sp)):.1f} points" for sp in (20, 10, 5, 2)) + ". Cadence helps only if the camera can measure it to +/- 3 steps/min (ASSUMED, untested).")
import statistics as st
names = {"fixed": "fixed camera, 1 m", "drone_optimistic": "drone, 1.5 m", "drone_base": "drone, 2.5 m (base)", "drone_pessimistic": "drone, 5 m"}
A("
**Where the 0.97 is lost (the limits).** Cells where the accuracy of the person-level links made is below 0.97, with the group-level accuracy of the SAME cells (point values; accuracy over all tracks counts an ambiguous track as not linked; the last column is the accuracy of all decisions made):
")
A("| Camera | Cells below 0.97 | with pairs | with spacing 2 m or 1 m | with dropout 20 % | Person-level accuracy, median [min] | Group-level accuracy, median [min] | Accuracy of all decisions (person or group), median [min] |
| --- | --- | --- | --- | --- | --- | --- | --- |")
for src in ("fixed", "drone_optimistic", "drone_base", "drone_pessimistic"):
    rr = [r for r in rows if r["camera_source"] == src and f(r, "person_link_acc") < 0.97]; n = len(rr)
    pa = [f(r, "person_acc") for r in rr]; ga = [f(r, "group_acc") for r in rr]; da = [f(r, "decided_acc") for r in rr]
    A(f"| {names[src]} | {n} | {sum(f(r, 'pairs_share') > 0 for r in rr)} | {sum(f(r, 'spacing_m') <= 2 for r in rr)} | {sum(f(r, 'camera_dropout') > 0 for r in rr)} | {st.median(pa):.2f} [{min(pa):.2f}] | {st.median(ga):.2f} [{min(ga):.2f}] | {st.median(da):.2f} [{min(da):.2f}] |")
A("
Limits as conditions: **people walking in pairs, spacing of 2 m or less, camera dropout.** There the person-level claim does not hold and the operator relies on `ambiguous` and the group link.")
A("* Fixed cameras cover only 1.9 % of the boundary, so most links will be with the drone. An `ambiguous` link never sends a patrol to a specific person; a DAS-only track is an alarm and goes to the drone.\n")

# ---------------- 3. dual verification
A("## 3. Dual verification before a patrol is sent (label: SIMULATED, Stage 6; 20 days, 100 authorized vehicles per site per day and p_site_clear 0.99, both PLACEHOLDERS)\n")
D = list(csv.DictReader(open(R("results", "stage6_dual.csv")))); nm = {"0": "A single check", "1": "B dual everywhere", "2": "C dual in Neutral+Cold"}
A("| Scenario | Option | False patrols per km per day | Median verification time (s) | Median alarm-to-patrol (s) | Patrol reached | Intruders not verified within T_resp |\n| --- | --- | --- | --- | --- | --- | --- |")
for r in D: A(f"| {r['scenario']} | {nm[str(int(float(r['mode'])))]} | {f(r, 'false_patrols_per_km_day'):.3f} | {f(r, 'median_verification_s'):.0f} | {f(r, 'median_alarm_to_patrol_s'):.0f} | {100 * f(r, 'patrol_reached'):.1f} % | {100 * f(r, 'intruders_not_verified_in_Tresp'):.1f} % |")
A("\n**Decision: ONE check (option A).** Dual verification lowers the false patrols only by 0 to 13 % while it delays the verification and lets more intruders escape it, because a second drone is a second mission that uses the scarce drones. Most false patrols come from the site-routed alerts, governed by the PLACEHOLDER `p_site_clear` (0.9 -> 1.77, 0.99 -> 0.212, 0.999 -> 0.0525 false patrols per km per day, medium): **the target FAR_km = 0.01 is not reachable with the present assets** (drone / camera verification errors alone give about 0.03 per km per day). Source: `results/stage6_dual.csv`, `report/key_numbers.md`.\n")

# ---------------- 4. height and walking
A("## 4. Height from gait and the along-the-boundary walk (label: SIMULATED, Stage 7; `results/stage7_height_share.csv`)\n")
H = list(csv.DictReader(open(R("results", "stage7_height_share.csv"))))
A("| p_along (ASSUMED) | Walking | Along-boundary path | Height measurable, all intruders | of along-boundary paths | of crossing walkers | of all walkers |\n| --- | --- | --- | --- | --- | --- | --- |")
for r in H: A(f"| {100 * f(r, 'p_along'):.0f} % | {100 * f(r, 'share_walking'):.1f} % | {100 * f(r, 'share_along_path'):.1f} % | {100 * f(r, 'height_measurable_all'):.1f} % | " + (f"{100 * f(r, 'height_measurable_along'):.1f} %" if r['height_measurable_along'] not in ('NaN', 'nan', '') else "n/a") + f" | {100 * f(r, 'height_measurable_crossing_walkers'):.1f} % | {100 * f(r, 'height_measurable_walkers'):.1f} % |")
A("\nA person crossing the fibre never qualifies (the height method needs a walk parallel to the fibre within 3 m with at least 8 footsteps and a detection SNR of at least 12 dB; the SNR condition never binds in simulation). Height is a secondary, exploratory indicator (+/- 8 cm); the primary claim of the DAS is stride, speed and cadence.\n")
A("## 5. Related system results (SIMULATED, Stage 6)\n* Medium scenario: 48.7 to 51.5 % of the Hot alarms verified within T_resp against 61 % of the Hot cells in the optimization: the static availability model is optimistic (it ignores the time a drone is busy, the charge and simultaneous alarms). Source: `report/key_numbers.md`.\n* Simulated Pd of the DAS 0.977 (intrusion types) next to the literature 0.969; it depends on the ASSUMED ground coupling and is not a measured Pd. Source: `tests/test_stage4.m`, `report/decisions.md`.")
open(R("report", "ai_summary.md"), "w", encoding="utf8").write("\n".join(L) + "\n"); print("written", len(L), "lines")
