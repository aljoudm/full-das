"""Cut labelled single-channel windows from the Brno DAS recordings (raw h5 + bitmap npy + json curves) and compute the fused features.

    python -I ai/brno_windows.py [T_seconds] [out_dir] [max_per_event]
Window selection and event assignment are those of ai/brno_events.py (one event = one annotated curve; a window is marked in >= 50 % of its rows).
Each event is capped at max_per_event windows (random, fixed seed) to bound the compute; the cap is applied per event, never across events.
Output: <out_dir>/<recording>.npz with X (features), raw (N samples at fs_win_hz), event (curve index), row, chan, sha1 (hash of the raw window), cls, rec.
"""
import os, sys, glob, time, hashlib
import numpy as np, h5py
os.environ.setdefault("T_CLF_S", sys.argv[1] if len(sys.argv) > 1 else "1.0")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clf_common as cc
import brno_events as be

RAW = r"C:\data\das_brno\raw\DAS-dataset\data"


def process(h5path, out_dir, max_per_event=120, seed=0):
    folder = os.path.basename(os.path.dirname(h5path)); name = os.path.splitext(os.path.basename(h5path))[0]
    out = os.path.join(out_dir, name + ".npz")
    if os.path.isfile(out):
        return out
    cls = cc.FOLDER_TO_CLASS[folder]
    with h5py.File(h5path, "r") as f:
        d = f["Acquisition"]["Raw[0]"]["RawData"]; nt, nc = d.shape
        fs_in = float(f["Acquisition"]["Raw[0]"].attrs["OutputDataRate"])
        import json
        R = np.load(os.path.join(be.LAB, folder, name + ".npy")).shape[0]; spr = nt // R
        cand, ncurves, k = be.windows_of(name, folder, cc.T_CLF, spr); Lw = int(cc.T_CLF * fs_in)
        rng = np.random.default_rng(seed); keep = []
        for e in sorted(set(c[2] for c in cand)):
            ce = [c for c in cand if c[2] == e]
            if len(ce) > max_per_event: ce = [ce[i] for i in rng.choice(len(ce), max_per_event, replace=False)]
            keep += ce
        keep.sort(); by_row = {}
        for r, c, e in keep: by_row.setdefault(r, []).append((c, e))
        X, W, rows, chans, evs, hs = [], [], [], [], [], []
        t0 = time.time()
        for r, cl in by_row.items():
            blk = d[r * spr:r * spr + Lw, :]
            for c, e in cl:
                w = cc.to_domain(blk[:, c].astype(np.float64), fs_in)
                if len(w) < cc.N: continue
                X.append(cc.features(w)); W.append(w.astype(np.float32)); rows.append(r); chans.append(c); evs.append(e)
                hs.append(hashlib.sha1(blk[:, c].tobytes()).hexdigest())
    os.makedirs(out_dir, exist_ok=True)
    np.savez_compressed(out, X=np.array(X, dtype=np.float32), raw=np.array(W), row=np.array(rows), chan=np.array(chans), event=np.array(evs), sha1=np.array(hs),
                        cls=cls, rec=name, folder=folder, n_rows=R, spr=spr, n_candidates=len(cand), n_curves=ncurves)
    print(f"{name}: class {cls}, {len(X)} windows of {len(cand)} candidates, {len(set(evs))} events, {time.time() - t0:.0f} s", flush=True)
    return out


if __name__ == "__main__":
    T = sys.argv[1] if len(sys.argv) > 1 else "1.0"
    out = sys.argv[2] if len(sys.argv) > 2 else rf"C:\data\das_brno\windows_T{int(float(T))}"
    mx = int(sys.argv[3]) if len(sys.argv) > 3 else 120
    for p in sorted(glob.glob(os.path.join(RAW, "*", "*.h5"))):
        process(p, out, mx)
