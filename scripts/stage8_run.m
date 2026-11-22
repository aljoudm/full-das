% STAGE8_RUN  Stage 8: system-level metrics for low / medium / high (base classifier stub, ASSUMED) and the Brno-matrix SENSITIVITY (medium).
% All numbers SIMULATED. N days per case (default 60; Stage 9 runs until >= 10,000 intruders). Writes results/stage8/run_<case>.mat (not in git) and
% results/stage8/metrics_summary.csv (every metric with a 95 % day-bootstrap interval, label SIMULATED, source).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
nD = 60;   seed = 8080;
P = load_params_fd();   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);
cases = {'low', 'uniform'; 'medium', 'uniform'; 'high', 'uniform'; 'medium', 'confusion_counts'};
names = {'low', 'medium', 'high', 'medium_BrnoMatrix_SENSITIVITY'};
Es = cell(4, 1);   FAs = cell(4, 1);   t0 = tic;
parfor k = 1:4
    [Es{k}, FAs{k}] = run_scenario(P, T, TP, lib, cases{k, 1}, nD, seed, cases{k, 2});
end
fprintf('simulated %d days x 4 cases in %.0f s\n', nD, toc(t0));
rows = table();
for k = 1:4
    E = Es{k};   FA = FAs{k};   save(fullfile(root, 'results', 'stage8', ['run_' names{k} '.mat']), 'E', 'FA');
    M = compute_metrics(E, FA, T, P);   r = M.rows;   r.case = repmat(string(names{k}), height(r), 1);   r.label = repmat("SIMULATED", height(r), 1);
    r.classifier = repmat(string(cases{k, 2}), height(r), 1);   r.intruders = repmat(M.intruders, height(r), 1);   r.days = repmat(nD, height(r), 1);   rows = [rows; r]; %#ok<AGROW>
end
writetable(rows, fullfile(root, 'results', 'stage8', 'metrics_summary.csv'));
% ---- re-identification in the simulation: spacing to the nearest simultaneous intruder -> person-level link accuracy of the grid (SIMULATED lookup)
G = readtable(fullfile(root, 'results', 'reid', 'reid_grid.csv'));   r = T.cells.ring;   arc = r.s(:);   grid = [50 20 10 5 2 1];   RE = table();
for k = 1:3
    E = Es{k};   n = height(E);   sp = inf(n, 1);   tr = 600;                                   % an intruder is tracked for 600 s (ASSUMED) after its entry
    for d = 1:nD
        ii = find(E.day == d);   if numel(ii) < 2, continue; end
        for a = ii'
            o = ii(ii ~= a);   o = o(abs(E.t_start(o) - E.t_start(a)) < tr);
            if ~isempty(o), dd = abs(arc(E.piece(o)) - arc(E.piece(a)));   dd = min(dd, r.L - dd);   sp(a) = min(dd); end
        end
    end
    ver = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none");   src = repmat("drone_base", n, 1);   src(E.asset == "camera") = "fixed";
    acc = nan(n, 1);   rate = nan(n, 1);
    for a = find(ver)'
        g = grid(find(grid <= sp(a), 1));   if isempty(g), g = 1; end
        q = G(G.camera_source == src(a) & G.spacing_m == g & G.pairs_share == 0 & G.position_error_m == 1 & G.clock_offset_s == 0.2 & string(G.crossing) == "False" & G.camera_dropout == 0, :);
        acc(a) = q.person_link_acc(1);   rate(a) = q.person_link_rate(1);
    end
    RE = [RE; table(string(names{k}), nnz(ver), mean(sp(ver) < 50), mean(sp(ver) < 20), mean(sp(ver) < 10), mean(isinf(sp(ver))), mean(acc(ver), 'omitnan'), mean(rate(ver), 'omitnan'), ...
        'VariableNames', {'case', 'verified_intruders', 'share_neighbour_below_50m', 'share_neighbour_below_20m', 'share_neighbour_below_10m', 'share_no_simultaneous_neighbour', 'implied_person_link_accuracy', 'implied_person_link_rate'})]; %#ok<AGROW>
end
RE.label = repmat("SIMULATED (lookup in reid_grid.csv, pairs 0 %, clock 0.2 s, drone base 2.5 m or fixed camera 1 m)", 3, 1);
writetable(RE, fullfile(root, 'results', 'stage8', 'reid_in_simulation.csv'));   disp(RE);
disp(rows(rows.case == "medium" & ismember(rows.metric, {'Pd', 'Pc_cond', 'Pd_x_Pc', 'verified_Tresp', 'verified_Tresp_hot', 'patrol_reached', 'fa_before_all', 'fa_patrol', 'height_measurable'}), {'metric', 'value', 'lo', 'hi', 'n_num', 'n_den'}));
