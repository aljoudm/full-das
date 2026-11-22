"""Common frame for DAS and camera tracks: distance along the fence, plus time. (Design section 2, step 1.)"""
import numpy as np


def fibre_to_fence(d_fibre, scale=1.0, offset=0.0):
    """Fibre distance -> fence distance (m). scale and offset come from tap tests at known marks, once per installation."""
    return scale * np.asarray(d_fibre, dtype=float) + offset


def ground_to_fence(xy, origin=(0.0, 0.0), angle_rad=0.0):
    """Camera ground-plane coordinates (m) -> (along-fence, across-fence) coordinates: translate to the fence origin and rotate by the fence angle.
    DAS knows only the along-fence coordinate, so only the first output is used for linking."""
    xy = np.asarray(xy, dtype=float) - np.asarray(origin, dtype=float)
    c, s = np.cos(angle_rad), np.sin(angle_rad)
    return xy[..., 0] * c + xy[..., 1] * s, -xy[..., 0] * s + xy[..., 1] * c


def apply_clock_offset(t, offset):
    """Bring a sensor time to the common clock: t_common = t - offset (the residual offset is logged at synchronisation)."""
    return np.asarray(t, dtype=float) - offset


def position_at(t_ref, t, x, v):
    """Position along the fence at the common reference time, from a position x measured at time t with speed v (signed)."""
    return x + v * (t_ref - t)
