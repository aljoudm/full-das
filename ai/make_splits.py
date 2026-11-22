"""Write config/splits.json ONCE, before any training, with a fixed seed. It refuses to run again (never regenerated after training starts).

Protocol (docs/Classifier_Evaluation_Protocol.pdf, section 2) applied as far as the Brno data allow:
  * the group is the RECORDING FILE (the finest unit of the preference list that exists here: the location along the cable is unknown and 12 of the 16 recordings share one day);
  * a class is EVALUABLE on Brno only if it has >= 2 recordings: one recording of each evaluable class goes to the LOCKED TEST (chosen with the fixed seed), the others to development;
  * classes with ONE recording (running, digging, background, tampering) cannot be tested without removing all their training data: they are 'not evaluable on Brno (1 recording)',
    all their data go to development / training, and a temporal split of the recording is only a DIAGNOSTIC (labelled [DIAGNOSTIC - SAME RECORDING]);
  * development = the remaining recordings in 5 grouped folds (round robin inside each class, seed fixed).
Deviations (locked test 4 of 16 recordings = 25 % instead of 15-20 %; development folds in which a class has no training recording) are listed in the json and in report/assumptions.md.
"""
import os, sys, json, hashlib
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from brno_events import load_class_map

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "config", "splits.json")
SEED = 20261122

if os.path.exists(OUT):
    sys.exit("config/splits.json exists: the splits are never regenerated.")
inv = json.load(open(r"C:\data\das_brno\inventory.json")); f2c = load_class_map()
recs = [{"name": r["name"], "folder": r["folder"], "class": f2c[r["folder"]], "date": r["date"], "n_events_annotated": r["n_curves"]} for r in inv["recordings"]]
classes = sorted(set(r["class"] for r in recs))
rng = np.random.default_rng(SEED)
by_class = {c: sorted([r["name"] for r in recs if r["class"] == c]) for c in classes}
evaluable = [c for c in classes if len(by_class[c]) >= 2]
locked = [str(rng.choice(by_class[c])) for c in evaluable]
dev = [r["name"] for r in recs if r["name"] not in locked]
folds = {k: [] for k in range(5)}
k = 0
for c in classes:
    rr = [n for n in by_class[c] if n in dev]; rng.shuffle(rr)
    for n in rr:
        folds[k % 5].append(n); k += 1
cls_of = {r["name"]: r["class"] for r in recs}
split = {
    "seed": SEED, "group_unit": "recording file", "classes": classes, "evaluable_classes": evaluable,
    "not_evaluable_on_brno": {c: "1 recording" for c in classes if c not in evaluable},
    "locked_test": locked, "locked_test_class": {n: cls_of[n] for n in locked},
    "development": dev, "development_folds": {str(k): v for k, v in folds.items()}, "recordings": recs,
    "diagnostic_temporal_split": {"classes": [c for c in classes if c not in evaluable], "rule": "first 60 % of the recording rows = train, 10 % gap dropped, last 30 % = test; label [DIAGNOSTIC - SAME RECORDING]; never in the headline metrics"},
    "deviations": [
        "locked test = %d of %d recordings (%.0f %%), above the 15-20 %% target, because every evaluable class needs one test recording" % (len(locked), len(recs), 100 * len(locked) / len(recs)),
        "the group is the recording file: the location along the cable is unknown and 12 of 16 recordings are from 2023-04-17, so cable zone x day or day grouping is not possible",
        "walking has 2 recordings: 1 locked test, 1 development; its development folds have no walking training data in the fold that validates it",
        "running, digging, background and tampering have 1 recording each: not evaluable on Brno",
        "grouped 5-fold cross-validation on development is only descriptive (few recordings per class); no hyper-parameter is tuned on it"],
    "created_by": "ai/make_splits.py", "note": "written once before any training; never regenerated",
}
json.dump(split, open(OUT, "w"), indent=1)
print("locked test:", [(n, cls_of[n]) for n in locked])
for k, v in folds.items(): print("fold", k, [(n[:28], cls_of[n]) for n in v])
print("sha256", hashlib.sha256(open(OUT, "rb").read()).hexdigest())
