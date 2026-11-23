% SITING_PD_CURVE  Pd(d): detection probability of the simulated DAS against the TOTAL OPTICAL DISTANCE d from the interrogator, every 1 km from 0 to 25 km, with 95 % confidence limits.
%
% Source and model (exactly):
%   * windows: src/das/das_window.m, which runs the FROZEN phi-OTDR engine of DAS-Simulation (third_party/das_engine, commit 3a8862b) on a short fibre window around one event;
%   * SNR / attenuation: third_party/das_engine/das_params.m (FEBUS A1-NEO): fibre loss alpha = 0.2 dB/km [DATASHEET, rev. 20260618], launched power P0 = 0.1 W [ASSUMED, Thevenaz 2025],
%     Rayleigh backscatter coefficient -82 dB [ASSUMED, Corning PI-1424], receiver noise power fixed by the pulse bandwidth. The signal at optical distance d is scaled by the round-trip
%     loss exp(-2 alpha d) (das_window 'dist_m'), the noise is NOT scaled: local SNR = 34.8 dB at 0 km, 30.8 dB at 10 km, 26.8 dB at 20 km (checked in tests/test_stage4.m);
%   * events: das_waveform.m (walking, digging, vehicle from define_events.m of DAS-Simulation; running, climbing ASSUMED), ground coupling log-normal (sigma 0.4, mean 1, ASSUMED);
%   * detection: statistic S of src/das/das_detect.m above the threshold lib.thr (mean + 6 sigma of the noise-only windows), as in the Monte Carlo;
%   * mix: the five intrusion types weighted as they occur in the Stage 9 run (walking, running, vehicle, digging, climbing).
% N windows per (distance, type) = 80 (different random fibre fingerprints and couplings). Output: results/siting/pd_curve.csv, pd_curve.png, d_star.json.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   lib = build_das_library(P);   p = das_params();   cfg = struct('L_win_m', P.fd.L_win_m, 'T_win_s', P.fd.T_win_s, 'fs_win_hz', P.fd.fs_win_hz, 'PRF_hz', p.f_rep);
types = {'walking', 'running', 'vehicle', 'digging', 'climbing'};   dist = (0:25) * 1e3;   nW = 80;   sg = P.fd.coupling_sigma;
S9 = load(fullfile(root, 'results', 'stage9', 'run_medium.mat'));   share = arrayfun(@(t) mean(S9.E.type == t), string(types));   share = share / sum(share);
[ti, di, wi] = ndgrid(1:numel(types), 1:numel(dist), 1:nW);   ti = ti(:);   di = di(:);   wi = wi(:);   N = numel(ti);
rs = RandStream('Threefry', 'Seed', 7777);   coup = exp(sg * randn(rs, N, 1) - sg^2 / 2);   seed = 500000 + (1:N)';   S = zeros(N, 1);   thr = lib.thr;
t0 = tic;
parfor k = 1:N
    W = das_window(types{ti(k)}, dist(di(k)), coup(k), seed(k), cfg);   S(k) = das_detect(W);
end
fprintf('Pd(d): %d windows in %.0f s\n', N, toc(t0));   save(fullfile(root, 'results', 'pd_curve_raw.mat'), 'S', 'ti', 'di', 'thr');
det = S > thr;   B = 2000;   rb = RandStream('Threefry', 'Seed', 8888);   rows = zeros(numel(dist), 4);   perType = zeros(numel(dist), numel(types));
for j = 1:numel(dist)
    pt = zeros(1, numel(types));   for t = 1:numel(types), pt(t) = mean(det(ti == t & di == j)); end
    perType(j, :) = pt;   pm = sum(share .* pt);   bs = zeros(B, 1);
    for b = 1:B                                                           % bootstrap the windows inside every type (stratified), re-weight by the type shares
        q = 0;   for t = 1:numel(types), x = det(ti == t & di == j);   q = q + share(t) * mean(x(randi(rb, nW, nW, 1)));   end
        bs(b) = q;
    end
    rows(j, :) = [dist(j) / 1e3, pm, prctile(bs, 2.5), prctile(bs, 97.5)];
end
T = array2table([rows, perType], 'VariableNames', [{'distance_km', 'Pd_mix', 'Pd_lo95', 'Pd_hi95'}, strcat('Pd_', types)]);   T.n_windows_per_type = repmat(nW, height(T), 1);
T.local_snr_dB = 34.8 - 0.4 * T.distance_km;   T.label = repmat("SIMULATED", height(T), 1);
od = fullfile(root, 'results', 'siting');   if ~isfolder(od), mkdir(od); end
writetable(T, fullfile(od, 'pd_curve.csv'));
% ---- d*: the largest distance up to which Pd(d) stays >= Pd_DAS (the value the optimization assumes). Monotone (pooled-adjacent-violators) fit of the point estimates, plus the same rule on the lower / upper limit.
Pd_target = P.v.Pd_DAS;   y = T.Pd_mix;   w = ones(size(y));   blocks = num2cell(y);   wt = num2cell(w);
i = 1;   while i < numel(blocks)                                           % PAV for a non-increasing sequence
    if blocks{i} < blocks{i + 1} - 1e-12, m = (blocks{i} * wt{i} + blocks{i + 1} * wt{i + 1}) / (wt{i} + wt{i + 1});   blocks{i} = m;   wt{i} = wt{i} + wt{i + 1};   blocks(i + 1) = [];   wt(i + 1) = [];   i = max(i - 1, 1); else, i = i + 1; end
end
mono = repelem(cell2mat(blocks(:)), cell2mat(wt(:)));
dstar = @(v) (find(v < Pd_target, 1) - 2);      % index of the last distance with v >= target (distance in km = index since the grid starts at 0 with 1 km steps)
ds_fit = dstar(mono);   if isempty(ds_fit), ds_fit = 25; end
ds_lo = dstar(T.Pd_lo95);   if isempty(ds_lo) || ds_lo < 0, ds_lo = NaN; end,   ds_hi = dstar(T.Pd_hi95);   if isempty(ds_hi), ds_hi = 25; end
ranges = [5 10 20 70 100];   opt = ranges(find(ranges >= ds_fit, 1));
N_min = ceil((P.v.L_boundary_m / 1e3) / (2 * ds_fit));
json = struct('Pd_target', Pd_target, 'd_star_km', ds_fit, 'd_star_km_if_lower_95_limit_used', ds_lo, 'd_star_km_if_upper_95_limit_used', ds_hi, 'febus_range_option_km', opt, 'N_min', N_min, 'L_boundary_km', P.v.L_boundary_m / 1e3, ...
    'rule', 'largest d with the monotone (PAV) fit of Pd(d) >= Pd_target', 'windows_per_type_per_distance', nW, 'type_share', cell2struct(num2cell(share), types, 2));
fid = fopen(fullfile(od, 'd_star.json'), 'w');   fprintf(fid, '%s', jsonencode(json, 'PrettyPrint', true));   fclose(fid);
fprintf('d* = %d km (lower-limit rule %s, upper-limit rule %d), FEBUS range option %d km, N_min = %d\n', ds_fit, num2str(ds_lo), ds_hi, opt, N_min);
fig = figure('Color', 'w', 'Position', [60 60 900 480]);   ax = axes(fig);   hold(ax, 'on');   fill(ax, [T.distance_km; flipud(T.distance_km)], 100 * [T.Pd_lo95; flipud(T.Pd_hi95)], [0.75 0.85 0.95], 'EdgeColor', 'none', 'FaceAlpha', 0.7);
plot(ax, T.distance_km, 100 * T.Pd_mix, 'o-', 'Color', [0.05 0.3 0.7], 'LineWidth', 1.5);   plot(ax, T.distance_km, 100 * mono, 'r-', 'LineWidth', 1.2);   yline(ax, 100 * Pd_target, 'k--', sprintf('Pd_{DAS} = %.3f', Pd_target));   xline(ax, ds_fit, 'g-', sprintf('d* = %d km', ds_fit), 'LineWidth', 1.5);
xlabel(ax, 'total optical distance from the interrogator d [km]');   ylabel(ax, 'Pd [%]');   ylim(ax, [60 101]);   grid(ax, 'on');   legend(ax, {'95 % limits', 'Pd(d), type mix', 'monotone fit', ''}, 'Location', 'southwest');
title(ax, sprintf('Detection probability vs optical distance (SIMULATED; FEBUS A1-NEO, loss 0.2 dB/km; %d windows per type and distance)', nW), 'FontSize', 9);
exportgraphics(fig, fullfile(od, 'pd_curve.png'), 'Resolution', 200);
