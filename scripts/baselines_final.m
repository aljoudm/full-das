% BASELINES_FINAL  The two optimization baselines (decision D12 of the optimization repo, scripts/make_stage5.m) on the FINAL siting model and its final drone layout. NEW files only, in
% results/baselines_final/.
%   Baseline 1  existing assets only (cameras, no DAS; drones verify, they do not detect): static camera coverage and detection per zone, plus the intruder-weighted expected detection
%               (cell intrusion rate of the table x Pd of the cell).
%   Baseline 2  the same number of drones spread evenly, not optimised, with the definitions of make_stage5: 2 = pairs of drones on stations spaced evenly along the boundary (one single if N is odd);
%               2b = the same pairs spread over the SAME candidate stations the optimizer uses (k-means, seed 20261101, snapped); 2c = the even boundary spacing at the best of 40 phase offsets
%               (most Hot cells verified); singles = one drone per station, evenly spaced. "Optimal" = drone stations of results/alloc_<scenario>_22_siting.mat (final design).
%               Two evaluations: STATIC (drone_layout: cells with a verification layer, as in the optimization report) and MONTE CARLO (the final Stage 9 configuration, seed 9090, 394 days,
%               10,004 intruders, common random numbers; only the drone stations change). A control case (medium, the optimal stations passed through the same override) must reproduce
%               results/stage9_siting_final.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   od = fullfile(root, 'results', 'baselines_final');   if ~isfolder(od), mkdir(od); end
P = load_params_fd();   P.sim = struct('siting', true, 'pdmodel', true);   v = P.v;   T = load_twin(P);
Po = P;   Po.assets.allow_filler = false;   cells = load_cells(Po);   A = place_existing_assets(Po, cells);   M = coverage_model(Po, cells, A);   ring = cells.ring;   L = ring.L;   hot = cells.zoneCode == 3;
zn = {'Cold', 'Neutral', 'Hot'};   scn = {'low', 'medium', 'high'};
% ------------------------------------------------------------------ baseline 1
Pd0 = A.coverFrac(:) * v.Pd_CCTV;   lam = T.lambda.mid(:);   rows1 = {};
for k = [3 2 1 0]
    if k > 0, in = cells.zoneCode(:) == k;   nm = zn{k}; else, in = true(cells.n, 1);   nm = 'All'; end
    rows1(end+1, :) = {string(nm), nnz(in), 100 * sum(A.coveredLen_m(in)) / sum(cells.L_m(in)), min(Pd0(in)), mean(Pd0(in)), max(Pd0(in)), nnz(Pd0(in) >= v.AD0), 100 * sum(lam(in) .* Pd0(in)) / sum(lam(in))}; %#ok<SAGROW>
end
B1 = cell2table(rows1, 'VariableNames', {'zone', 'cells', 'boundary_covered_by_cameras_pct', 'Pd_min', 'Pd_mean', 'Pd_max', 'cells_meeting_AD0', 'intruder_weighted_expected_detection_pct'});
writetable(B1, fullfile(od, 'baseline1_existing_assets_only.csv'));   disp(B1);
% ------------------------------------------------------------------ baseline 2: layouts and the static evaluation
names = {'optimal', 'even_boundary_2', 'even_candidates_2b', 'even_best_phase_2c', 'even_singles'};   lays = struct('scenario', {}, 'layout', {}, 'xy', {}, 'n', {});   st = {};
for s = 1:3
    X = load(fullfile(root, 'results', ['alloc_' scn{s} '_22_siting.mat']));   al = X.alloc;   N = al.drones.total;   sc = P.assets.scenarios(strcmp({P.assets.scenarios.name}, scn{s}));   assert(N == sc.N_drone, 'drone count');
    Ns = ceil(N / 2);   nd2 = [2 * ones(floor(N / 2), 1); mod(N, 2) * ones(mod(N, 2), 1)];
    onRing = @(arc) arrayfun(@(a) find(abs(ring.s - a) == min(abs(ring.s - a)), 1), arc(:));
    k2 = onRing(((1:Ns) - 0.5) * L / Ns);   xy2 = [ring.x(k2(:)) ring.y(k2(:))];   xy2 = reshape(xy2, Ns, 2);
    k1 = onRing(((1:N) - 0.5) * L / N);   xy1 = reshape([ring.x(k1(:)) ring.y(k1(:))], N, 2);
    rng(20261101);   [~, Cc] = kmeans(M.stationXY, Ns, 'Replicates', 20, 'Start', 'plus');   xy2b = zeros(Ns, 2);
    for j = 1:Ns, [~, k] = min(hypot(M.stationXY(:, 1) - Cc(j, 1), M.stationXY(:, 2) - Cc(j, 2)));   xy2b(j, :) = M.stationXY(k, :); end
    best = -1;
    for ph = (0:39) / 40
        kp = onRing(mod(((0:Ns-1) + ph) * L / Ns, L));   xyP = reshape([ring.x(kp(:)) ring.y(kp(:))], Ns, 2);   lP = drone_layout(cells, P, xyP, nd2);   h = nnz(lP.verified(:) & hot(:));
        if h > best, best = h;   xy2c = xyP; end
    end
    XY = {al.drones.station_xy, xy2, xy2b, xy2c, xy1};   ND = {al.drones.n(:), nd2, nd2, nd2, ones(N, 1)};
    for q = 1:5
        lay = drone_layout(cells, P, XY{q}, ND{q});   ver = lay.verified(:);
        st(end+1, :) = {string(scn{s}), string(names{q}), N, numel(ND{q}), nnz(ver & hot(:)), nnz(hot), 100 * nnz(ver & hot(:)) / nnz(hot), nnz(ver), cells.n, 100 * sum(lam(ver)) / sum(lam)}; %#ok<SAGROW>
        lays(end+1) = struct('scenario', scn{s}, 'layout', names{q}, 'xy', XY{q}, 'n', ND{q}); %#ok<SAGROW>
    end
end
B2s = cell2table(st, 'VariableNames', {'scenario', 'layout', 'drones', 'stations', 'Hot_cells_verified', 'Hot_cells', 'Hot_verified_pct', 'cells_verified', 'cells', 'intrusion_rate_in_verified_cells_pct'});
writetable(B2s, fullfile(od, 'baseline2_even_drones_static.csv'));   save(fullfile(od, 'drone_layouts.mat'), 'lays');   disp(B2s);
% ------------------------------------------------------------------ baseline 2: Monte Carlo (the four even layouts in every scenario + one control)
TP = terrain_pieces(T, P);   lib = build_das_library(P);
run = find(~strcmp({lays.layout}, 'optimal') | strcmp({lays.scenario}, 'medium'));   nC = numel(run);   Es = cell(nC, 1);   FAs = cell(nC, 1);
if isempty(gcp('nocreate')), cl = parcluster('Processes');   cl.NumWorkers = nC;   parpool(cl, nC); end
t0 = tic;
parfor k = 1:nC
    q = lays(run(k));   Pk = P;   Pk.sim.drones = struct('station_xy', q.xy, 'n', q.n);
    [Es{k}, FAs{k}] = run_scenario(Pk, T, TP, lib, q.scenario, 10000, 9090, 'uniform', 0);
end
fprintf('Monte Carlo done in %.0f s\n', toc(t0));
mets = {'Pd', 'verified_Tresp', 'verified_Tresp_hot', 'patrol_reached', 'patrol_reached_of_alarms', 'median_verification_s', 'median_alarm_to_patrol_s', 'fa_patrol'};
S9 = readtable(fullfile(root, 'results', 'stage9_siting_final', 'metrics_summary.csv'));   rows = table();
for s = 1:3
    q = S9(strcmp(S9.run_case, scn{s}) & ismember(S9.metric, mets), :);
    rows = [rows; table(repmat(string(scn{s}), height(q), 1), repmat("optimal", height(q), 1), string(q.metric), q.value, q.lo, q.hi, q.days, 'VariableNames', {'scenario', 'layout', 'metric', 'value', 'lo', 'hi', 'days'})]; %#ok<AGROW>
end
mx = NaN;
for k = 1:nC
    q = lays(run(k));   E = Es{k};   FA = FAs{k};   Mt = compute_metrics(E, FA, T, P);   m = Mt.rows(ismember(Mt.rows.metric, mets), :);
    if strcmp(q.layout, 'optimal')                                           % control: the override with the optimal stations reproduces the final Stage 9 run
        ref = S9(strcmp(S9.run_case, q.scenario), :);   mx = 0;
        for i = 1:height(m), v0 = ref.value(strcmp(ref.metric, m.metric{i}));   mx = max(mx, abs(v0 - m.value(i)) / max(abs(v0), eps)); end
        fprintf('control (optimal stations through the override) versus results/stage9_siting_final: largest relative difference %.2e\n', mx);   assert(mx < 1e-9, 'the control differs from the final Stage 9 run');
        continue
    end
    save(fullfile(od, sprintf('run_%s_%s.mat', q.scenario, q.layout)), 'E', 'FA');
    rows = [rows; table(repmat(string(q.scenario), height(m), 1), repmat(string(q.layout), height(m), 1), string(m.metric), m.value, m.lo, m.hi, repmat(FA.nDays, height(m), 1), 'VariableNames', {'scenario', 'layout', 'metric', 'value', 'lo', 'hi', 'days'})]; %#ok<AGROW>
end
assert(~isnan(mx), 'control case missing');   rows.label = repmat("SIMULATED", height(rows), 1);
writetable(rows, fullfile(od, 'baseline2_even_drones_montecarlo.csv'));   fprintf('baselines done\n');
