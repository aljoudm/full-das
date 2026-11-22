"""Inventory of the Brno DAS dataset: every [Check in data] item of the evaluation protocol, from the files themselves.

    python -I ai/brno_inventory.py   ->  C:/data/das_brno/inventory.json  (read by docs/brno_metadata.md and the split script)
Sources: <label>/<recording>.json (annotated curves = events), .npy (bitmap rows x channels), .h5 attributes (when the recording is downloaded).
"""
import os, json, glob, re
import numpy as np, h5py

LAB = r"C:\data\das_brno\extract\DAS-dataset\data"
RAW = r"C:\data\das_brno\raw\DAS-dataset\data"
OUT = r"C:\data\das_brno\inventory.json"
inv = {"recordings": [], "h5_attrs_example": None}
for npy in sorted(glob.glob(os.path.join(LAB, "*", "*.npy"))):
    folder = os.path.basename(os.path.dirname(npy)); name = os.path.splitext(os.path.basename(npy))[0]
    bm = np.load(npy); j = json.load(open(npy[:-3] + "json"))
    curves = [k for k in j if k.startswith("curve")]
    t, c = np.nonzero(bm)
    m = re.search(r"(\d{4}-\d{2}-\d{2})T(\d{2})(\d{2})(\d{2})", name)
    rec = {"folder": folder, "name": name, "date": m.group(1) if m else None, "start_time": f"{m.group(2)}:{m.group(3)}:{m.group(4)}" if m else None,
           "bitmap_rows": int(bm.shape[0]), "channels": int(bm.shape[1]), "n_curves": len(curves), "marked_cells": int(bm.sum()),
           "marked_channel_min": int(c.min()) if len(c) else None, "marked_channel_max": int(c.max()) if len(c) else None,
           "marked_row_min": int(t.min()) if len(t) else None, "marked_row_max": int(t.max()) if len(t) else None, "json_keys": [k for k in j if not k.startswith("curve")]}
    h5 = os.path.join(RAW, folder, name + ".h5")
    if os.path.isfile(h5):
        with h5py.File(h5, "r") as f:
            raw = f["Acquisition"]["Raw[0]"]; d = raw["RawData"]
            rec.update({"downloaded": True, "n_time": int(d.shape[0]), "dtype": str(d.dtype), "chunks": str(d.chunks), "fs_hz": float(raw.attrs["OutputDataRate"]), "duration_s": float(d.shape[0] / raw.attrs["OutputDataRate"]),
                        "rawdata_attrs": {k: (v.decode() if isinstance(v, bytes) else (v.tolist() if hasattr(v, "tolist") else v)) for k, v in d.attrs.items()}})
            acq = {k: (v.decode() if isinstance(v, bytes) else (v.item() if hasattr(v, "item") else v)) for k, v in f["Acquisition"].attrs.items()}
            if inv["h5_attrs_example"] is None:
                inv["h5_attrs_example"] = {"acquisition": acq, "raw0": {k: (v.decode() if isinstance(v, bytes) else (v.tolist() if hasattr(v, "tolist") else v)) for k, v in raw.attrs.items()},
                                           "groups": list(f["Acquisition"].keys()), "root_groups": list(f.keys())}
            rec["acq_pulse"] = {k: acq.get(k) for k in ("PulseRate", "PulseWidth", "SpatialSamplingInterval", "NumberOfLoci", "MaximumFrequency")}
    else:
        rec["downloaded"] = False
    inv["recordings"].append(rec)
json.dump(inv, open(OUT, "w"), indent=1, default=lambda o: o.decode() if isinstance(o, bytes) else str(o))
print(len(inv["recordings"]), "recordings;", sum(r["downloaded"] for r in inv["recordings"]), "downloaded")
for r in inv["recordings"]:
    print(f'{r["folder"]:13s} {r["name"][:34]:34s} {r["date"]} curves {r["n_curves"]:3d} bitmap {r["bitmap_rows"]}x{r["channels"]} channels {r["marked_channel_min"]}-{r["marked_channel_max"]}', f'{r.get("duration_s", float("nan")):.0f}s' if r["downloaded"] else "")
