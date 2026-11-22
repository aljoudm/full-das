"""Track summaries: over the time both sensors see a person, each track gives position along the fence at a common reference time, speed, direction,
and optionally cadence and height, each with its variance. (Design section 2, step 2.)"""
from dataclasses import dataclass, field
from typing import Optional
import numpy as np


@dataclass
class Track:
    id: int
    sensor: str                         # 'das' | 'cam'
    t0: float
    t1: float
    pos: float                          # m along the fence at the reference time
    speed: float                        # m/s (magnitude)
    direction: int                      # +1 / -1
    cadence: Optional[float] = None     # steps/min
    height: Optional[float] = None      # cm
    var: dict = field(default_factory=dict)         # variances of pos, speed, cadence, height
    truth_person: Optional[int] = None  # simulation only
    truth_group: Optional[int] = None


def summarize(times, positions, track_id, sensor, sd, t_ref=None, cadence=None, height=None, clock_sd=0.0, nominal_speed=1.3):
    """Summary from a series of (time, position-along-fence) samples: a least-squares line gives speed and the position at t_ref.
    sd = dict of 1-sigma errors of the cues (pos, speed, cadence, height). The camera clock error is folded into the position variance (speed x sync error)."""
    t = np.asarray(times, dtype=float); x = np.asarray(positions, dtype=float)
    t_ref = float(t.mean()) if t_ref is None else t_ref
    A = np.vstack([t - t_ref, np.ones_like(t)]).T
    (v, x_ref), *_ = np.linalg.lstsq(A, x, rcond=None)
    var = {"pos": sd["pos"] ** 2 + (nominal_speed * clock_sd) ** 2, "speed": sd["speed"] ** 2, "cadence": sd.get("cadence", 0.0) ** 2, "height": sd.get("height", 0.0) ** 2}
    return Track(track_id, sensor, float(t.min()), float(t.max()), float(x_ref), abs(float(v)), 1 if v >= 0 else -1, cadence, height, var)
