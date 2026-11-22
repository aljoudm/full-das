"""Train and evaluate the temporary event classifier (our ViT-1D on MFCC + RDFT + DWT features) on the Brno windows.

    python -I ai/clf_train.py [windows_dir] [epochs]

Two evaluation protocols are run and reported side by side:
  RANDOM   : stratified random 80/10/10 over windows (the protocol of the DASViT1D paper; neighbouring windows of one recording are in both
             train and test, so it leaks) ;
  GROUPED  : whole recordings are held out (leave-one-recording-out, 3 folds). A class with a single recording is split in time:
             first 60 % = block A, 10 % gap (dropped), last 30 % = block C; A and C are separate groups, never in the same fold of train and test.
The pooled GROUPED confusion matrix is the one the simulation stub uses (results/classifier/confusion_grouped.json).
"""
import os, sys, glob, json, time
import numpy as np
import torch, torch.nn as nn
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clf_common as cc

WIN = sys.argv[1] if len(sys.argv) > 1 else r"C:\data\das_brno\windows"
EPOCHS = int(sys.argv[2]) if len(sys.argv) > 2 else 30
OUT = os.path.join(cc.ROOT, "results", "classifier"); os.makedirs(OUT, exist_ok=True)
torch.manual_seed(0); np.random.seed(0)
NC = len(cc.CLASSES)


class ViT1D(nn.Module):
    """1D vision transformer on the fused feature vector: patches of 8 values -> tokens, class token, 3 encoder layers."""
    def __init__(self, L=cc.FEAT_LEN, patch=8, d=64, heads=4, layers=3, nc=NC, drop=0.1):
        super().__init__()
        assert L % patch == 0
        self.patch = patch; n = L // patch
        self.embed = nn.Linear(patch, d); self.cls = nn.Parameter(torch.zeros(1, 1, d)); self.pos = nn.Parameter(torch.zeros(1, n + 1, d))
        nn.init.trunc_normal_(self.pos, std=0.02)
        enc = nn.TransformerEncoderLayer(d, heads, 2 * d, drop, batch_first=True, norm_first=True)
        self.enc = nn.TransformerEncoder(enc, layers); self.norm = nn.LayerNorm(d); self.head = nn.Linear(d, nc)

    def forward(self, x):
        b = x.shape[0]; t = self.embed(x.view(b, -1, self.patch))
        t = torch.cat([self.cls.expand(b, -1, -1), t], 1) + self.pos
        return self.head(self.norm(self.enc(t)[:, 0]))


def fit_predict(Xtr, ytr, Xte, epochs=EPOCHS, Xva=None, yva=None):
    mu, sd = Xtr.mean(0), Xtr.std(0) + 1e-6
    f = lambda a: torch.tensor((a - mu) / sd, dtype=torch.float32)
    xt, yt = f(Xtr), torch.tensor(ytr); m = ViT1D()
    w = np.bincount(ytr, minlength=NC).astype(float); w = np.where(w > 0, w.sum() / (NC * np.maximum(w, 1)), 0)
    opt = torch.optim.AdamW(m.parameters(), 1e-3, weight_decay=1e-2); lossf = nn.CrossEntropyLoss(weight=torch.tensor(w, dtype=torch.float32))
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, epochs)
    for ep in range(epochs):
        m.train(); perm = torch.randperm(len(xt))
        for i in range(0, len(xt), 128):
            idx = perm[i:i + 128]; opt.zero_grad(); lossf(m(xt[idx]), yt[idx]).backward(); opt.step()
        sched.step()
    m.eval()
    with torch.no_grad(): pred = m(f(Xte)).argmax(1).numpy()
    return pred, (m, mu, sd)


def wilson(k, n, z=1.96):
    p = k / n; d = 1 + z * z / n; c = p + z * z / (2 * n); h = z * np.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return (c - h) / d, (c + h) / d


def boot_ci(yt, yp, grp, B=1000, seed=0):
    """95 % bootstrap CI over GROUPS (recordings / time blocks): resample the groups with replacement, recompute pooled accuracy and per-class recall."""
    rng = np.random.default_rng(seed); gs = np.array(sorted(set(grp), key=str), dtype=object); ok = (yt == yp)
    idx = {g: np.nonzero(grp == g)[0] for g in gs}; acc = []; rec = [[] for _ in range(NC)]
    for _ in range(B):
        pick = rng.choice(len(gs), len(gs)); ii = np.concatenate([idx[gs[i]] for i in pick])
        acc.append(ok[ii].mean())
        for c in range(NC):
            m = yt[ii] == c
            if m.any(): rec[c].append(ok[ii][m].mean())
    q = lambda v: (float(np.percentile(v, 2.5)), float(np.percentile(v, 97.5))) if len(v) else (float('nan'), float('nan'))
    return {"acc": q(acc), "recall": [q(r) for r in rec], "n_groups": int(len(gs))}


def load():
    X, y, rec, row, frac = [], [], [], [], []
    for p in sorted(glob.glob(os.path.join(WIN, "*.npz"))):
        z = np.load(p, allow_pickle=True)
        if len(z["X"]) == 0: continue
        X.append(z["X"]); y += [cc.CLASSES.index(str(z["cls"]))] * len(z["X"]); rec += [str(z["rec"])] * len(z["X"])
        r = z["row"]; row.append(r); frac.append((r - r.min()) / max(1, (r.max() - r.min())))
    return np.vstack(X), np.array(y), np.array(rec), np.concatenate(row), np.concatenate(frac)


def main():
    X, y, rec, row, frac = load()
    recs = sorted(set(rec)); cls_of = {r: y[rec == r][0] for r in recs}
    print("recordings per class:")
    for c in range(NC):
        rr = [r for r in recs if cls_of[r] == c]
        print(f"  {cc.CLASSES[c]:9s} {len(rr)} recording(s), {int((y == c).sum())} windows: {', '.join(rr)}")
    # ---- groups: single-recording classes are cut in time (A = first 60 %, gap 60-70 % dropped, C = last 30 %)
    group = rec.copy().astype(object); keep = np.ones(len(y), bool); single = set()
    for c in range(NC):
        rr = [r for r in recs if cls_of[r] == c]
        if len(rr) == 1:
            r = rr[0]; m = rec == r; single.add(c)
            group[m & (frac <= 0.6)] = r + "#A"; group[m & (frac >= 0.7)] = r + "#C"; keep[m & (frac > 0.6) & (frac < 0.7)] = False
    # ---- RANDOM protocol (leaky)
    rng = np.random.default_rng(0); idx = np.arange(len(y)); rng.shuffle(idx)
    ntr, nva = int(0.8 * len(y)), int(0.1 * len(y)); tr, te = idx[:ntr], idx[ntr + nva:]
    t0 = time.time(); pr, _ = fit_predict(X[tr], y[tr], X[te]); acc_rand = float((pr == y[te]).mean())
    print(f"RANDOM 80/10/10: test accuracy {acc_rand:.3f} ({time.time() - t0:.0f} s)")
    # ---- GROUPED protocol: fold of a group = its index within its class modulo 3
    groups = sorted(set(group[keep])); gcls = {g: y[group == g][0] for g in groups}
    fold_of = {}
    for c in range(NC):
        for j, g in enumerate([g for g in groups if gcls[g] == c]): fold_of[g] = j % 3
    P_true, P_pred, P_grp = [], [], []
    conf = np.zeros((NC, NC), int); conf_single = np.zeros((NC, NC), int); conf_cross = np.zeros((NC, NC), int); fold_acc = []
    log = []
    for k in range(3):
        te_m = keep & np.array([fold_of.get(g, -1) == k for g in group]); tr_m = keep & ~te_m
        # a block of a single-recording class must not train against its own sibling block when that sibling is in the test fold: allowed (gap dropped)
        te_g = set(group[te_m]); tr_g = set(group[tr_m]); assert not (te_g & tr_g), "a group is in both train and test"
        te_r = set(r.split("#")[0] for r in te_g); tr_rec_whole = set(r for r in tr_g if "#" not in r)
        assert not (te_r & tr_rec_whole), "a whole recording is in both train and test"
        pr, _ = fit_predict(X[tr_m], y[tr_m], X[te_m]); yt = y[te_m]; acc = float((pr == yt).mean()); fold_acc.append(acc)
        for a, b, g in zip(yt, pr, group[te_m]):
            P_true.append(a); P_pred.append(b); P_grp.append(g)
            conf[a, b] += 1
            (conf_single if a in single else conf_cross)[a, b] += 1
        for c in range(NC):
            gs = sorted(set(g for g in group[te_m] if gcls[g] == c))
            if gs: print(f"    fold {k} test {cc.CLASSES[c]:9s}: {len(gs)} group(s) {gs}, {int((yt == c).sum())} windows" + ("   [SAME RECORDING, TEMPORAL SPLIT]" if c in single else ""))
        print(f"fold {k}: test groups {sorted(te_g)} | train {len(tr_g)} groups | {int(tr_m.sum())} train / {int(te_m.sum())} test windows | accuracy {acc:.3f}")
        log.append({"fold": k, "test_groups": sorted(te_g), "n_train": int(tr_m.sum()), "n_test": int(te_m.sum()), "accuracy": acc})
    P_true, P_pred, P_grp = np.array(P_true), np.array(P_pred), np.array(P_grp, dtype=object)
    acc_grp = float(np.trace(conf) / conf.sum())
    ci = boot_ci(P_true, P_pred, P_grp)
    print("bootstrap over groups (recordings / time blocks), 95 % CI, 1000 resamples:")
    print(f"  pooled accuracy {acc_grp:.3f}  [{ci['acc'][0]:.3f}, {ci['acc'][1]:.3f}]  ({len(set(P_grp))} test groups)")
    for c in range(NC):
        n_g = len(set(P_grp[P_true == c]));   lo, hi = ci['recall'][c]
        print(f"  recall {cc.CLASSES[c]:9s} {(P_pred[P_true == c] == c).mean() if n_g else float('nan'):.3f}  [{lo:.3f}, {hi:.3f}]  groups {n_g}, windows {int((P_true == c).sum())}" + ("   [SAME RECORDING, TEMPORAL SPLIT]" if c in single else ""))
    print(f"GROUPED pooled accuracy {acc_grp:.3f}  (cross-recording classes only: {np.trace(conf_cross) / max(conf_cross.sum(), 1):.3f}; "
          f"single-recording time-block classes only: {np.trace(conf_single) / max(conf_single.sum(), 1):.3f})")
    print("inflation of the random protocol over the grouped one: %.1f percentage points" % (100 * (acc_rand - acc_grp)))
    rown = conf / np.maximum(conf.sum(1, keepdims=True), 1)
    print("confusion (rows true, cols predicted, row-normalised):"); print("          " + " ".join(f"{c[:7]:>8s}" for c in cc.CLASSES))
    for i, c in enumerate(cc.CLASSES): print(f"{c:9s} " + " ".join(f"{v:8.2f}" for v in rown[i]))
    json.dump({"classes": cc.CLASSES, "counts": conf.tolist(), "row_normalised": rown.tolist(), "accuracy_grouped": acc_grp, "ci95_grouped": ci, "random_wilson95": [wl, wh], "accuracy_random": acc_rand,
               "accuracy_grouped_cross_recording": float(np.trace(conf_cross) / max(conf_cross.sum(), 1)),
               "accuracy_grouped_single_recording_blocks": float(np.trace(conf_single) / max(conf_single.sum(), 1)), "single_recording_classes": [cc.CLASSES[c] for c in sorted(single)],
               "folds": log, "epochs": EPOCHS, "fs_hz": cc.FS, "window_s": cc.T_CLF, "features": cc.FEAT_LEN, "n_windows": int(keep.sum()),
               "recordings": {cc.CLASSES[c]: [r for r in recs if cls_of[r] == c] for c in range(NC)}}, open(os.path.join(OUT, "confusion_grouped.json"), "w"), indent=1)
    # final model on all kept windows (used ONLY for the sim-domain check, never for accuracy claims)
    _, (m, mu, sd) = fit_predict(X[keep], y[keep], X[:2])
    torch.save({"state": m.state_dict(), "mu": mu, "sd": sd, "classes": cc.CLASSES}, os.path.join(OUT, "clf_vit1d_all.pt"))


if __name__ == "__main__":
    main()
