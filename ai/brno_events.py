"""Candidate windows and events of the Brno recordings from the label files only (no raw data needed).

An EVENT is one annotated curve of the recording's json (one continuous activity by one source: a walk, a dig, a vehicle pass). Curve coordinates are
x = channel, y = bitmap row (checked: 100 % of the sampled curve points of the fence recording fall on marked cells). A window is the T_clf_s of ONE channel,
starting at a bitmap row, marked in >= 50 % of the rows it covers; it belongs to the event whose curve is nearest to the window centre (row, channel).
    python -I ai/brno_events.py  ->  C:/data/das_brno/events_<T>s.json and prints the class table
"""
import os, sys, json, glob
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

LAB = r"C:\data\das_brno\extract\DAS-dataset\data"
FS_IN = 20000.0
CLASS_MAP = None


def load_class_map():
    import re
    folder_to_class = {}
    for line in open(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config", "class_map.yaml"), encoding="utf8"):
        m = re.match(r"\s+(\w+):\s+\{class:\s*(\w+)", line)
        if m: folder_to_class[m.group(1)] = m.group(2)
    return folder_to_class


def windows_of(name, folder, T, spr):
    bm = np.load(os.path.join(LAB, folder, name + ".npy")); j = json.load(open(os.path.join(LAB, folder, name + ".json")))
    R = bm.shape[0]; k = int(np.ceil(T * FS_IN / spr))
    curves = [np.c_[j[c]["x"], j[c]["y"]] for c in sorted((c for c in j if c.startswith("curve")), key=lambda s: int(s[5:]))]
    cs = np.vstack([np.zeros((1, bm.shape[1])), np.cumsum(bm, axis=0)])
    out = []                                                    # (row, channel, event)
    for r in range(0, R - k + 1, max(1, k // 2)):
        ok = (cs[r + k] - cs[r]) >= 0.5 * k
        for c in np.nonzero(ok)[0]:
            p = np.array([c, r + k / 2.0])
            d = [np.min(np.hypot(cv[:, 0] - p[0], cv[:, 1] - p[1])) for cv in curves]
            out.append((r, int(c), int(np.argmin(d)) if d else -1))
    return out, len(curves), k


if __name__ == "__main__":
    inv = json.load(open(r"C:\data\das_brno\inventory.json")); f2c = load_class_map()
    for T in (1.0, 2.0):
        table = {}; rec_rows = []
        for rec in inv["recordings"]:
            folder, name = rec["folder"], rec["name"]
            spr = 2056 if rec["channels"] == 1700 else None
            if spr is None:                                     # June recordings (1663 loci): the rows/samples ratio comes from the h5 length when known, else from the same ratio 20000 / 9.73 = 2056
                spr = int(rec["n_time"] // rec["bitmap_rows"]) if rec.get("downloaded") else 2056
            if rec.get("downloaded"): spr = int(rec["n_time"] // rec["bitmap_rows"])
            w, nc, k = windows_of(name, folder, T, spr)
            ev = sorted(set(e for _, _, e in w))
            rec_rows.append({"recording": name, "folder": folder, "class": f2c[folder], "date": rec["date"], "events_annotated": nc, "events_with_windows": len(ev), "windows": len(w), "rows_per_window": k, "samples_per_row": spr})
            c = f2c[folder]; t = table.setdefault(c, {"recordings": 0, "events_annotated": 0, "events_with_windows": 0, "windows": 0, "days": set()})
            t["recordings"] += 1; t["events_annotated"] += nc; t["events_with_windows"] += len(ev); t["windows"] += len(w); t["days"].add(rec["date"])
        json.dump({"T_s": T, "per_recording": rec_rows, "per_class": {c: {**v, "days": sorted(v["days"])} for c, v in table.items()}}, open(rf"C:\data\das_brno\events_{int(T)}s.json", "w"), indent=1)
        print(f"\nT = {T:.0f} s")
        print(f'{"class":13s} {"rec":>3s} {"days":>4s} {"events(annot.)":>14s} {"events(with windows)":>20s} {"windows":>8s}')
        for c, v in table.items(): print(f'{c:13s} {v["recordings"]:3d} {len(v["days"]):4d} {v["events_annotated"]:14d} {v["events_with_windows"]:20d} {v["windows"]:8d}')
