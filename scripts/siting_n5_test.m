% SITING_N5_TEST  Why does the MILP choose N = 6 although N_min = ceil(L / (2 d*)) = 5 (d* = 14.75 km)?  Three tests, one MATLAB session:
%  (A) IDEAL sites (any arc position, lead-in 0, whole-run reach d*): can 5 sites cover the whole boundary?  (analytic bound: reach 14.75 km >= L / 10 = 14.55 km, so yes in principle)
%  (B) the REAL candidate sites (road + checkpoint, lead-in = route factor x distance, reach d* - lead-in): minimum number of sites and the best 5-site cover, with the uncovered boundary stretches;
%  (C) the full MILP with N = 5 forced (Siting.Nfix), same objectives: infeasible or more expensive?
% A run (about 1 km of fibre) is covered by a site if BOTH ends of the run are within d* optical distance (lead-in + arc distance along the ring).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();   T = load_twin(P);   [~, ~, A] = get_allocation(P, 'medium');
J = jsondecode(fileread(fullfile(root, 'results', 'siting', 'd_star.json')));   ds = J.d_star_km * 1e3;   r = T.cells.ring;   L = r.L;   runs = T.cells.runs;   s0 = runs.s0(:);   s1 = runs.s1(:);   len = runs.len(:);   nR = numel(s0);
arcd = @(a, b) min(abs(a - b), L - abs(a - b));
C = make_candidates(T, P, A);   save(fullfile(root, 'results', 'siting', 'candidates_base.mat'), 'C');   pos = [C.arc_m]';   lead = [C.leadin_m]';
cover = @(pos, lead) (max(arcd(pos', s0), arcd(pos', s1)) + lead' <= ds);          % nR x nC logical
out = struct();
% ---- (A) ideal sites every 100 m, no lead-in
posI = (0:100:L)';   CI = cover(posI, zeros(size(posI)));   [nI, ~] = mincover(CI);   out.ideal_min_sites = nI;
% ---- (B) real candidates
CB = cover(pos, lead);   [nB, ~] = mincover(CB);   out.real_min_sites = nB;
% best 5-site cover (maximise covered fibre length)
nC = numel(pos);   f = [zeros(nC, 1); -len];   Aineq = [-CB, eye(nR)];   bineq = zeros(nR, 1);   Aeq = [ones(1, nC), zeros(1, nR)];   x = intlinprog(f, 1:(nC + nR), Aineq, bineq, Aeq, 5, zeros(nC + nR, 1), ones(nC + nR, 1), optimoptions('intlinprog', 'Display', 'off'));
y = x(1:nC) > 0.5;   z = x(nC+1:end) > 0.5;   out.best5_uncovered_km = sum(len(~z)) / 1e3;   out.best5_sites = {C(y).name};   out.best5_arcs_km = pos(y)' / 1e3;
unc = find(~z);   out.uncovered_runs_arc_km = [s0(unc) s1(unc)] / 1e3;
% for every uncovered run: the best a candidate could do (the distance by which the nearest candidate misses the run)
miss = zeros(numel(unc), 1);   for q = 1:numel(unc), mm = max(arcd(pos', s0(unc(q))), arcd(pos', s1(unc(q)))) + lead' - ds;   miss(q) = min(mm); end,   out.uncovered_min_excess_km = miss' / 1e3;
fprintf('(A) ideal sites: minimum %d | (B) real candidates: minimum %d sites; best 5 leave %.2f km uncovered\n', nI, nB, out.best5_uncovered_km);
if ~isempty(unc), fprintf('    uncovered stretches (arc km):\n'); disp(out.uncovered_runs_arc_km); fprintf('    each exceeds the reach of the nearest allowed site by (km):\n'); disp(out.uncovered_min_excess_km); end
% ---- (C) full MILP with N = 5
out.milp_N5 = 'not run';
try
    al = get_allocation_siting(P, 'medium', 'Cand', C, 'Nfix', 5, 'Tag', 'N5', 'Force', true);   out.milp_N5 = sprintf('feasible: N %d, C_total %.0f', al.n_interrogators, al.C_total);
catch ME
    out.milp_N5 = ['infeasible or failed: ' strtrim(ME.message)];
end
disp(out.milp_N5);   fid = fopen(fullfile(root, 'results', 'siting', 'n5_test.json'), 'w');   fprintf(fid, '%s', jsonencode(out, 'PrettyPrint', true));   fclose(fid);

function [n, y] = mincover(Cv)
[nR, nC] = size(Cv);   x = intlinprog([ones(nC, 1)], 1:nC, -Cv, -ones(nR, 1), [], [], zeros(nC, 1), ones(nC, 1), optimoptions('intlinprog', 'Display', 'off'));
if isempty(x), n = Inf;  y = false(nC, 1); else, y = x > 0.5;  n = nnz(y); end
end
