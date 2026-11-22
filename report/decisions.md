# Decisions of full-das (justification; reference draft for the report)

1. **Single parameter table.** `config/parameters_reviewed.tsv` (copy of the optimization table at f51b223, plus column `value_type` and rows added 22 Nov 2026). `run_optimization` reads it through `src/load_params_fd.m`, which drops the 10th column for the frozen loader (the frozen file stays unchanged). Why: one source for every number.
2. **Frozen copies in `third_party/`** with commits in `third_party/PROVENANCE.md`; the sources are never modified.
3. **Cold zone is not zero.** lambda_cold = 1 to 2 events/day for the whole zone (sensitivity 0.1 to 2); spread over cells by risk x length. Why: the Cold performance must be testable.
4. **Allocation = frozen MILP**, 22 real interdiction crossings (32 sites as a sensitivity); each solved case is saved in `results/` because the MATLAB licence is a trial.
5. **Profiling naming and use of height** (Yomna, 22 Nov): 0.4 m is a *channel spacing*; SNR is computed with her `detection_snr_db`, and the 12 dB threshold comes from simulation (the real value is measured in Phase 0); height is exploratory (+/- 8 cm), used only to exclude a match (difference >= `dh_reid_max` = 25 cm, parameter), never to identify or confirm a person. The primary claim of the DAS is stride length, speed and cadence.
6. **DASViT1D** accuracy (93.5 %, published) is for another device and site (Brno dataset); accuracy on FEBUS is unknown until tested on real data.
