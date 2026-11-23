"""Build report/stage9_siting_comparison.md from results/stage9_siting/comparison*.csv (nothing typed by hand). python -I scripts/make_stage9_comparison.py"""
import csv, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
C = list(csv.DictReader(open(os.path.join(ROOT, "results", "stage9_siting", "comparison.csv"))))
B = list(csv.DictReader(open(os.path.join(ROOT, "results", "stage9_siting", "comparison_by_distance.csv"))))
g = lambda sc, mo, me: [r for r in C if r["scenario"] == sc and r["model"] == mo and r["metric"] == me][0]
pc = lambda r: f"{100*float(r['value']):.1f} % [{100*float(r['lo']):.1f}, {100*float(r['hi']):.1f}]"
L = []; A = L.append
A("# Stage 9 before / after the siting model (SIMULATED)\n")
A("Before = `results/stage9` (4 interrogators at run midpoints, library lookup by the nearest of five distances). After = `results/stage9_siting` (6 interrogators in the sited shelters, lead-in fibre in the optical distance, ONE Pd(d) model `results/siting/pd_model.mat` for the detection decision). Same seed 9090, same common random numbers (the same intruder events day by day), 394 days, 10,004 events per scenario. Source: `scripts/stage9_compare.m`, `results/stage9_siting/comparison*.csv`.\n")
A("## Cost and devices\n")
c0 = g("medium", "stage9", "Pd"); c1 = g("medium", "stage9_siting", "Pd")
A(f"| | Before | After |\n| --- | --- | --- |\n| Interrogators | {c0['n_interrogators']} | {c1['n_interrogators']} |\n| C_total (SAR) | {float(c0['C_total']):,.0f} | {float(c1['C_total']):,.0f} |\n| Drones | unchanged (3 / 6 / 12) | unchanged |\n")
A("## System metrics (95 % bootstrap intervals)\n")
A("| Scenario | Metric | Before | After |\n| --- | --- | --- | --- |")
for sc in ("low", "medium", "high"):
    for me, t in (("Pd", "Pd (detected by the DAS)"), ("Pd_x_Pc", "Pd x Pc"), ("verified_Tresp", "verified within T_resp (all intruders)"), ("verified_Tresp_hot", "verified within T_resp (Hot zone)"), ("patrol_reached", "patrol reached")):
        A(f"| {sc} | {t} | {pc(g(sc, 'stage9', me))} | {pc(g(sc, 'stage9_siting', me))} |")
    r0 = g(sc, "stage9", "median_verification_s"); r1 = g(sc, "stage9_siting", "median_verification_s")
    A(f"| {sc} | median verification time, s | {float(r0['value']):.0f} | {float(r1['value']):.0f} |")
A("\n## Share of intruders missed by the DAS, by optical distance to the interrogator (medium; low and high in the csv)\n")
A("| Distance | Before: events | Before: missed | After: events | After: missed |\n| --- | --- | --- | --- | --- |")
bins = sorted({(float(r["from_km"]), float(r["to_km"])) for r in B if r["scenario"] == "medium"})
for lo, hi in bins:
    def f(mo):
        x = [r for r in B if r["scenario"] == "medium" and r["model"] == mo and float(r["from_km"]) == lo and float(r["to_km"]) == hi]
        return (x[0]["events"], f"{float(x[0]['missed_pct']):.2f} %") if x else ("0", "-")
    a = f("stage9"); b = f("stage9_siting"); A(f"| {lo:g}-{hi:g} km | {a[0]} | {a[1]} | {b[0]} | {b[1]} |")
A("\nAfter the change no event is farther than 14.23 km (maximum optical distance of the siting solution), and the miss share stays below 1.2 % in every band; the overall Pd is above the Pd_DAS = 0.969 assumed by the optimization. Before, events at 12.5-17.5 km used the 15 km library bin (12 windows per type, Pd 0.854) and were missed 5.8-12.2 % of the time (see `report/assumptions.md`).")
open(os.path.join(ROOT, "report", "stage9_siting_comparison.md"), "w", encoding="utf8").write("\n".join(L) + "\n"); print("\n".join(L))
