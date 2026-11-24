% STAGE9_COMPARE  Before / after the siting model: results/stage9 (4 interrogators, library lookup by the nearest of five distances) versus results/stage9_siting (6 sited interrogators with lead-in,
% unified Pd(d) model), same seed and common random numbers (the same events day by day). Writes results/stage9_siting/comparison.csv and comparison_by_distance.csv.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();   T = load_twin(P);   r = T.cells.ring;   L = r.L;
sc = {'low', 'medium', 'high'};   mets = {'Pd', 'Pd_x_Pc', 'verified_Tresp', 'verified_Tresp_hot', 'patrol_reached', 'median_verification_s'};   rows = table();   byd = table();   edges = [0 5 10 14.75 15 20 30]*1e3;
for k = 1:numel(sc)
    for v = 1:2
        dirn = {'stage9', 'stage9_siting'};   X = load(fullfile(root, 'results', dirn{v}, ['run_' sc{k} '.mat']));   E = X.E;   FA = X.FA;
        if v == 1, A = load(fullfile(root, 'results', ['alloc_' sc{k} '_22.mat'])); else, A = load(fullfile(root, 'results', ['alloc_' sc{k} '_22_siting.mat'])); end
        ia = A.alloc.interrogators;   lead = zeros(size(ia.arc_m(:)'));   if isfield(ia, 'leadin_m'), lead = ia.leadin_m(:)'; end
        sp = r.s(E.piece);   sp = sp(:);   d = abs(sp - ia.arc_m(:)');   d = min(d, L - d) + lead;   dist = min(d, [], 2);
        Ct = A.alloc.C_total;   if v == 1, Ct = Ct + A.alloc.n_interrogators * P.v.C_shelter; end      % C_total WITH shelters: the siting allocation includes them; the main allocation was solved with C_shelter = 0, so its 4 cabins (all new, 120,000 each) are added
        M = compute_metrics(E, FA, T, P);   m = M.rows;
        for q = 1:numel(mets), i = find(strcmp(m.metric, mets{q}), 1);   rows = [rows; table(string(sc{k}), string(dirn{v}), string(mets{q}), m.value(i), m.lo(i), m.hi(i), A.alloc.n_interrogators, Ct, FA.nDays, height(E), 'VariableNames', {'scenario', 'model', 'metric', 'value', 'lo', 'hi', 'n_interrogators', 'C_total', 'days', 'events'})]; end %#ok<AGROW>
        for b = 1:numel(edges) - 1
            mk = dist >= edges(b) & dist < edges(b+1);   if ~any(mk), continue; end
            byd = [byd; table(string(sc{k}), string(dirn{v}), edges(b)/1e3, edges(b+1)/1e3, nnz(mk), 100 * mean(~E.detected(mk)), 'VariableNames', {'scenario', 'model', 'from_km', 'to_km', 'events', 'missed_pct'})]; end %#ok<AGROW>
    end
end
od = fullfile(root, 'results', 'stage9_siting');   writetable(rows, fullfile(od, 'comparison.csv'));   writetable(byd, fullfile(od, 'comparison_by_distance.csv'));   disp(rows(rows.scenario == "medium", :));   disp(byd(byd.scenario == "medium", :));
