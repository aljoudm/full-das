% TEST_STAGE4  DAS window library: SNR vs the engine's own expected values, detection and localization statistics, threshold / false alarms.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   fprintf('--- Stage 4 tests ---\n');
lib = build_das_library(P);   cfg = lib.cfg;
% 1) local SNR of the window equals the engine's analytic value (DAS-Simulation README: 34.8 / 30.8 / 26.8 dB at 0 / 10 / 20 km)
for d = [0 10e3 20e3]
    [~, k] = min(abs(lib.dist_m - d));   m = lib.dist_idx == k;   snr = mean(lib.snr_db(m));
    exp_snr = 34.8 - 0.4 * (lib.dist_m(k) + cfg.L_win_m / 2) / 1e3;
    fprintf('distance %5.1f km: library SNR %.2f dB, analytic %.2f dB\n', lib.dist_m(k) / 1e3, snr, exp_snr);
    assert(abs(snr - exp_snr) < 0.3, 'SNR differs from the analytic value');
end
% 2) detection rate by type and distance (coupling log-normal, sigma = %.1f)
fprintf('detection threshold S = %.1f; noise-only windows above it: %.4f (normal-tail estimate %.2g per window)\n', lib.thr, lib.p_fa_window_empirical, lib.p_fa_window_normal);
fprintf('%-10s', 'type'); fprintf('%8.1f km', lib.dist_m / 1e3); fprintf('\n');
for t = 1:numel(lib.types)
    fprintf('%-10s', lib.types{t});
    for d = 1:numel(lib.dist_m)
        m = lib.type_idx == t & lib.dist_idx == d;   fprintf('%11.2f', mean(lib.S(m) > lib.thr));
    end
    fprintf('\n');
end
assert(lib.p_fa_window_empirical < 0.01, 'noise-only windows trigger too often');
hum = ismember(lib.types(lib.type_idx), {'walking', 'running', 'vehicle', 'digging', 'climbing'});   hum = hum(:);
pd = mean(lib.S(hum) > lib.thr);   fprintf('overall detection of intrusion types in the library: %.3f (literature Pd_DAS 0.969; reported separately)\n', pd);
assert(pd > 0.8, 'detection of intrusions too low for these amplitudes');
% 3) localization of the detected ones: engine resolution is 10 m, channel spacing 2 m
det = lib.S > lib.thr & hum;   ae = abs(lib.z_err(det));
fprintf('localization error of detected intrusions: median %.1f m, 95th percentile %.1f m, max %.1f m\n', median(ae), prctile(ae, 95), max(ae));
assert(median(ae) <= 10 && prctile(ae, 95) <= 30, 'localization too coarse');
% 4) window geometry
assert(size(lib.dL{1}, 2) == numel(lib.z) && size(lib.dL{1}, 1) == numel(lib.t), 'window size');
fprintf('window: %d time samples at %.0f Hz x %d channels (%.0f m, %.1f s)\n', numel(lib.t), lib.fs, numel(lib.z), cfg.L_win_m, cfg.T_win_s);
% 5) das_observe on a simulated day (events from Stage 3, allocation of Stage 2)
[al, ~, A] = get_allocation(P, 'medium');   T = load_twin(P);   TP = terrain_pieces(T, P);   G = gen_setup(T, TP, P, A);
sg = RandStream('Threefry', 'Seed', 99);   ev = gen_day(T, TP, G, P, sg, 1);   tic;   ob = das_observe(ev, T, al, lib, sg);
fprintf('das_observe: %d events in %.1f s; distance to interrogator max %.1f km (limit R_DAS = %.0f km)\n', height(ev), toc, max(ob.dist_m) / 1e3, P.v.R_DAS_m / 1e3);
assert(max(ob.dist_m) <= P.v.R_DAS_m, 'an event is farther than R_DAS from its interrogator');
ii = ev.is_intrusion;   fprintf('this day: %d intrusions, detected %d; non-intrusion events detected: animals %d/%d, authorized vehicles %d/%d, noise %d/%d\n', nnz(ii), nnz(ob.detected(ii)), ...
    nnz(ob.detected(ev.kind == "animal")), nnz(ev.kind == "animal"), nnz(ob.detected(ev.kind == "normal_vehicle")), nnz(ev.kind == "normal_vehicle"), nnz(ob.detected(ev.kind == "noise")), nnz(ev.kind == "noise"));
assert(mean(ob.detected(ii)) > 0.85, 'intrusion detection in the day');
fprintf('Stage 4: ALL PASSED\n');
