% STAGE9_RUN  Stage 9: full Monte Carlo. Every case runs days until at least 10,000 real intruder EVENTS have occurred (N_MC of the table: the number of independent events for a +/- 0.27 %
% margin on a 98 % proportion). Common random numbers across cases (same seed per day). All numbers SIMULATED.
% Cases: low / medium / high with the BASE uniform classifier stub (Pc 0.983, ASSUMED) and single intruders; medium with the Brno confusion matrix (SENSITIVITY only);
% medium with group intrusions p_group = 25 % and 50 % (ASSUMED sensitivities).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
minN = 10000;   seed = 9090;   outn = getenv('STAGE9_OUT');   if isempty(outn), outn = 'stage9'; end,   if ~isfolder(fullfile(root, 'results', outn)), mkdir(fullfile(root, 'results', outn)); end
P = load_params_fd();   if strcmp(outn, 'stage9_siting'), P.sim = struct('siting', true, 'pdmodel', true); end,   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);   % siting allocations (6 shelters, lead-in) + the unified Pd(d) model; same seed (common random numbers) as the base run
cases = {'low', 'uniform', 0; 'medium', 'uniform', 0; 'high', 'uniform', 0; 'medium', 'confusion_counts', 0; 'medium', 'uniform', 0.25; 'medium', 'uniform', 0.5};
names = {'low', 'medium', 'high', 'medium_BrnoMatrix_SENSITIVITY', 'medium_pgroup25_SENSITIVITY', 'medium_pgroup50_SENSITIVITY'};
if isempty(gcp('nocreate')), cl = parcluster('Processes');   cl.NumWorkers = 6;   parpool(cl, 6); end
Es = cell(6, 1);   FAs = cell(6, 1);   t0 = tic;
parfor k = 1:6
    [Es{k}, FAs{k}] = run_scenario(P, T, TP, lib, cases{k, 1}, minN, seed, cases{k, 2}, cases{k, 3});
end
fprintf('Monte Carlo done in %.0f s\n', toc(t0));
rows = table();
for k = 1:6
    E = Es{k};   FA = FAs{k};   save(fullfile(root, 'results', outn, ['run_' names{k} '.mat']), 'E', 'FA');
    M = compute_metrics(E, FA, T, P);   r = M.rows;   r.run_case = repmat(string(names{k}), height(r), 1);   r.label = repmat("SIMULATED", height(r), 1);
    r.classifier = repmat(string(cases{k, 2}), height(r), 1);   r.p_group = repmat(cases{k, 3}, height(r), 1);   r.intruder_events = repmat(M.intruders, height(r), 1);   r.days = repmat(FA.nDays, height(r), 1);   rows = [rows; r]; %#ok<AGROW>
    fprintf('%-32s %d days, %d events, %d persons\n', names{k}, FA.nDays, height(E), sum(E.group_size));
end
writetable(rows, fullfile(root, 'results', outn, 'metrics_summary.csv'));
% ---- re-identification inside the simulation (SIMULATED lookups): singles by the spacing to the nearest simultaneous intruder, groups by their size
G = readtable(fullfile(root, 'results', 'reid', 'reid_grid.csv'));   GG = readtable(fullfile(root, 'results', 'reid', 'group_events.csv'));
r = T.cells.ring;   arc = r.s(:);   grid = [50 20 10 5 2 1];   RE = table();
for k = 1:6
    E = Es{k};   n = height(E);   sp = inf(n, 1);   tr = 600;
    for d = 1:FAs{k}.nDays
        ii = find(E.day == d);   if numel(ii) < 2, continue; end
        for a = ii'
            o = ii(ii ~= a);   o = o(abs(E.t_start(o) - E.t_start(a)) < tr);
            if ~isempty(o), dd = abs(arc(E.piece(o)) - arc(E.piece(a)));   dd = min(dd, r.L - dd);   sp(a) = min(dd); end
        end
    end
    ver = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none");   src = repmat("drone_base", n, 1);   src(E.asset == "camera") = "fixed";
    w = E.group_size .* ver;   acc = nan(n, 1);   rate = nan(n, 1);   dec = nan(n, 1);   gacc = nan(n, 1);   wrong = nan(n, 1);
    for a = find(ver)'
        if E.group_size(a) > 1
            q = GG(GG.camera_source == src(a) & GG.group_size == E.group_size(a), :);   acc(a) = q.person_link_acc(1);   rate(a) = q.person_link_rate(1);   dec(a) = q.decision_rate(1);   gacc(a) = q.group_acc(1);   wrong(a) = q.wrong_links_per_100(1);
        else
            g = grid(find(grid <= sp(a), 1));   if isempty(g), g = 1; end
            q = G(G.camera_source == src(a) & G.spacing_m == g & G.pairs_share == 0 & G.position_error_m == 1 & G.clock_offset_s == 0.2 & string(G.crossing) == "False" & G.camera_dropout == 0, :);
            acc(a) = q.person_link_acc(1);   rate(a) = q.person_link_rate(1);   dec(a) = q.decision_rate(1);   gacc(a) = q.group_acc(1);   wrong(a) = q.wrong_links_per_100(1);
        end
    end
    wm = @(x, ww) sum(x(ww > 0) .* ww(ww > 0), 'omitnan') / sum(ww(ww > 0 & ~isnan(x)));
    wl = w .* rate;   % weight by the persons that get a person-level link when averaging the accuracy of the links made
    RE = [RE; table(string(names{k}), nnz(ver), sum(w), mean(E.group_size(ver) > 1), mean(sp(ver) < 50), wm(acc, wl), wm(rate, w), wm(dec, w), wm(gacc, w), wm(wrong, w), ...
        'VariableNames', {'run_case', 'verified_events', 'verified_persons', 'share_verified_events_group', 'share_single_with_neighbour_below_50m', 'person_link_accuracy_of_links_made', 'person_link_rate', 'decision_rate', 'group_level_accuracy', 'wrong_person_links_per_100_persons'})]; %#ok<AGROW>
end
RE.label = repmat("SIMULATED lookup (reid_grid.csv for singles, group_events.csv for groups; drone base 2.5 m, fixed camera 1 m when a camera verified)", height(RE), 1);
writetable(RE, fullfile(root, 'results', outn, 'reid_in_simulation.csv'));   disp(RE(:, 1:end-1));
