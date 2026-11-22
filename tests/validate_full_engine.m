% VALIDATE_FULL_ENGINE  The window strategy against the FULL 20 km phi-OTDR run of the frozen engine (slow: about 2-4 min and 3 GB per case).
% For each case an event is placed at z0 on the full 20 km fibre; the detection statistic S of a +-150 m crop (same das_detect, same decimation)
% is compared with the S of window simulations at the same distance (coupling 1, 10 random fibres). Also checks the OTDR backscatter slope.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P0 = load_params_fd();   p = das_params();   cfg = struct('L_win_m', P0.fd.L_win_m, 'T_win_s', P0.fd.T_win_s, 'fs_win_hz', P0.fd.fs_win_hz, 'PRF_hz', p.f_rep);
fprintf('--- full-engine validation ---\n');
cases = {'walking', 12e3; 'vehicle', 4e3; 'digging', 18e3; 'background', 10e3};
for c = 1:size(cases, 1)
    type = cases{c, 1};   z0 = cases{c, 2};   tic;
    evalc('P = params(struct(''seed'', 77 + c));');   evalc('F = fiber_model(P);');
    s = RandStream('Threefry', 'Seed', 5 + c);
    if strcmp(type, 'background'), dL = zeros(1, P.Npulses); w = 3; else, [dL, w] = das_waveform(type, P.t_slow, s, 1); end
    ev = struct('name', type, 'type', type, 'z0', z0, 'w', w, 'dL', dL);   ev.phi_t = P.k_strain * dL;   ev.ramp = min(max((P.z_fine(:) - (z0 - w / 2)) / w, 0), 1);
    evalc('Wf = simulate_waterfall(P, F, ev);');   evalc('D = detector(P, Wf, ''coherent'');');   clear Wf;   evalc('R = process_das(P, D);');   clear D;
    k = R.z >= z0 - cfg.L_win_m / 2 & R.z < z0 + cfg.L_win_m / 2;   X = double(R.dL(k, :)).';   clear R;
    dec = round(cfg.PRF_hz / cfg.fs_win_hz);   [b, a] = butter(4, 0.8 / dec);   Y = filtfilt(b, a, X);   Y = Y(1:dec:end, :);
    Wf = struct('dL', single(Y), 'fs', cfg.PRF_hz / dec, 'z', (0:size(Y, 2) - 1) * P.dz_adc, 'z0', cfg.L_win_m / 2);
    [Sf, zh] = das_detect(Wf);
    Sw = zeros(10, 1);   for r = 1:10, Wr = das_window(type, z0, 1, 300 + r, cfg);   Sw(r) = das_detect(Wr); end
    fprintf('%-10s z0 = %4.1f km: full-engine S = %8.1f (loc err %5.1f m) | window sims S: median %8.1f, range %8.1f to %8.1f  (%.0f s)\n', ...
        type, z0 / 1e3, Sf, zh - Wf.z0, median(Sw), min(Sw), max(Sw), toc);
    if strcmp(type, 'background'), assert(Sf < 12 && max(Sw) < 12, 'background statistic'); else
        assert(Sf > min(Sw) / 2 && Sf < max(Sw) * 2, 'full-engine S outside the window-simulation range (factor 2)'); end
end
% OTDR sanity (OTDR- repo: conventional trace slope 0.400 dB/km): mean backscatter of the engine over 20 km
evalc('P = params();');   evalc('F = fiber_model(P);');   T = simulate_trace(P, F);
zk = P.z(:) / 1e3;   Pm = movmean(T.Pw, 400);   ok = zk > 0.5 & zk < 19.5;   cf = polyfit(zk(ok), 10 * log10(Pm(ok)), 1);
fprintf('engine backscatter slope %.3f dB/km (OTDR- model and theory: -0.400); resolution %.2f m (OTDR-: 10.2 m for 100 ns)\n', cf(1), P.dz_res);
assert(abs(cf(1) + 0.4) < 0.03, 'backscatter slope');
fprintf('Full-engine validation: ALL PASSED\n');
