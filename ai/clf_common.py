"""Shared pieces of the event classifier (our re-implementation of the DASViT1D idea; no code copied from the DASViT1D repository
or from the dataset's GPL loader): parameters from the single table, class map, feature extraction (MFCC + RDFT + DWT), window cutting.

Domain conversion (Brno -> full-das PSD domain): a Brno window is ONE channel, 20 kHz, cut to T_clf_s; it is resampled to fs_win_hz (510 Hz,
polyphase, anti-aliased), detrended, then the features below are computed. A full-das simulated window (time x channel at fs_win_hz) is reduced to
the single channel with the highest band energy and cut to T_clf_s: from there the SAME feature function is used, so both domains share the
frequency axis 0-255 Hz and the same feature layout.
"""
import os, csv
import numpy as np
from scipy import signal
import pywt, librosa

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TABLE = os.path.join(ROOT, "config", "parameters_reviewed.tsv")

CLASSES = ["walking", "running", "vehicle", "digging", "climbing", "tampering", "no_event", "other"]   # no_event = "background" of class_map.yaml; 'animal' has no data (PLACEHOLDER in the stub)
# folder of the Brno dataset -> our class (config/class_map.yaml; manipulation is its own class 'tampering' since the protocol of 23 Nov, which changes decision 10)
FOLDER_TO_CLASS = {"walk": "walking", "running": "running", "car": "vehicle", "construction": "digging", "fence": "climbing",
                   "manipulation": "tampering", "regular": "no_event", "longboard": "other", "openclose": "other"}      # = config/class_map.yaml (background = no_event)


def table_value(sym):
    with open(TABLE, encoding="utf8", newline="") as f:
        for row in csv.reader(f, delimiter="\t", quotechar=None):
            if row and row[0] == sym:
                return float(row[3])
    raise KeyError(sym)


FS = table_value("fs_win_hz")            # 510 Hz
T_CLF = float(os.environ.get("T_CLF_S", table_value("T_clf_s")))   # 1.0 s (PLACEHOLDER); env T_CLF_S overrides it for the 1 s vs 2 s comparison
N = int(round(FS * T_CLF))               # samples per window


def to_domain(x20k, fs_in=20000):
    """One-channel Brno window (fs_in) -> fs_win_hz window of N samples (polyphase resampling, detrended)."""
    up, down = int(round(FS)), int(fs_in)
    g = np.gcd(up, down)
    y = signal.resample_poly(np.asarray(x20k, dtype=np.float64), up // g, down // g)[:N]
    return signal.detrend(y)


def features(x):
    """Fused feature vector of one window x (N samples at FS): MFCC (mean, std) + RDFT log-magnitude + DWT block log-energies."""
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.std(x) + 1e-12)                                              # scale-free (strain units differ between devices)
    w = x * np.hanning(len(x))
    # MFCC (20 coefficients) over short frames, mean and std over time
    S = librosa.feature.mfcc(y=x.astype(np.float32), sr=FS, n_mfcc=20, n_fft=128, hop_length=32, n_mels=32, fmax=FS / 2 - 1)
    mf = np.concatenate([S.mean(axis=1), S.std(axis=1)])                     # 40
    # RDFT: redundant DFT (zero padding r = 3) -> 3x finer frequency grid, 0 to 127 Hz kept, log magnitude
    r = 3
    sp = np.abs(np.fft.rfft(w, n=r * len(w)))
    f = np.fft.rfftfreq(r * len(w), 1 / FS)
    rd = np.log10(sp[f <= 127.5] + 1e-6)
    rd = signal.resample(rd, 192)                                           # 192
    # DWT: Daubechies-4, 3 levels; log-energy in 16 equal blocks of every sub-band (A3, D3, D2, D1) -> 64
    c = pywt.wavedec(x, "db4", level=3)
    dw = []
    for band in c:
        blocks = np.array_split(band, 16)
        dw += [np.log10(np.mean(b ** 2) + 1e-9) for b in blocks]
    return np.concatenate([mf, rd, np.asarray(dw)]).astype(np.float32)        # 40 + 192 + 64 = 296


FEAT_LEN = 296
