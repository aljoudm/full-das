"""Re-identification settings: read from config/ai_config.json (block "reid", the same file as the classifier) and, once chosen, from
results/reid/thresholds.json (gate and margin tuned on development scenes, then frozen). Camera sources: 'fixed' and the drone camera in three cases."""
import json, os
from dataclasses import dataclass, field

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAMERA_SOURCES = ("fixed", "drone_optimistic", "drone_base", "drone_pessimistic")


def raw():
    return json.load(open(os.path.join(ROOT, "config", "ai_config.json"), encoding="utf8"))["reid"]


@dataclass
class Config:
    # errors (1 sd), ASSUMED planning values of docs/ReID_Design_and_Evaluation_Protocol.pdf unless stated in ai_config.json
    pos_sd_das: float = 1.0
    pos_sd_cam: float = 1.0
    speed_sd_das: float = 0.05
    speed_sd_cam: float = 0.10
    cad_sd_das: float = 2.0
    cad_sd_cam: float = 3.0
    cad_cam_available: bool = True
    height_sd_das: float = 8.0
    height_sd_cam: float = 5.0
    clock_sd: float = 0.0                 # s, used for the variance of the camera position (speed x sync error) and for the offset in simulations
    nominal_speed: float = 1.3
    gate_sigma: float = 3.0
    margin: float = 4.0
    group_dist: float = 2.0
    group_dv: float = 0.15
    cues: tuple = ("pos", "speed", "cadence", "height")
    source: str = "fixed"


def load(source="fixed", pos_level=None, clock_sd=0.0, cues=None, cad_cam_available=None, use_frozen=True):
    r = raw(); c = Config(pos_sd_das=r["pos_sd_das_m"], pos_sd_cam=r["pos_sd_cam_fixed_m"], speed_sd_das=r["speed_sd_das"], speed_sd_cam=r["speed_sd_cam"],
                          cad_sd_das=r["cad_sd_das"], cad_sd_cam=r["cad_sd_cam"], cad_cam_available=bool(r["cad_cam_available"]), height_sd_das=r["height_sd_das"],
                          height_sd_cam=r["height_sd_cam"], nominal_speed=r["pop_speed_mean"], gate_sigma=r["gate_sigma"], margin=r["margin"],
                          group_dist=r["group_dist_m"], group_dv=r["group_dv"], clock_sd=clock_sd, source=source)
    if source.startswith("drone"):
        c.pos_sd_cam = r["pos_sd_cam_drone_m"][{"drone_optimistic": "optimistic", "drone_base": "base", "drone_pessimistic": "pessimistic"}[source]]
    elif source != "fixed":
        raise ValueError(source)
    if pos_level is not None:                       # planning grid factor: position error of DAS (and of the fixed camera)
        c.pos_sd_das = pos_level
        if source == "fixed": c.pos_sd_cam = pos_level
    if cues is not None: c.cues = tuple(cues)
    if cad_cam_available is not None: c.cad_cam_available = bool(cad_cam_available)
    th = os.path.join(ROOT, "results", "reid", "thresholds.json")
    if use_frozen and os.path.isfile(th):
        t = json.load(open(th)); c.gate_sigma = t["gate_sigma"]; c.margin = t["margin"]
    return c
