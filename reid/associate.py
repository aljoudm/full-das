"""Gating, cost, Hungarian assignment, decision margin and group linking. (Design section 2, steps 3 to 7.)

    links = associate(das_tracks, cam_tracks, cfg)
Each DAS track gets one link: status 'linked' (cam_id, cost, margin), 'group-linked' (a group of camera tracks), 'ambiguous' (candidate camera ids) or
'das-only' (no camera track can be the same person: an alarm-relevant case, the drone is sent to the DAS position).
An ambiguous link NEVER sends a patrol to a specific person (unified simulation: Stage 6 rules)."""
import numpy as np
from scipy.optimize import linear_sum_assignment

BIG = 1e9


def _arr(tracks, attr):
    return np.array([getattr(t, attr) for t in tracks], dtype=float)


def cost_matrix(das, cam, cfg):
    """Cost of every (DAS, camera) pair: sum over the enabled cues of (difference)^2 / (DAS variance + camera variance); inf if the pair fails the gate."""
    n, m = len(das), len(cam)
    C = np.full((n, m), np.inf)
    if n == 0 or m == 0: return C
    dpos, cpos = _arr(das, "pos")[:, None], _arr(cam, "pos")[None, :]
    var_pos = np.maximum(np.array([d.var["pos"] for d in das])[:, None] + np.array([c.var["pos"] for c in cam])[None, :], 1e-12)   # floor: zero-error tests
    ok = (_arr(das, "direction")[:, None] == _arr(cam, "direction")[None, :])                         # opposite directions are never linked (hard gate)
    ok &= (_arr(das, "t1")[:, None] > _arr(cam, "t0")[None, :]) & (_arr(cam, "t1")[None, :] > _arr(das, "t0")[:, None])      # time windows overlap
    ok &= np.abs(dpos - cpos) <= cfg.gate_sigma * np.sqrt(var_pos)
    cost = np.zeros((n, m))
    for cue in cfg.cues:
        if cue == "pos":
            cost += (dpos - cpos) ** 2 / var_pos
        elif cue == "speed":
            vv = np.maximum(np.array([d.var["speed"] for d in das])[:, None] + np.array([c.var["speed"] for c in cam])[None, :], 1e-12)
            cost += (_arr(das, "speed")[:, None] - _arr(cam, "speed")[None, :]) ** 2 / vv
        elif cue in ("cadence", "height"):
            dv = np.array([getattr(d, cue) if getattr(d, cue) is not None else np.nan for d in das])[:, None]
            cv = np.array([getattr(c, cue) if getattr(c, cue) is not None else np.nan for c in cam])[None, :]
            vv = np.maximum(np.array([d.var[cue] for d in das])[:, None] + np.array([c.var[cue] for c in cam])[None, :], 1e-12)
            with np.errstate(invalid="ignore", divide="ignore"):
                term = (dv - cv) ** 2 / vv
            cost += np.where(np.isnan(term), 0.0, term)                                                  # a cue that one sensor cannot measure is skipped
    C[ok] = cost[ok]
    return C


def groups(tracks, cfg):
    """Tracks within group_dist of each other with the same direction and nearly the same speed form a group (union-find). Returns group id per track."""
    n = len(tracks); parent = list(range(n))
    def find(i):
        while parent[i] != i: parent[i] = parent[parent[i]]; i = parent[i]
        return i
    for i in range(n):
        for j in range(i + 1, n):
            a, b = tracks[i], tracks[j]
            if a.direction == b.direction and abs(a.pos - b.pos) <= cfg.group_dist and abs(a.speed - b.speed) <= cfg.group_dv:
                parent[find(i)] = find(j)
    return [find(i) for i in range(n)]


def associate(das, cam, cfg):
    n, m = len(das), len(cam)
    C = cost_matrix(das, cam, cfg)
    links = [{"das_id": d.id, "status": "das-only", "cam_id": None, "cost": None, "margin": None, "candidates": [], "group": None} for d in das]
    if n == 0: return links
    assigned = {}
    if m > 0:
        r, c = linear_sum_assignment(np.where(np.isfinite(C), C, BIG))
        assigned = {int(i): int(j) for i, j in zip(r, c) if np.isfinite(C[i, j])}
    dg, cg = groups(das, cfg), (groups(cam, cfg) if m else [])
    dsize = {g: dg.count(g) for g in set(dg)}
    for i in range(n):
        fin = np.where(np.isfinite(C[i]))[0] if m else np.array([], int)
        if len(fin) == 0: continue                                                                      # no camera track can be this person: DAS-only
        best = fin[np.argmin(C[i, fin])]
        cand = [int(j) for j in fin if C[i, j] <= C[i, best] + cfg.margin]                                # options not clearly worse than the best
        j = assigned.get(i)
        decided = False
        if j is not None:
            alt_row = np.min(np.delete(C[i], j)) if m > 1 else np.inf
            alt_col = np.min(np.delete(C[:, j], i)) if n > 1 else np.inf
            marg = min(alt_row, alt_col) - C[i, j]
            if marg >= cfg.margin:                                                                       # clearly better than the next option for the row AND the column
                links[i].update(status="linked", cam_id=cam[j].id, cost=float(C[i, j]), margin=float(marg), candidates=[cam[j].id]); decided = True
            else:
                links[i].update(cost=float(C[i, j]), margin=float(marg))
        if not decided:
            links[i]["candidates"] = [cam[k].id for k in cand]
            cgs = {cg[k] for k in cand}
            if len(cand) >= 2 and len(cgs) == 1 and dsize[dg[i]] >= 2:                                   # group link: the DAS track is in a group and all candidates are one camera group
                links[i].update(status="group-linked", group=int(next(iter(cgs))))
            else:
                links[i].update(status="ambiguous")
    return links
