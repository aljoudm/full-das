"""Tests of the re-identification module (design section 6): the six required tests plus a config / table consistency check.
Run from the repository root:  PYTHONPATH=. python -I tests/test_reid.py"""
import os, sys, csv, copy
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from reid import config as rc
from reid.associate import associate
from reid.simulate import make_scene
from reid.summaries import Track


def zero_cfg(**kw):
    c = rc.load("fixed", use_frozen=False)
    for a in ("pos_sd_das", "pos_sd_cam", "speed_sd_das", "speed_sd_cam", "cad_sd_das", "cad_sd_cam", "height_sd_das", "height_sd_cam"): setattr(c, a, 0.0)
    c.clock_sd = 0.0
    for k, v in kw.items(): setattr(c, k, v)
    return c


def truth_ok(das, cam, links):
    by = {c.id: c for c in cam}
    return all(l["status"] == "linked" and by[l["cam_id"]].truth_person == d.truth_person for d, l in zip(das, links))


def test_zero_error_50m_every_link_right():
    cfg = zero_cfg()
    for crossing in (False, True):
        for seed in range(30):
            for das, cam in make_scene(cfg, 50, 0.0, crossing, 0.0, np.random.default_rng(seed)):
                assert truth_ok(das, cam, associate(das, cam, cfg)), "a link is wrong with zero errors at 50 m"


def test_camera_order_does_not_matter():
    cfg = rc.load("fixed", clock_sd=0.2, use_frozen=False)
    for seed in range(20):
        for das, cam in make_scene(cfg, 5, 0.25, True, 0.1, np.random.default_rng(seed)):
            a = {l["das_id"]: (l["status"], l["cam_id"], tuple(sorted(l["candidates"]))) for l in associate(das, cam, cfg)}
            for k in range(3):
                cam2 = list(np.random.default_rng(100 + k).permutation(np.array(cam, dtype=object))); b = {l["das_id"]: (l["status"], l["cam_id"], tuple(sorted(l["candidates"]))) for l in associate(das, cam2, cfg)}
                assert a == b, "links depend on the order of the camera tracks"


def trk(i, sensor, pos, speed=1.3, direction=1, t0=0.0, t1=10.0):
    return Track(i, sensor, t0, t1, pos, speed, direction, 110.0, 165.0, {"pos": 1.0, "speed": 0.01, "cadence": 4.0, "height": 64.0}, i, i)


def test_identical_candidates_are_ambiguous():
    cfg = rc.load("fixed", use_frozen=False)
    links = associate([trk(1, "das", 10.0)], [trk(11, "cam", 10.0), trk(12, "cam", 10.0)], cfg)
    assert links[0]["status"] == "ambiguous" and set(links[0]["candidates"]) == {11, 12}, links


def test_opposite_directions_never_linked():
    cfg = rc.load("fixed", use_frozen=False)
    links = associate([trk(1, "das", 10.0, direction=1)], [trk(11, "cam", 10.0, direction=-1)], cfg)
    assert links[0]["status"] == "das-only" and links[0]["cam_id"] is None, links


def test_das_track_without_camera_is_das_only():
    cfg = rc.load("fixed", use_frozen=False)
    assert associate([trk(1, "das", 10.0)], [], cfg)[0]["status"] == "das-only"
    assert associate([trk(1, "das", 10.0)], [trk(11, "cam", 90.0)], cfg)[0]["status"] == "das-only"          # the only camera track is far away: gated out


def test_same_seed_same_result():
    cfg = rc.load("drone_base", clock_sd=0.2, use_frozen=False)
    def run(seed):
        out = []
        for das, cam in make_scene(cfg, 5, 0.5, True, 0.2, np.random.default_rng(seed)): out.append([(l["status"], l["cam_id"], round(l["cost"], 9) if l["cost"] is not None else None) for l in associate(das, cam, cfg)])
        return out
    assert run(7) == run(7) and run(7) != run(8)


def test_config_matches_table():
    r = rc.raw(); table = {}
    with open(os.path.join(rc.ROOT, "config", "parameters_reviewed.tsv"), encoding="utf8", newline="") as f:
        for row in csv.reader(f, delimiter="\t", quotechar=None):
            if row and row[0].startswith("reid_"): table[row[0]] = row[3]
    pairs = {"reid_pos_sd_das_m": r["pos_sd_das_m"], "reid_pos_sd_cam_fixed_m": r["pos_sd_cam_fixed_m"], "reid_speed_sd_das": r["speed_sd_das"], "reid_speed_sd_cam": r["speed_sd_cam"],
             "reid_cad_sd_das": r["cad_sd_das"], "reid_cad_sd_cam": r["cad_sd_cam"], "reid_cad_cam_available": r["cad_cam_available"], "reid_height_sd_das": r["height_sd_das"], "reid_height_sd_cam": r["height_sd_cam"],
             "reid_pop_speed_mean": r["pop_speed_mean"], "reid_pop_speed_sd": r["pop_speed_sd"], "reid_pop_height_mean": r["pop_height_mean"], "reid_pop_height_sd": r["pop_height_sd"], "reid_pop_cad_mean": r["pop_cad_mean"],
             "reid_pop_cad_sd": r["pop_cad_sd"], "reid_pair_gap_m": r["pair_gap_m"], "reid_pair_dv": r["pair_dv"], "reid_pair_dcad": r["pair_dcad"], "reid_n_people": r["n_people"], "reid_n_windows": r["n_windows"],
             "reid_window_s": r["window_s"], "reid_group_dist_m": r["group_dist_m"], "reid_group_dv": r["group_dv"], "reid_gate_sigma": r["gate_sigma"], "reid_margin": r["margin"], "reid_target_decided_acc": r["target_decided_acc"],
             "reid_pos_sd_cam_drone_base_m": r["pos_sd_cam_drone_m"]["base"], "reid_pos_sd_cam_drone_opt_m": r["pos_sd_cam_drone_m"]["optimistic"], "reid_pos_sd_cam_drone_pess_m": r["pos_sd_cam_drone_m"]["pessimistic"]}
    for k, v in pairs.items():
        assert k in table, "row missing in the table: " + k
        assert abs(float(table[k]) - float(v)) < 1e-12, f"{k}: table {table[k]} vs config {v}"


if __name__ == "__main__":
    n = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_"): fn(); n += 1; print("PASS", name)
    print(f"reid tests: {n} passed")
