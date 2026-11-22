"""Re-identification of GROUP intrusions (2 to 5 people walking together 1 to 2 m apart) among single walkers, SIMULATED, all errors ASSUMED.

A scene = one group of k people (same direction, nearly the same speed and cadence, independent heights) plus 10 single people 50 m apart, three association windows,
camera clock offset 0.2 s, no dropout. Only the tracks of the GROUP MEMBERS are scored (person-level and group-level), with the frozen thresholds (results/reid/thresholds.json).
    PYTHONPATH=. python -m reid.group_scene     ->  results/reid/group_events.csv (per camera source and group size, 95 % scene bootstrap)"""
import os, csv
import numpy as np
from . import config as rc
from .associate import associate
from .summaries import Track
from .evaluate import score_window, pooled, bootstrap, COLS


def make_group_scene(cfg, k, rng, n_single=10, spacing=50.0, n_windows=3, window_s=10.0):
    p = rc.raw(); n = k + n_single
    x0 = np.empty(n); v = np.clip(rng.normal(p["pop_speed_mean"], p["pop_speed_sd"], n), 0.3, None)
    h = rng.normal(p["pop_height_mean"], p["pop_height_sd"], n); cad = rng.normal(p["pop_cad_mean"], p["pop_cad_sd"], n)
    gx = rng.uniform(0, n_single * spacing); x0[0] = gx
    for i in range(1, k):                                                    # members 1 to 2 m apart, nearly the same speed and cadence
        x0[i] = x0[i - 1] + rng.uniform(1.0, 2.0); v[i] = v[0] + rng.normal(0, p["pair_dv"]); cad[i] = cad[0] + rng.normal(0, p["pair_dcad"])
    x0[k:] = rng.uniform(0, n_single * spacing, n_single)
    grp = np.arange(n); grp[:k] = 0; grp[k:] = np.arange(1, n_single + 1)
    offset = rng.normal(0, cfg.clock_sd) if cfg.clock_sd > 0 else 0.0
    sd_d = {"pos": cfg.pos_sd_das, "speed": cfg.speed_sd_das, "cadence": cfg.cad_sd_das, "height": cfg.height_sd_das}
    sd_c = {"pos": cfg.pos_sd_cam, "speed": cfg.speed_sd_cam, "cadence": cfg.cad_sd_cam, "height": cfg.height_sd_cam}
    windows = []
    for w in range(n_windows):
        t0, t1 = w * window_s, (w + 1) * window_s; tm = 0.5 * (t0 + t1); xt = x0 + v * tm; das, cam = [], []
        for i in range(n):
            das.append(Track(i, "das", t0, t1, xt[i] + rng.normal(0, sd_d["pos"]), v[i] + rng.normal(0, sd_d["speed"]), 1, cad[i] + rng.normal(0, sd_d["cadence"]), h[i] + rng.normal(0, sd_d["height"]),
                             {q: sd_d[q] ** 2 for q in sd_d}, i, int(grp[i])))
            var = {"pos": sd_c["pos"] ** 2 + (cfg.nominal_speed * cfg.clock_sd) ** 2, "speed": sd_c["speed"] ** 2, "cadence": sd_c["cadence"] ** 2, "height": sd_c["height"] ** 2}
            cam.append(Track(1000 + i, "cam", t0, t1, xt[i] + v[i] * offset + rng.normal(0, sd_c["pos"]), v[i] + rng.normal(0, sd_c["speed"]), 1,
                             (cad[i] + rng.normal(0, sd_c["cadence"])) if cfg.cad_cam_available else None, h[i] + rng.normal(0, sd_c["height"]), var, i, int(grp[i])))
        cam = [cam[j] for j in rng.permutation(len(cam))]
        windows.append((das, cam))
    return windows


def run(source, k, n_scenes=300, seed0=3_000_000):
    cfg = rc.load(source, clock_sd=0.2); M = []
    for i in range(n_scenes):
        tot = dict.fromkeys(COLS, 0)
        for das, cam in make_group_scene(cfg, k, np.random.default_rng(seed0 + 17 * i + k)):
            links = associate(das, cam, cfg); idx = [j for j, d in enumerate(das) if d.truth_group == 0]          # only the members of the group
            for key, val in score_window([das[j] for j in idx], cam, [links[j] for j in idx]).items(): tot[key] += val
        M.append([tot[c] for c in COLS])
    return np.array(M)


if __name__ == "__main__":
    out = os.path.join(rc.ROOT, "results", "reid", "group_events.csv"); rows = []
    mets = ["person_acc", "group_acc", "decision_rate", "decided_acc", "person_link_rate", "person_link_acc", "wrong_links_per_100", "idf1"]
    for src in ("fixed", "drone_base", "drone_pessimistic"):
        for k in (2, 3, 4, 5):
            M = run(src, k); p = pooled(M); ci = bootstrap(M)
            rows.append([src, k, 300, "SIMULATED"] + [round(v, 4) for m in mets for v in (p[m], ci[m][0], ci[m][1])]); print(src, k, {m: round(p[m], 3) for m in mets})
    with open(out, "w", newline="") as f:
        w = csv.writer(f); w.writerow(["camera_source", "group_size", "n_scenes", "label"] + [x for m in mets for x in (m, m + "_lo", m + "_hi")]); w.writerows(rows)
    print("written", out)
