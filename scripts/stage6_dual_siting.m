% STAGE6_DUAL_SITING  Single versus dual verification on the FINAL model (6 sited interrogators, unified Pd(d), the siting allocation of results/alloc_<scenario>_22_siting.mat).
% Same configuration, seed and common random numbers as the Stage 9 siting run (seed 9090, days until at least 10,000 real intruder events = 394 days): only P.fd.dual_verify changes.
%   A = single check (dual_verify 0, base) | B = dual everywhere (1) | C = dual in Neutral and Cold, single in Hot (2)
% NEW outputs only: results/stage6_dual_siting.csv and results/stage6_dual_siting/run_<scenario>_<option>.mat (the old results/stage6_dual.csv is not touched).
% Per scenario x option, with 95 % bootstrap limits over days (compute_metrics): false patrols per km per day, median verification time, median alarm-to-patrol time, patrol reached (share of
% true alarms), intruders not verified within T_resp (all / Hot), true alarms verified later than T_resp (share of the true alarms that have an asset). Check: option A must equal results/stage9_siting.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
minN = 10000;   seed = 9090;   od = fullfile(root, 'results', 'stage6_dual_siting');   if ~isfolder(od), mkdir(od); end
P = load_params_fd();   P.sim = struct('siting', true, 'pdmodel', true);   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);   km = T.cells.ring.L / 1e3;
scn = {'low', 'medium', 'high'};   opt = {'A', 'B', 'C'};   [si, oi] = ndgrid(1:3, 1:3);   si = si(:);   oi = oi(:);   nC = numel(si);
if isempty(gcp('nocreate')), cl = parcluster('Processes');   cl.NumWorkers = nC;   parpool(cl, nC); end
Es = cell(nC, 1);   FAs = cell(nC, 1);   t0 = tic;
parfor k = 1:nC
    Pk = P;   Pk.fd.dual_verify = oi(k) - 1;
    [Es{k}, FAs{k}] = run_scenario(Pk, T, TP, lib, scn{si(k)}, minN, seed, 'uniform', 0);
end
fprintf('Monte Carlo done in %.0f s\n', toc(t0));
rows = table();   B = 2000;
for k = 1:nC
    E = Es{k};   FA = FAs{k};   save(fullfile(od, sprintf('run_%s_%s.mat', scn{si(k)}, opt{oi(k)})), 'E', 'FA');
    M = compute_metrics(E, FA, T, P);   m = M.rows;   g = @(name) m(strcmp(m.metric, name), :);
    hasAsset = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none");   late = hasAsset & ~E.in_Tresp;   nD = FA.nDays;
    rs = RandStream('Threefry', 'Seed', 321);   dayIdx = arrayfun(@(d) find(E.day == d), 1:nD, 'UniformOutput', false);   bs = zeros(B, 1);
    for b = 1:B, ii = vertcat(dayIdx{randi(rs, nD, nD, 1)});   bs(b) = nnz(late(ii)) / max(nnz(hasAsset(ii)), 1); end
    lateV = nnz(late) / max(nnz(hasAsset), 1);   lateLo = prctile(bs, 2.5);   lateHi = prctile(bs, 97.5);
    ver = g('verified_Tresp');   verH = g('verified_Tresp_hot');   fp = g('fa_patrol');   mv = g('median_verification_s');   mp = g('median_alarm_to_patrol_s');   pr = g('patrol_reached_of_alarms');
    r = table(string(scn{si(k)}), string(opt{oi(k)}), oi(k) - 1, nD, seed, height(E), fp.value, fp.lo, fp.hi, fp.n_num / nD, mv.value, mv.lo, mv.hi, mp.value, mp.lo, mp.hi, pr.value, pr.lo, pr.hi, ...
        1 - ver.value, 1 - ver.hi, 1 - ver.lo, (ver.n_den - ver.n_num) / nD, 1 - verH.value, 1 - verH.hi, 1 - verH.lo, lateV, lateLo, lateHi, ...
        'VariableNames', {'scenario', 'option', 'dual_verify', 'days', 'seed', 'intruder_events', 'false_patrols_per_km_day', 'fp_lo', 'fp_hi', 'false_patrols_per_day', 'median_verification_s', 'mv_lo', 'mv_hi', ...
        'median_alarm_to_patrol_s', 'mp_lo', 'mp_hi', 'patrol_reached_of_true_alarms', 'pr_lo', 'pr_hi', 'not_verified_in_Tresp_all', 'nv_lo', 'nv_hi', 'not_verified_per_day', 'not_verified_in_Tresp_hot', 'nvh_lo', 'nvh_hi', ...
        'true_alarms_verified_late', 'late_lo', 'late_hi'});
    rows = [rows; r];   %#ok<AGROW>
end
rows.label = repmat("SIMULATED", height(rows), 1);   rows.false_patrols_per_day = rows.false_patrols_per_km_day * km;
writetable(rows, fullfile(root, 'results', 'stage6_dual_siting.csv'));   disp(rows(:, {'scenario', 'option', 'days', 'false_patrols_per_km_day', 'median_verification_s', 'median_alarm_to_patrol_s', 'patrol_reached_of_true_alarms', 'not_verified_in_Tresp_all', 'not_verified_in_Tresp_hot', 'true_alarms_verified_late'}));
% ---- check: option A equals the Stage 9 siting run (same seed, same days, same configuration)
S9 = readtable(fullfile(root, 'results', 'stage9_siting', 'metrics_summary.csv'));   mx = 0;
for s = 1:3
    a = rows(rows.scenario == scn{s} & rows.option == "A", :);   q = S9(strcmp(S9.run_case, scn{s}), :);
    for pair = {{'verified_Tresp', 1 - a.not_verified_in_Tresp_all}, {'patrol_reached_of_alarms', a.patrol_reached_of_true_alarms}, {'fa_patrol', a.false_patrols_per_km_day}, {'median_verification_s', a.median_verification_s}}
        v0 = q.value(strcmp(q.metric, pair{1}{1}));   mx = max(mx, abs(v0 - pair{1}{2}) / max(abs(v0), eps));
    end
end
fprintf('option A versus results/stage9_siting: largest relative difference %.2e\n', mx);   assert(mx < 1e-9, 'option A differs from the Stage 9 siting run');
