"""Train and evaluate the temporary event classifier following docs/Classifier_Evaluation_Protocol.pdf (Yomna, 22 Nov 2026), checklist section 7.

    python -I ai/clf_protocol.py [T_seconds] [epochs]        (windows from ai/brno_windows.py; splits from config/splits.json, written once)
What it does, in order:
  1. loads the windows of every recording; leakage checks as ASSERTIONS (groups disjoint, events never straddle a split, no duplicate window hashes); prints and saves class counts per split;
  2. trains ONE model on the development recordings with FIXED hyper-parameters (nothing is tuned on the test) and evaluates the LOCKED TEST ONCE, at EVENT level
     (mean probability over the windows of an event): balanced accuracy, recall and precision per class, macro F1, ECE, each with a cluster bootstrap over test recordings
     (2000 resamples) and, because there are fewer than 10 test recordings, Clopper-Pearson on events; confusion matrix with event COUNTS; reliability plot;
  3. descriptive grouped 5-fold results on development (event level), flagged as descriptive;
  4. diagnostics, labelled and never in the headline: random-window split (run once) vs grouped, window-level; single-recording classes: first 80 % train / last 20 % test with a 2-window gap [DIAGNOSTIC - SAME RECORDING], 'same recording, optimistic';
  5. writes results/classifier/T<s>s/{metrics.json, confusion_matrix.csv, reliability.png, model_card.md, split_counts.json}.
"""
import os, sys, json, glob, hashlib, subprocess, time
import numpy as np
T_ARG = sys.argv[1] if len(sys.argv) > 1 else "1.0"
os.environ["T_CLF_S"] = T_ARG
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clf_common as cc
import torch
import clf_train as ct                                    # ViT1D, fit_predict (importing does not run main)
from scipy.stats import beta

EPOCHS = int(sys.argv[2]) if len(sys.argv) > 2 else 30
ct.EPOCHS = EPOCHS
WIN = rf"C:\data\das_brno\windows_T{int(float(T_ARG))}"
OUT = os.path.join(cc.ROOT, "results", "classifier", f"T{int(float(T_ARG))}s"); os.makedirs(OUT, exist_ok=True)
SPLIT = json.load(open(os.path.join(cc.ROOT, "config", "splits.json")))
NC = len(cc.CLASSES); ALARM = ["walking", "running", "digging", "climbing", "tampering"]
torch.manual_seed(0); np.random.seed(0)


def load():
    D = {}
    for r in SPLIT["recordings"]:
        p = os.path.join(WIN, r["name"] + ".npz")
        if not os.path.isfile(p): sys.exit(f"missing windows of {r['name']}: run ai/brno_windows.py {T_ARG} after the download")
        z = np.load(p, allow_pickle=True); D[r["name"]] = z
    return D


def assemble(D, names):
    X, y, rec, ev, h, row = [], [], [], [], [], []
    for n in names:
        z = D[n]
        if len(z["X"]) == 0: continue
        m = len(z["X"]); X.append(z["X"]); y += [cc.CLASSES.index(str(z["cls"]))] * m; rec += [n] * m
        ev += [f"{n}|{e}" for e in z["event"]]; h += list(z["sha1"]); row.append(z["row"])
    return np.vstack(X), np.array(y), np.array(rec), np.array(ev), np.array(h), np.concatenate(row)


def predict_proba(Xtr, ytr, Xte):
    pred, (m, mu, sd) = ct.fit_predict(Xtr, ytr, Xte[:2])
    m.eval()
    with torch.no_grad(): P = torch.softmax(m(torch.tensor((Xte - mu) / sd, dtype=torch.float32)), 1).numpy()
    return P, (m, mu, sd)


def event_level(P, y, ev, rec):
    """Aggregate windows to events: mean probability over the windows of each event."""
    ue = sorted(set(ev)); yt, yp, conf, er = [], [], [], []
    for e in ue:
        m = ev == e; p = P[m].mean(0); yt.append(y[m][0]); yp.append(int(p.argmax())); conf.append(float(p.max())); er.append(rec[m][0])
    return np.array(yt), np.array(yp), np.array(conf), np.array(er), np.array(ue)


def clopper(k, n, a=0.05):
    lo = 0.0 if k == 0 else beta.ppf(a / 2, k, n - k + 1); hi = 1.0 if k == n else beta.ppf(1 - a / 2, k + 1, n - k)
    return float(lo), float(hi)


def metrics(yt, yp, classes_present):
    rec = {}; prec = {}; f1 = {}
    for c in classes_present:
        tp = int(((yt == c) & (yp == c)).sum()); nt = int((yt == c).sum()); npred = int((yp == c).sum())
        rec[c] = tp / nt if nt else float("nan"); prec[c] = tp / npred if npred else float("nan")
        f1[c] = 2 * rec[c] * prec[c] / (rec[c] + prec[c]) if (rec[c] + prec[c]) > 0 and not np.isnan(rec[c] + prec[c]) else 0.0
    ba = float(np.nanmean([rec[c] for c in classes_present])); return rec, prec, f1, ba


def cluster_boot(yt, yp, er, classes_present, B=2000, seed=0):
    rng = np.random.default_rng(seed); recs = sorted(set(er)); idx = {r: np.nonzero(er == r)[0] for r in recs}; ba = []; rc = {c: [] for c in classes_present}
    for _ in range(B):
        pick = rng.choice(len(recs), len(recs)); ii = np.concatenate([idx[recs[i]] for i in pick])
        r, _, _, b = metrics(yt[ii], yp[ii], [c for c in classes_present if (yt[ii] == c).any()]); ba.append(b)
        for c in r: rc[c].append(r[c])
    q = lambda v: [float(np.percentile(v, 2.5)), float(np.percentile(v, 97.5))] if len(v) else [None, None]
    return q(ba), {c: q(v) for c, v in rc.items()}


def ece(conf, correct, bins=5):
    e = 0.0; edges = np.linspace(0, 1, bins + 1)
    for a, b in zip(edges[:-1], edges[1:]):
        m = (conf > a) & (conf <= b)
        if m.any(): e += m.mean() * abs(correct[m].mean() - conf[m].mean())
    return float(e)


def main():
    t0 = time.time(); D = load(); dev, locked = SPLIT["development"], SPLIT["locked_test"]
    # ---- 1) leakage assertions
    folds = SPLIT["development_folds"]; allf = [n for v in folds.values() for n in v]
    assert len(allf) == len(set(allf)) and set(allf) == set(dev), "development folds are not a partition of the development recordings"
    assert not (set(dev) & set(locked)), "a recording is in both development and locked test"
    Xd, yd, rd, ed, hd, rowd = assemble(D, dev); Xl, yl, rl, el, hl, rowl = assemble(D, locked)
    assert not (set(ed) & set(el)), "an event is in both development and test"
    assert len(set(e.split("|")[0] for e in ed) & set(e.split("|")[0] for e in el)) == 0, "events of one recording straddle the split"
    for k, v in folds.items():
        o = [n for kk, vv in folds.items() if kk != k for n in vv]; assert not (set(v) & set(o)), "a recording is in two folds"
    assert not (set(hd) & set(hl)), "duplicate windows (same hash) across development and test"
    assert len(set(hd)) > 0.9 * len(hd), "many duplicate windows inside development"
    counts = {"development": {cc.CLASSES[c]: {"windows": int((yd == c).sum()), "events": len(set(ed[yd == c])), "recordings": len(set(rd[yd == c]))} for c in range(NC)},
              "locked_test": {cc.CLASSES[c]: {"windows": int((yl == c).sum()), "events": len(set(el[yl == c])), "recordings": len(set(rl[yl == c]))} for c in range(NC)}}
    json.dump(counts, open(os.path.join(OUT, "split_counts.json"), "w"), indent=1)
    print("LEAKAGE CHECKS PASSED (groups disjoint, no event straddles a split, no duplicate window hashes)")
    print(f'{"class":10s} | development win/ev/rec | locked test win/ev/rec')
    for c in cc.CLASSES: print(f'{c:10s} | {counts["development"][c]["windows"]:6d}/{counts["development"][c]["events"]:3d}/{counts["development"][c]["recordings"]:2d}        | {counts["locked_test"][c]["windows"]:6d}/{counts["locked_test"][c]["events"]:3d}/{counts["locked_test"][c]["recordings"]:2d}')
    # ---- 2) locked test, once
    P, (m, mu, sd) = predict_proba(Xd, yd, Xl)
    yt, yp, conf, er, ue = event_level(P, yl, el, rl)
    present = sorted(set(yt.tolist())); rec, prec, f1, ba = metrics(yt, yp, present)
    ci_ba, ci_rec = cluster_boot(yt, yp, er, present)
    ntest_rec = len(set(er)); cp = {c: clopper(int(((yt == c) & (yp == c)).sum()), int((yt == c).sum())) for c in present}
    correct = (yt == yp).astype(float); e_ece = ece(conf, correct)
    cm = np.zeros((NC, NC), int)
    for a, b in zip(yt, yp): cm[a, b] += 1
    import csv
    with open(os.path.join(OUT, "confusion_matrix.csv"), "w", newline="") as f:
        w = csv.writer(f); w.writerow(["true"] + cc.CLASSES)
        for c in present: w.writerow([cc.CLASSES[c]] + cm[c].tolist())
    print(f"\nLOCKED TEST (event level, {len(yt)} events from {ntest_rec} recordings; classes present: {[cc.CLASSES[c] for c in present]})")
    print(f"headline over {len(present)} evaluable classes {[cc.CLASSES[c] for c in present]} (running, digging, background, tampering: 1 recording each, trained but not in the headline)")
    print(f"balanced accuracy {ba:.3f}  cluster bootstrap 95 % [{ci_ba[0]:.3f}, {ci_ba[1]:.3f}]  (only {ntest_rec} test recordings: the bootstrap interval is too narrow; Clopper-Pearson on events below)")
    for c in present:
        print(f"  {cc.CLASSES[c]:9s} recall {rec[c]:.3f} [{cp[c][0]:.3f}, {cp[c][1]:.3f}] Clopper-Pearson, {int((yt == c).sum())} events, {len(set(er[yt == c]))} recording(s); precision {prec[c]:.3f}")
    per_rec = {}
    for r_ in sorted(set(er)):
        mm = er == r_; per_rec[r_] = {"class": cc.CLASSES[int(yt[mm][0])], "n_events": int(mm.sum()), "events_correct": int((yt[mm] == yp[mm]).sum()), "recall": float((yt[mm] == yp[mm]).mean()),
                                      "predicted": {cc.CLASSES[c]: int((yp[mm] == c).sum()) for c in set(yp[mm].tolist())}}
        print(f"  test recording {r_[:34]:34s} class {per_rec[r_]['class']:9s}: {per_rec[r_]['events_correct']} of {per_rec[r_]['n_events']} events correct, predicted {per_rec[r_]['predicted']}")
    ceil_ = {cc.CLASSES[c]: float(0.05 ** (1.0 / int((yt == c).sum()))) for c in present}
    print("  best possible one-sided 95 % lower bound on recall if every test event of the class were correct (0.05^(1/n)):", {k: round(v, 3) for k, v in ceil_.items()})
    print(f"  THE LOCKED TEST HAS ONLY {ntest_rec} RECORDINGS: the cluster bootstrap is not meaningful; Clopper-Pearson on events and the per-recording results above are what counts.")
    # ---- 3) descriptive development folds
    fold_res = []
    for k, v in folds.items():
        tr_names = [n for kk, vv in folds.items() if kk != k for n in vv]; Xt, yt_, rt_, et_, _, _ = assemble(D, tr_names); Xv, yv, rv, evv, _, _ = assemble(D, v)
        Pk, _ = predict_proba(Xt, yt_, Xv); a, b, _, _, _ = event_level(Pk, yv, evv, rv)
        fold_res.append({"fold": k, "recordings": v, "events": int(len(a)), "event_accuracy": float((a == b).mean()),
                         "classes_without_training_recording": [cc.CLASSES[c] for c in set(a.tolist()) if c not in set(yt_.tolist())]})
        print(f"  dev fold {k} (descriptive): {len(a)} events, event accuracy {(a == b).mean():.3f}, classes with no training data in this fold: {fold_res[-1]['classes_without_training_recording']}")
    # ---- 4a) random-window diagnostic, once (window level, all recordings pooled)
    Xa, ya, ra, ea, _, _ = assemble(D, dev + locked); rng = np.random.default_rng(0); idx = rng.permutation(len(ya)); ntr = int(0.8 * len(ya)); tr, te = idx[:ntr], idx[ntr + int(0.1 * len(ya)):]
    Pr, _ = predict_proba(Xa[tr], ya[tr], Xa[te]); acc_rand_win = float((Pr.argmax(1) == ya[te]).mean())
    acc_grp_win = float((P.argmax(1) == yl).mean())
    print(f"\n[DIAGNOSTIC] random 80/10/10 WINDOW split (run once): window accuracy {acc_rand_win:.3f}  vs grouped locked test, window accuracy {acc_grp_win:.3f}  -> gap {100 * (acc_rand_win - acc_grp_win):.1f} points (windows overlap: not independent)")
    # ---- 4b) single-recording classes, DIAGNOSTIC (Yomna's update 23 Nov): contiguous blocks, first 80 % of the recording rows = train, last 20 % = test,
    #          with a gap of 2 windows (one window + its overlap) between them; the result is "same recording, optimistic"
    single = [("no_event" if c == "background" else c) for c in SPLIT["not_evaluable_on_brno"]]; diag = {}      # class_map.yaml says background, the code says no_event
    if single:
        Xs, ys, rs, es, hs, rows = assemble(D, dev); trm = np.ones(len(ys), bool); tem = np.zeros(len(ys), bool)
        for n in set(rs):
            mm = rs == n
            if cc.CLASSES[ys[mm][0]] not in single: continue
            r = rows[mm]; k = int(np.ceil(cc.T_CLF * 20000 / int(D[n]["spr"]))); cut = r.min() + 0.8 * (r.max() - r.min())
            idx = np.nonzero(mm)[0]; trm[idx] = (r + k) <= (cut - k); tem[idx] = r >= cut           # gap = 2 windows between the last training window and the first test window
        Pt, _ = predict_proba(Xs[trm], ys[trm], Xs[tem]); a, b, _, er2, _ = event_level(Pt, ys[tem], es[tem], rs[tem])
        for c in sorted(set(a.tolist())):
            diag[cc.CLASSES[c]] = {"events": int((a == c).sum()), "recall": float(((a == c) & (b == c)).sum() / (a == c).sum()), "label": "[DIAGNOSTIC - SAME RECORDING] same recording, optimistic"}
            print(f"[DIAGNOSTIC - SAME RECORDING, optimistic] {cc.CLASSES[c]}: {diag[cc.CLASSES[c]]['events']} events in the last 20 % of the recording, recall {diag[cc.CLASSES[c]]['recall']:.2f} (not evaluable on Brno: 1 recording; trained on the first 80 % with a 2-window gap)")
    # ---- 4c) false alarms on the BACKGROUND recording (last 20 % after the gap), alarms per km per day: [DIAGNOSTIC - SAME RECORDING], same recording, optimistic
    bgf = {}
    if "no_event" in single:
        chan_all = np.concatenate([D[n]["chan"] for n in dev if len(D[n]["X"])]); bgm = tem & (ys == cc.CLASSES.index("no_event"))
        if bgm.any():
            ab, bb, _, _, _ = event_level(Pt[(tem[tem]) & (ys[tem] == cc.CLASSES.index("no_event"))], ys[bgm], es[bgm], rs[bgm])
            alarm_idx = [cc.CLASSES.index(c) for c in ALARM]; n_alarm = int(np.isin(bb, alarm_idx).sum())
            nbg = [n for n in dev if cc.FOLDER_TO_CLASS[str(D[n]["folder"])] == "no_event"][0]; spr = int(D[nbg]["spr"]); rr_ = rows[bgm]
            k = int(np.ceil(cc.T_CLF * 20000 / spr)); secs = (rr_.max() + k - rr_.min()) * spr / 20000.0
            km = len(set(chan_all[bgm])) * 1.0209523 / 1000.0; days = secs / 86400.0; kd = km * days
            bgf = {"label": "[DIAGNOSTIC - SAME RECORDING] same recording, optimistic", "background_events": int(len(ab)), "alarm_class_events": n_alarm, "monitored_km": km, "duration_s": secs, "km_days": kd,
                   "alarms_per_km_per_day": n_alarm / kd, "rule_of_three_upper_95_per_km_day": (3.0 / kd if n_alarm == 0 else None)}
            print(f"[DIAGNOSTIC - SAME RECORDING, optimistic] background false alarms: {n_alarm} alarm-class events of {len(ab)} background events over {km:.2f} km x {secs:.0f} s = {kd:.2e} km-days -> {n_alarm / kd:.0f} alarms/km/day" + (f"; rule of three: upper bound {3.0 / kd:.0f} per km per day (useless: far too little background)" if n_alarm == 0 else ""))
    # ---- 5) files
    commit = subprocess.run(["git", "-C", cc.ROOT, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    ck = hashlib.sha256(b"".join(p.detach().numpy().tobytes() for p in m.parameters())).hexdigest()
    M = {"protocol": "docs/Classifier_Evaluation_Protocol.pdf", "window_s": cc.T_CLF, "fs_hz": cc.FS, "epochs": EPOCHS, "level": "event (mean probability over the windows of an event)",
         "locked_test": {"n_events": int(len(yt)), "n_recordings": ntest_rec, "classes": [cc.CLASSES[c] for c in present], "headline_classes": [cc.CLASSES[c] for c in present], "n_headline_classes": len(present), "headline_note": "balanced accuracy and macro F1 are over these evaluable classes only; running, digging, background and tampering (1 recording each) stay in training but are out of the headline; an evaluable-class event predicted as one of them counts as an error of its true class", "balanced_accuracy": ba, "balanced_accuracy_cluster_bootstrap_95": ci_ba,
                         "recall": {cc.CLASSES[c]: {"value": rec[c], "clopper_pearson_95": cp[c], "cluster_bootstrap_95": ci_rec[c], "n_events": int((yt == c).sum()), "n_recordings": len(set(er[yt == c]))} for c in present},
                         "precision": {cc.CLASSES[c]: prec[c] for c in present}, "macro_f1": float(np.mean([f1[c] for c in present])), "ece": e_ece, "unknown_share": 0.0,
                         "note": f"only {ntest_rec} test recordings: the cluster bootstrap interval is too narrow; use Clopper-Pearson on events. Far below the several hundred events per class that a 98 % claim needs."},
         "per_test_recording": per_rec, "max_provable_recall_lower_bound_if_all_correct": ceil_, "development_folds_descriptive": fold_res, "diagnostic_random_window_split": {"window_accuracy_random": acc_rand_win, "window_accuracy_grouped_locked_test": acc_grp_win, "label": "[DIAGNOSTIC] window level, run once"},
         "diagnostic_single_recording_classes": diag, "diagnostic_background_false_alarms": bgf, "not_evaluable_on_brno": SPLIT["not_evaluable_on_brno"], "commit": commit, "model_checksum_sha256": ck, "seconds": time.time() - t0}
    json.dump(M, open(os.path.join(OUT, "metrics.json"), "w"), indent=1)
    import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
    edges = np.linspace(0, 1, 6); xs, ys_ = [], []
    for a, b in zip(edges[:-1], edges[1:]):
        mm = (conf > a) & (conf <= b)
        if mm.any(): xs.append(conf[mm].mean()); ys_.append(correct[mm].mean())
    fig, ax = plt.subplots(figsize=(4.5, 4.5)); ax.plot([0, 1], [0, 1], "k--"); ax.plot(xs, ys_, "o-"); ax.set_xlabel("mean confidence (event)"); ax.set_ylabel("fraction correct"); ax.set_title(f"Reliability, Brno locked test, ECE {e_ece:.2f}\n{len(yt)} events, {ntest_rec} recordings", fontsize=9)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, "reliability.png"), dpi=150)
    open(os.path.join(OUT, "model_card.md"), "w", encoding="utf8").write(f"""# Model card: temporary event classifier (ViT-1D on MFCC + RDFT + DWT), window {cc.T_CLF:.0f} s
**Brno results; FEBUS not yet tested.** Brno accuracy is not system accuracy and not FEBUS accuracy.
* Data: Brno DAS dataset (Tomasov et al. 2025, CC BY), raw int16, 20 kHz, OptaSense, resampled to {cc.FS:.0f} Hz, one channel per window. Classes: {', '.join(cc.CLASSES)} ('animal' absent).
* Split: config/splits.json (seed {SPLIT['seed']}, written once); group = recording file; locked test = {', '.join(locked)}.
* Evaluation: event level, balanced accuracy {ba:.3f} over {len(present)} evaluable classes, {len(yt)} test events from {ntest_rec} recordings; intervals in metrics.json. Classes with one recording are not evaluable on Brno.
* Preprocessing and class weights are fitted on the development recordings only; no hyper-parameter was tuned (fixed: 3 layers, d = 64, {EPOCHS} epochs).
* **Running is an alarm class that is NOT evaluated on Brno** (1 recording; same for digging = construction, tampering, background): it stays in training and has priority when FEBUS data are collected. Balanced accuracy and macro F1 are over the {len(present)} evaluable classes only ({', '.join(cc.CLASSES[c] for c in present)}); an event of an evaluable class predicted as a single-recording class counts as an error of its true class.
* **Only {ntest_rec} test recordings.** Per-recording results and Clopper-Pearson intervals on events are in metrics.json; the cluster bootstrap is not meaningful with so few recordings. Even if every event of the largest class were correct, the one-sided 95 % lower bound on recall would be at most {max(ceil_.values()):.3f} (0.05^(1/n), n = events of that class): Brno shows that the classifier works, the real accuracy has to come from FEBUS.
* **Climbing (fence) scored 0 of the test events when it did so, which was expected:** the classifier is trained on only 2 climbing events from 2 recordings (momentary fence impacts), and the test result cannot tell a weak classifier from an unusual fence recording (a single recording of 12 annotated impacts). It is a statement about these data, not about the classifier.
* **Use in the simulation:** the Brno matrix is a SENSITIVITY only ("Brno, 4 test recordings, SENSITIVITY"); the uniform stub (Pc from the literature) stays the base. Classes missing from the matrix fall back to the uniform stub.
* Known limits: very few events per class; one site and one interrogator; windows of an event are correlated; confidence is not calibrated beyond the reliability plot; no unknown option.
* Commit {commit}; model checksum {ck}.
""")
    print(f"\nsaved {OUT}  ({time.time() - t0:.0f} s)")


if __name__ == "__main__":
    main()
