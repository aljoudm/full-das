"""Plot and summary.json of the re-identification grid (SIMULATED). python -m reid.plots"""
import csv, json, os
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from . import config as rc

OUT = os.path.join(rc.ROOT, "results", "reid")
rows = list(csv.DictReader(open(os.path.join(OUT, "reid_grid.csv"))))
f = lambda r, k: float(r[k])
sel = lambda src, sp, pr: [r for r in rows if r["camera_source"] == src and f(r, "spacing_m") == sp and f(r, "pairs_share") == pr and f(r, "position_error_m") == 1.0 and f(r, "clock_offset_s") == 0.2 and r["crossing"] == "False" and f(r, "camera_dropout") == 0.0][0]
fig, axs = plt.subplots(1, 3, figsize=(13, 4))
for ax, (met, title) in zip(axs, [("person_link_acc", "accuracy of person-level links made"), ("person_link_rate", "share of tracks that get a person-level link"), ("wrong_links_per_100", "wrong person-level links per 100 tracks")]):
    for src, col in zip(rc.CAMERA_SOURCES, ["k", "tab:green", "tab:blue", "tab:red"]):
        for pr, ls in [(0.0, "-"), (0.5, "--")]:
            sp = [50, 20, 10, 5, 2, 1]; r = [sel(src, s, pr) for s in sp]
            y = [f(x, met) for x in r]; lo = [f(x, met + "_lo") for x in r]; hi = [f(x, met + "_hi") for x in r]
            ax.plot(sp, y, ls, color=col, marker="o", ms=3, label=f"{src}, {int(pr * 100)}% pairs"); ax.fill_between(sp, lo, hi, color=col, alpha=0.12)
    ax.set_xscale("log"); ax.invert_xaxis(); ax.set_xlabel("average spacing between people [m]"); ax.set_title(title, fontsize=9)
    if met == "person_link_acc": ax.axhline(0.97, color="grey", lw=0.8, ls=":"); ax.set_ylim(0.8, 1.005)
axs[0].legend(fontsize=6); fig.suptitle("DAS-camera re-identification, SIMULATED (all errors assumed), clock 0.2 s, no crossing, no dropout, 300 scenes per point, 95 % scene bootstrap", fontsize=8)
fig.tight_layout(); fig.savefig(os.path.join(OUT, "accuracy_vs_spacing.png"), dpi=140)
th = json.load(open(os.path.join(OUT, "thresholds.json")))
summ = {"label": "SIMULATED: all errors and population spreads are ASSUMED (drone position error 1.5 / 2.5 m PROXY from Nalamothu et al. 2024, 5 m ASSUMED)", "thresholds": {"gate_sigma": th["gate_sigma"], "margin": th["margin"], "scope": "ONE setting for the whole grid and for all four camera sources, chosen once on development scenes (seed base 9,000,000; fixed camera 1 m, clock 0.2 s, 10 % dropout, spacing 10/5/2, pairs 0/25/50 %)"},
        "cells": len(rows), "scenes_per_cell": 300, "bootstrap": "scene bootstrap, 2000 resamples, 95 %", "below_0.97": {}}
for src in rc.CAMERA_SOURCES:
    rr = [r for r in rows if r["camera_source"] == src]
    summ["below_0.97"][src] = {"cells": len(rr), "point_below": sum(f(r, "person_link_acc") < 0.97 for r in rr), "lower_ci_below": sum(f(r, "person_link_acc_lo") < 0.97 for r in rr), "min_point": min(f(r, "person_link_acc") for r in rr)}
json.dump(summ, open(os.path.join(OUT, "summary.json"), "w"), indent=1); print("ok")
