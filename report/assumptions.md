# Assumptions of the event model (all in `config/parameters_reviewed.tsv`, column value_type)
* Wadis come from the DEM (cell lower than its 300 m Gaussian mean by `wadi_depth_m` with a gentle floor): a PROXY, the 30 m DSM includes buildings and no wadi map exists.
* Dirt roads = OSM `highway=track|unclassified` (surface is not tagged, so this is a proxy); built-up = distance to the centre of an OSM urban area or place (centre points only, so the 1 km radius is coarse).
* Entry weights (x3 wadi, x2 track, x2 urban), type proportions per terrain class, speeds, durations, heading random walk and the non-intrusion rates are ASSUMED / PLACEHOLDER; none has a source.
* Intrusion arrival is uniform over the 24 h of a day (no night preference modelled).
* A trajectory ends 600 m inside (measured on the local normal) or after 1800 s; about 7 % of the walks leave the boundary polygon at concave bends.

# Assumptions of the DAS stage
* The window length, duration and sampling are PLACEHOLDERS until the AI input is fixed (Yomna). The library is rebuilt by `build_das_library(P, 'Force', true)`.
* Event waveforms: walking, digging and vehicle are those of DAS-Simulation `define_events.m`; running, climbing, animal and the background-noise event are ASSUMED (no source).
* Ground coupling (burial, soil, intruder-to-cable distance) is a log-normal factor with sigma 0.4 and mean 1 (ASSUMED). Detection is therefore dominated by this assumption at long range: the 0.977 is a property of the model, not a measured Pd.
* The detection statistic is the band-limited (8 to 200 Hz) energy of the recovered elongation, peak over channels / median; a plain activity statistic (std of dL) detects far less at long range (S of walking at 18 km about 3, same as noise). Intrinsic false alarms use a normal-tail extrapolation.
* The engine does not model laser phase noise, polarisation fading, splices, real cable coupling or the interrogator's own processing (see DAS-Simulation README); no real FEBUS recording has been compared.

# Assumptions and limits of the classifier (Brno dataset)
* **The labelled Brno data are not enough to estimate the true accuracy of an event classifier.** Each class has between 1 and 4 recordings of 20 to 70 seconds from ONE site, ONE interrogator (Optasense ODH-F), one buried cable and a few people / vehicles. Windows cut from one recording are strongly correlated, so every accuracy we compute has wide confidence limits (bootstrap over recordings) and must always be quoted with them and with the number of recordings. A single accuracy figure without limits and recording counts is not reported anywhere in this repository.
* The published 93.5 % (random windows) is not comparable with our grouped number: random windows put neighbouring windows of the same recording in train and test.
* Classes with ONE recording (running, construction, regular and possibly others) are evaluated with a temporal split of the same recording (first 60 % train, 10 % gap dropped, last 30 % test). Their results are labelled **"same recording, temporal split"** and are optimistic (same person, same place).
* The class `animal` has no data in any public set: its accuracy is a PLACEHOLDER (`Pc_animal_placeholder`).
* The classifier is trained on a different device and site than FEBUS: its accuracy on FEBUS is unknown until real FEBUS recordings exist (Phase 0).
* **Use in the simulation**: the optimization keeps Pc_DAS from the literature (0.983 to 0.993, wang2024). The Brno confusion matrix is used in the unified simulation only for the SHAPE of the errors (what is confused with what). If its accuracy is lower than the literature, both cases are shown as a sensitivity. The simulated-window check (classifier applied to our simulated windows) is a separate "sim-domain check" table and is never mixed with the Brno table.
