"""Metrics, scene bootstrap, ablations, threshold choice and plots for the re-identification evaluation (design section 4). SIMULATED, all parameters ASSUMED.

    python -I -m reid.evaluate tune        choose gate and margin on DEVELOPMENT scenes (different seed), write results/reid/thresholds.json, then frozen
    python -I -m reid.evaluate grid [n]    the factorial grid for the fixed camera and the three drone cases (n scenes per cell, default 300)
    python -I -m reid.evaluate ablation    remove one cue at a time
Metrics (pooled over scenes, 95 % scene bootstrap, 2000 resamples): person-level accuracy, group-level accuracy, decision rate, accuracy of decided links,
wrong-link rate per 100 DAS tracks, IDF1 over the association windows of a scene (IDTP = correct person links, IDFP = wrong person links, IDFN = tracks with a camera
counterpart that were not correctly linked; a simplification of the MOT definition)."""
import os, sys, json, itertools, time
from multiprocessing import Pool
import numpy as np
from . import config as rc
from .associate import associate
from .simulate import make_scene

OUT = os.path.join(rc.ROOT, "results", "reid"); os.makedirs(OUT, exist_ok=True)
COLS = ["n_das", "n_cp", "person_correct", "group_correct", "decided", "decided_correct", "wrong_person_links", "wrong_group_links", "linked", "linked_correct"]


def score_window(das, cam, links):
    cam_by_person = {c.truth_person: c for c in cam}; cam_by_id = {c.id: c for c in cam}
    r = dict.fromkeys(COLS, 0); r["n_das"] = len(das)
    for d, l in zip(das, links):
        has = d.truth_person in cam_by_person; r["n_cp"] += has
        if l["status"] == "linked":
            c = cam_by_id[l["cam_id"]]; ok_p = c.truth_person == d.truth_person; ok_g = c.truth_group == d.truth_group
            r["decided"] += 1; r["decided_correct"] += ok_g; r["linked"] += 1; r["linked_correct"] += ok_p; r["person_correct"] += ok_p and has
            r["group_correct"] += ok_g and has; r["wrong_person_links"] += not ok_p; r["wrong_group_links"] += not ok_g
        elif l["status"] == "group-linked":
            gs = {cam_by_id[i].truth_group for i in l["candidates"]}; ok_g = (gs == {d.truth_group}) and has
            r["decided"] += 1; r["decided_correct"] += ok_g; r["group_correct"] += ok_g; r["wrong_group_links"] += not ok_g
    return r


def run_scene(args):
    cfg, spacing, pairs, crossing, dropout, seed = args
    rng = np.random.default_rng(seed); tot = dict.fromkeys(COLS, 0)
    for das, cam in make_scene(cfg, spacing, pairs, crossing, dropout, rng):
        for k, v in score_window(das, cam, associate(das, cam, cfg)).items(): tot[k] += v
    return [tot[c] for c in COLS]


def pooled(M):
    """Pooled metrics from a (scenes x COLS) count matrix."""
    s = M.sum(0); g = dict(zip(COLS, s)); idtp = g["linked_correct"] - 0; idfp = g["wrong_person_links"]; idfn = g["n_cp"] - g["person_correct"]
    div = lambda a, b: float(a / b) if b > 0 else float("nan")
    return {"person_acc": div(g["person_correct"], g["n_cp"]), "group_acc": div(g["group_correct"], g["n_cp"]), "decision_rate": div(g["decided"], g["n_das"]),
            "decided_acc": div(g["decided_correct"], g["decided"]), "wrong_links_per_100": 100 * div(g["wrong_person_links"], g["n_das"]), "idf1": div(2 * idtp, 2 * idtp + idfp + idfn)}


def bootstrap(M, B=2000, seed=0):
    rng = np.random.default_rng(seed); n = len(M); res = {k: [] for k in pooled(M)}
    for _ in range(B):
        p = pooled(M[rng.integers(0, n, n)])
        for k, v in p.items(): res[k].append(v)
    return {k: (float(np.nanpercentile(v, 2.5)), float(np.nanpercentile(v, 97.5))) for k, v in res.items()}


def run_cell(cfg, spacing, pairs, crossing, dropout, n_scenes, seed0):
    return np.array([run_scene((cfg, spacing, pairs, crossing, dropout, seed0 + i)) for i in range(n_scenes)])


def _cell_job(a):
    key, cfg, sp, pr, cr, dr, n, seed = a
    M = run_cell(cfg, sp, pr, cr, dr, n, seed); p = pooled(M); ci = bootstrap(M)
    return key, p, ci


def tune():
    """Choose the gate and the margin on DEVELOPMENT scenes (seeds 9,000,000 and up, never used for the results): the smallest margin whose accuracy of decided links
    reaches reid_target_decided_acc over a mix of crowded and pair scenes, then the gate with the best decision rate. Written once, then frozen."""
    target = rc.raw()["target_decided_acc"]; th = os.path.join(OUT, "thresholds.json")
    if os.path.isfile(th): print("thresholds already frozen:", open(th).read()); return
    mix = [(sp, pr, cr) for sp in (10, 5, 2) for pr in (0.0, 0.25, 0.5) for cr in (False, True)]
    best = None
    for gate in (2.0, 3.0, 4.0):
        for margin in (0.0, 1.0, 2.0, 4.0, 8.0, 16.0):
            tot = np.zeros(len(COLS))
            for k, (sp, pr, cr) in enumerate(mix):
                cfg = rc.load("fixed", clock_sd=0.2, use_frozen=False); cfg.gate_sigma = gate; cfg.margin = margin
                tot += run_cell(cfg, sp, pr, cr, 0.1, 20, 9_000_000 + 1000 * k).sum(0)
            p = pooled(tot[None, :]); print(f"gate {gate} margin {margin}: decided acc {p['decided_acc']:.3f}, decision rate {p['decision_rate']:.3f}")
            if p["decided_acc"] >= target and (best is None or p["decision_rate"] > best[0]): best = (p["decision_rate"], gate, margin, p["decided_acc"])
    if best is None: best = (0.0, 3.0, 16.0, float("nan"))
    json.dump({"gate_sigma": best[1], "margin": best[2], "decision_rate_dev": best[0], "decided_acc_dev": best[3], "target": target, "dev_seed_base": 9_000_000,
               "rule": "highest decision rate with decided accuracy >= target on development scenes"}, open(th, "w"), indent=1)
    print("frozen:", best)


def grid(n_scenes=300, procs=4):
    import csv
    spacings = (50, 20, 10, 5, 2, 1); pairs = (0.0, 0.25, 0.5); poss = (0.5, 1.0, 3.0); clocks = (0.0, 0.2, 0.5); crosses = (False, True); drops = (0.0, 0.2)
    jobs = []
    for src in rc.CAMERA_SOURCES:
        for sp, pr, ps, ck, cr, dr in itertools.product(spacings, pairs, poss, clocks, crosses, drops):
            if src != "fixed" and ps != 1.0: continue                  # drone cases: DAS error fixed at the base level, the camera error is the studied factor
            cfg = rc.load(src, pos_level=ps, clock_sd=ck)
            jobs.append(((src, sp, pr, ps, ck, cr, dr), cfg, sp, pr, cr, dr, n_scenes, 1_000_000 + 7 * len(jobs)))
    t0 = time.time(); rows = []
    with Pool(procs) as pool:
        for i, (key, p, ci) in enumerate(pool.imap_unordered(_cell_job, jobs, chunksize=2)):
            rows.append((key, p, ci))
            if i % 100 == 0: print(f"{i}/{len(jobs)} cells, {time.time() - t0:.0f} s", flush=True)
    rows.sort(key=lambda r: r[0])
    with open(os.path.join(OUT, "reid_grid.csv"), "w", newline="") as f:
        w = csv.writer(f); head = ["camera_source", "spacing_m", "pairs_share", "position_error_m", "clock_offset_s", "crossing", "camera_dropout", "n_scenes", "label"]
        mets = ["person_acc", "group_acc", "decision_rate", "decided_acc", "wrong_links_per_100", "idf1"]
        w.writerow(head + [x for m in mets for x in (m, m + "_lo", m + "_hi")])
        for key, p, ci in rows:
            w.writerow(list(key) + [n_scenes, "SIMULATED"] + [round(v, 4) for m in mets for v in (p[m], ci[m][0], ci[m][1])])
    print("grid written,", len(rows), "cells,", f"{time.time() - t0:.0f} s")
    return rows


def ablation(n_scenes=300):
    import csv
    rows = []
    for src in rc.CAMERA_SOURCES:
        for label, cues, cadav in [("all cues", ("pos", "speed", "cadence", "height"), True), ("no speed", ("pos", "cadence", "height"), True), ("no height", ("pos", "speed", "cadence"), True),
                                   ("no cadence", ("pos", "speed", "height"), True), ("position only", ("pos",), True), ("camera cannot measure cadence", ("pos", "speed", "cadence", "height"), False)]:
            for sp in (20, 10, 5, 2):
                cfg = rc.load(src, clock_sd=0.2, cues=cues, cad_cam_available=cadav)
                M = run_cell(cfg, sp, 0.0, False, 0.0, n_scenes, 5_000_000); p = pooled(M); ci = bootstrap(M)
                rows.append([src, label, sp, n_scenes, round(p["person_acc"], 4), round(ci["person_acc"][0], 4), round(ci["person_acc"][1], 4), round(p["decided_acc"], 4), round(p["decision_rate"], 4), "SIMULATED"])
    with open(os.path.join(OUT, "ablation.csv"), "w", newline="") as f:
        w = csv.writer(f); w.writerow(["camera_source", "variant", "spacing_m", "n_scenes", "person_acc", "person_acc_lo", "person_acc_hi", "decided_acc", "decision_rate", "label"]); w.writerows(rows)
    print("ablation written", len(rows), "rows")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "grid"
    if cmd == "tune": tune()
    elif cmd == "grid": grid(int(sys.argv[2]) if len(sys.argv) > 2 else 300)
    elif cmd == "ablation": ablation()
