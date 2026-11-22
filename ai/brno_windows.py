"""Cut labelled single-channel windows from the Brno DAS recordings (raw h5 + bitmap npy) and compute the fused features.

    python -I ai/brno_windows.py [raw_dir] [out_dir] [max_per_recording]
The bitmap (rows x channels, bool) marks where the labelled event is; one row covers n_time / n_rows samples (about 0.1 s). A window is
the T_clf_s of one channel that starts at a row and is marked in at least 50 % of the rows it covers. Windows are taken every half window.
Output: <out_dir>/<recording>.npz with X (features), raw (N samples at fs_win_hz), cls, row, channel, plus the recording name and class.
"""
import os, sys, glob, time
import numpy as np, h5py
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clf_common as cc

RAW = r"C:\data\das_brno\raw\DAS-dataset\data"
LAB = r"C:\data\das_brno\extract\DAS-dataset\data"          # bitmaps (tiny files, read over the network)
OUT = r"C:\data\das_brno\windows"


def process(h5path, out_dir, max_win=1500, seed=0):
    folder = os.path.basename(os.path.dirname(h5path)); name = os.path.splitext(os.path.basename(h5path))[0]
    out = os.path.join(out_dir, name + ".npz")
    if os.path.isfile(out):
        return out
    cls = cc.FOLDER_TO_CLASS[folder]
    bm = np.load(os.path.join(LAB, folder, name + ".npy"))
    with h5py.File(h5path, "r") as f:
        d = f["Acquisition"]["Raw[0]"]["RawData"]; nt, nc = d.shape
        fs_in = float(f["Acquisition"]["Raw[0]"].attrs["OutputDataRate"])
        R = bm.shape[0]; spr = nt // R; k = int(np.ceil(cc.T_CLF * fs_in / spr)); Lw = int(cc.T_CLF * fs_in)
        # candidate (row, channel): marked in >= 90 % of the k rows; every k//2 rows
        cs = np.vstack([np.zeros((1, bm.shape[1])), np.cumsum(bm, axis=0)])
        cand = []
        for r in range(0, R - k + 1, max(1, k // 2)):
            ok = (cs[r + k] - cs[r]) >= 0.5 * k
            for c in np.nonzero(ok)[0]: cand.append((r, c))
        rng = np.random.default_rng(seed)
        if len(cand) > max_win:
            cand = [cand[i] for i in rng.choice(len(cand), max_win, replace=False)]
        cand.sort()
        X, W, rows, chans = [], [], [], []
        by_row = {}
        for r, c in cand: by_row.setdefault(r, []).append(c)
        t0 = time.time()
        for r, cl in by_row.items():
            blk = d[r * spr:r * spr + Lw, :]
            for c in cl:
                w = cc.to_domain(blk[:, c].astype(np.float64), fs_in)
                if len(w) < cc.N: continue
                X.append(cc.features(w)); W.append(w.astype(np.float32)); rows.append(r); chans.append(c)
    X = np.array(X, dtype=np.float32)
    os.makedirs(out_dir, exist_ok=True)
    np.savez_compressed(out, X=X, raw=np.array(W), row=np.array(rows), chan=np.array(chans), cls=cls, rec=name, folder=folder, n_rows=R, spr=spr, n_candidates=len(cand))
    print(f"{name}: class {cls}, {len(X)} windows (candidates {len(cand)}), {time.time() - t0:.0f} s", flush=True)
    return out


if __name__ == "__main__":
    raw = sys.argv[1] if len(sys.argv) > 1 else RAW
    out = sys.argv[2] if len(sys.argv) > 2 else OUT
    mx = int(sys.argv[3]) if len(sys.argv) > 3 else 1500
    for p in sorted(glob.glob(os.path.join(raw, "*", "*.h5"))):
        process(p, out, mx)
