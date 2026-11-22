"""Scene generator for the factors of the evaluation protocol (design section 4). SIMULATED: every error and population spread is ASSUMED (config/ai_config.json, block reid).

    scene = make_scene(cfg, spacing_m, pairs_frac, crossing, dropout, rng, n_people, n_windows)
A scene = n_windows consecutive association windows of the same people (so links can change over time: IDF1). Each window gives the DAS tracks (every person is seen by DAS)
and the camera tracks (a person's camera track is missing with probability `dropout`, per window: a DAS-only case). Truth ids are attached for scoring only."""
import numpy as np
from .summaries import Track
from . import config as rc

POP = None


def pop():
    global POP
    if POP is None: POP = rc.raw()
    return POP


def make_scene(cfg, spacing_m, pairs_frac, crossing, dropout, rng, n_people=None, n_windows=None, window_s=None):
    p = pop(); n = n_people or p["n_people"]; W = n_windows or p["n_windows"]; wl = window_s or p["window_s"]
    L = n * spacing_m
    x0 = rng.uniform(0, L, n); v = np.clip(rng.normal(p["pop_speed_mean"], p["pop_speed_sd"], n), 0.3, None)
    h = rng.normal(p["pop_height_mean"], p["pop_height_sd"], n); cad = rng.normal(p["pop_cad_mean"], p["pop_cad_sd"], n)
    d = np.where(rng.random(n) < 0.5, 1, -1) if crossing else np.ones(n, int)
    grp = np.arange(n); n_pairs = int(round(pairs_frac * n / 2))
    idx = rng.permutation(n)
    for k in range(n_pairs):                                           # a pair walks together: about 1 m apart, nearly the same speed, cadence and direction
        a, b = idx[2 * k], idx[2 * k + 1]
        x0[b] = x0[a] + p["pair_gap_m"]; v[b] = v[a] + rng.normal(0, p["pair_dv"]); cad[b] = cad[a] + rng.normal(0, p["pair_dcad"]); d[b] = d[a]; grp[b] = grp[a]
    offset = rng.normal(0, cfg.clock_sd) if cfg.clock_sd > 0 else 0.0     # camera clock offset of this scene (seconds), not compensated
    sd_d = {"pos": cfg.pos_sd_das, "speed": cfg.speed_sd_das, "cadence": cfg.cad_sd_das, "height": cfg.height_sd_das}
    sd_c = {"pos": cfg.pos_sd_cam, "speed": cfg.speed_sd_cam, "cadence": cfg.cad_sd_cam, "height": cfg.height_sd_cam}
    windows = []
    for w in range(W):
        t0, t1 = w * wl, (w + 1) * wl; tm = 0.5 * (t0 + t1); xt = x0 + d * v * tm      # true position along the fence at the reference time
        das, cam = [], []
        for i in range(n):
            das.append(Track(i, "das", t0, t1, xt[i] + rng.normal(0, sd_d["pos"]), v[i] + rng.normal(0, sd_d["speed"]), int(d[i]), cad[i] + rng.normal(0, sd_d["cadence"]),
                             h[i] + rng.normal(0, sd_d["height"]), {"pos": sd_d["pos"] ** 2, "speed": sd_d["speed"] ** 2, "cadence": sd_d["cadence"] ** 2, "height": sd_d["height"] ** 2}, i, int(grp[i])))
            if rng.random() < dropout: continue                         # camera track missing in this window
            var = {"pos": sd_c["pos"] ** 2 + (cfg.nominal_speed * cfg.clock_sd) ** 2, "speed": sd_c["speed"] ** 2, "cadence": sd_c["cadence"] ** 2, "height": sd_c["height"] ** 2}
            cam.append(Track(1000 + i, "cam", t0, t1, xt[i] + d[i] * v[i] * offset + rng.normal(0, sd_c["pos"]), v[i] + rng.normal(0, sd_c["speed"]), int(d[i]),
                             (cad[i] + rng.normal(0, sd_c["cadence"])) if cfg.cad_cam_available else None, h[i] + rng.normal(0, sd_c["height"]), var, i, int(grp[i])))
        perm = rng.permutation(len(cam)); cam = [cam[k] for k in perm]    # the order of camera tracks carries no information
        windows.append((das, cam))
    return windows
