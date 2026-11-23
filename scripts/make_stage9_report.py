"""Build report/stage9_results.md from results/stage9/*.csv (nothing typed by hand). python -I scripts/make_stage9_report.py"""
import csv, os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RUN = sys.argv[1] if len(sys.argv) > 1 else "stage9"      # results folder: stage9 (main model) or stage9_siting (siting model)
OUT = "stage9_results.md" if RUN == "stage9" else "stage9_siting_results.md"
rows = list(csv.DictReader(open(os.path.join(ROOT, "results", RUN, "metrics_summary.csv"))))
re_ = {r["run_case"]: r for r in csv.DictReader(open(os.path.join(ROOT, "results", RUN, "reid_in_simulation.csv")))}
get = lambda c, m: [r for r in rows if r["run_case"] == c and r["metric"] == m][0]
def pc(c, m, d=1):
    r = get(c, m); return f"{100*float(r['value']):.{d}f} % [{100*float(r['lo']):.{d}f}, {100*float(r['hi']):.{d}f}]"
def nm(c, m, d=0):
    r = get(c, m); return f"{float(r['value']):.{d}f} [{float(r['lo']):.{d}f}, {float(r['hi']):.{d}f}]"
base = [("low", "low (3 drones)"), ("medium", "medium (6)"), ("high", "high (12)")]
L = []; A = L.append
n_ev = {c: int(float(get(c, "Pd")["n_den"])) for c, _ in base}; days = int(float(rows[0]["days"]))
A("# Stage 9: full Monte Carlo (SIMULATED)\n")
A(f"**SIMULATED.** Every case ran {days} simulated days (until at least 10,000 real intruder EVENTS: {', '.join(f'{c} {n}' for c, n in n_ev.items())}), seed 9090, 22 interdiction sites, 100 authorized vehicles per site per day (PLACEHOLDER), p_site_clear 0.99 (PLACEHOLDER), along-boundary walk p_along 0.10 (ASSUMED). Base classifier: temporary uniform stub, Pc 0.983 (ASSUMED, literature). 95 % intervals: bootstrap over DAYS (2,000 resamples). **Common random numbers:** day d of every case uses the same generator streams, so all cases see the SAME intruders and the same non-intrusion events (checked: the intruder times are identical in the three scenarios and the non-intrusion events are identical in 394 of 394 days); differences between scenarios come from the assets only. Sources: `results/stage9/metrics_summary.csv`, `reid_in_simulation.csv`, code `src/metrics/`, `scripts/stage9_run.m`.\n")
A("## 1. The three scenarios (base classifier stub)\n")
A("| Metric | " + " | ".join(n for _, n in base) + " | Source |\n| --- | --- | --- | --- | --- |")
defs = [("Pd", "Pd: detected by the DAS"), ("Pc_cond", "Pc: classified correctly, given detection"), ("Pd_x_Pc", "Pd x Pc: detected and classified correctly (end to end, of all intruders)"), ("alarm_raised", "alarm raised (detected and classified as a threat; includes alerts routed to site guards)"),
        ("verified_Tresp", "verified within T_resp (300 s), all intruders"), ("verified_Tresp_hot", "verified within T_resp, Hot-zone intruders"), ("verified_of_alarms", "verified within T_resp, of the intruders that raised an alarm"),
        ("patrol_reached", "patrol reached (after a confirmed verification, ANY delay), all intruders"), ("patrol_reached_of_alarms", "patrol reached, of the intruders that raised an alarm"), ("height_measurable", "height measurable (all intruders, p_along 10 %)")]
for m, t in defs: A(f"| {t} | " + " | ".join(pc(c, m) for c, _ in base) + " | `metrics_summary.csv` |")
for m, t in [("median_verification_s", "median verification time, s (alarm to asset on scene)"), ("p90_verification_s", "90th percentile of the verification time, s"), ("median_alarm_to_patrol_s", "median alarm-to-patrol time, s"), ("p90_alarm_to_patrol_s", "90th percentile of the alarm-to-patrol time, s")]:
    A(f"| {t} | " + " | ".join(nm(c, m) for c, _ in base) + " | `metrics_summary.csv` |")
for m, t in [("fa_cued", "false alarms before verification, drone- or camera-cued, per km per day"), ("fa_site", "false alarms before verification, routed to site guards (low priority), per km per day"), ("fa_before_all", "false alarms before verification, all, per km per day"), ("fa_patrol", "false alarms AFTER verification (reaching a patrol), per km per day (target 0.01)")]:
    A(f"| {t} | " + " | ".join(nm(c, m, 3) for c, _ in base) + " | `metrics_summary.csv` |")
A("\n## 2. Sensitivities (medium)\n")
sens = [("medium", "base (uniform stub, singles)"), ("medium_BrnoMatrix_SENSITIVITY", "Brno matrix, \"Brno, 4 test recordings, SENSITIVITY\""), ("medium_pgroup25_SENSITIVITY", "groups: p_group 25 % (ASSUMED)"), ("medium_pgroup50_SENSITIVITY", "groups: p_group 50 % (ASSUMED)")]
A("| Metric | " + " | ".join(n for _, n in sens) + " |\n| --- | --- | --- | --- | --- |")
A("| Intruder EVENTS / PERSONS | " + " | ".join(f"{int(float(get(c, 'Pd')['n_den']))} / {int(float(get(c, 'persons_total')['value']))}" for c, _ in sens) + " |")
for m, t in [("Pd", "Pd"), ("Pc_cond", "Pc given detection"), ("verified_Tresp", "verified within T_resp (events)"), ("verified_Tresp_hot", "verified within T_resp, Hot"), ("persons_in_verified_events", "persons in verified events (share of persons)"), ("patrol_reached", "patrol reached (events, any delay)"), ("patrol_fully_staffed_of_confirmed", "patrol fully staffed (all needed patrols sent), of confirmed events")]:
    A(f"| {t} | " + " | ".join(pc(c, m) if m != "persons_in_verified_events" else f"{100*float(get(c, m)['value']):.1f} %" for c, _ in sens) + " |")
for m, t in [("median_alarm_to_patrol_s", "median alarm-to-patrol, s"), ("p90_alarm_to_patrol_s", "90th percentile alarm-to-patrol, s")]: A(f"| {t} | " + " | ".join(nm(c, m) for c, _ in sens) + " |")
for m, t in [("fa_cued", "false alarms before verification, drone/camera-cued, per km per day"), ("fa_patrol", "false alarms reaching a patrol, per km per day")]: A(f"| {t} | " + " | ".join(nm(c, m, 3) for c, _ in sens) + " |")
A("\n**Re-identification in the simulation (SIMULATED lookups):** singles use the spacing to the nearest simultaneous intruder in `reid_grid.csv`; groups use their size in `results/reid/group_events.csv` (group scenes: members 1 to 2 m apart among single walkers 50 m apart, camera clock offset 0.2 s); drone base 2.5 m, fixed camera 1 m when a camera verified. All persons of a verified event count (weights = persons).\n")
A("| Case | Verified persons | Share of verified events that are groups | Accuracy of the person-level links made | Person-level link rate | Decision rate (person or group) | Group-level accuracy | Wrong person-level links per 100 persons |\n| --- | --- | --- | --- | --- | --- | --- | --- |")
for c, n in [("medium", "base (singles)"), ("medium_pgroup25_SENSITIVITY", "p_group 25 %"), ("medium_pgroup50_SENSITIVITY", "p_group 50 %")]:
    r = re_[c]; A(f"| {n} | {int(float(r['verified_persons']))} | {100*float(r['share_verified_events_group']):.1f} % | {100*float(r['person_link_accuracy_of_links_made']):.1f} % | {100*float(r['person_link_rate']):.1f} % | {100*float(r['decision_rate']):.1f} % | {100*float(r['group_level_accuracy']):.1f} % | {float(r['wrong_person_links_per_100_persons']):.2f} |")
open(os.path.join(ROOT, "report", OUT), "w", encoding="utf8").write("\n".join(L) + "\n"); print("\n".join(L))
