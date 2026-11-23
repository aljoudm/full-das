function [alloc, C, S] = get_allocation_siting(P, scenario, varargin)
% GET_ALLOCATION_SITING  Optimized DAS / drone allocation with the INTERROGATOR SITING model (branch interrogator-siting of the optimization repo, frozen copy third_party/optimization_siting).
%
%   [alloc, C, S] = get_allocation_siting(P, 'medium')
%   [...] = get_allocation_siting(P, 'medium', 'DStarKm', 14, 'Tag', 'slope15', 'Slope', 0.15, 'Force', true)
%
%   d* (km)  effective range of a channel from results/siting/d_star.json (Pd(d) >= Pd_DAS) unless 'DStarKm' is given; the channel reach of a shelter is d* - lead-in fibre of that shelter.
%   Candidates: make_candidates (roads, slope, waterways, checkpoints); C is the candidate struct array. N_min = ceil(L_boundary / (2 d*)); the MILP asserts N >= N_min.
%   Objectives (lexicographic): violations, shortfall, C_total (interrogator + shelter + sensing fibre + LEAD-IN fibre), then the sum over runs of (expected intruders x optical distance),
%   then as many interrogators as possible at the checkpoints, then A_ver of the Hot cells. Saved in results/alloc_<scenario>_22_siting[_<tag>].mat (the solver licence is a trial).
ip = inputParser;   addParameter(ip, 'DStarKm', []);   addParameter(ip, 'Tag', '');   addParameter(ip, 'Force', false);   addParameter(ip, 'Slope', []);   addParameter(ip, 'RoadM', []);   addParameter(ip, 'WaterM', []);
parse(ip, varargin{:});   o = ip.Results;
root = fileparts(fileparts(fileparts(mfilename('fullpath')))); tag = o.Tag;   if ~isempty(tag), tag = ['_' tag]; end
f = fullfile(root, 'results', sprintf('alloc_%s_22_siting%s.mat', scenario, tag));
T = load_twin(P);   [~, ~, A] = get_allocation(P, scenario);
cargs = {};   if ~isempty(o.Slope), cargs = [cargs {'Slope', o.Slope}]; end,   if ~isempty(o.RoadM), cargs = [cargs {'RoadM', o.RoadM}]; end,   if ~isempty(o.WaterM), cargs = [cargs {'WaterM', o.WaterM}]; end
C = make_candidates(T, P, A, cargs{:});
if isempty(o.DStarKm), J = jsondecode(fileread(fullfile(root, 'results', 'siting', 'd_star.json')));   dstar = J.d_star_km; else, dstar = o.DStarKm; end
Nmin = ceil(P.v.L_boundary_m / 1e3 / (2 * dstar));
c = T.cells;   runLam = zeros(numel(c.runs.cell), 1);                       % expected intruders per day on every run: cell rate (Cold 1-2, Neutral 8-10, Hot 11-20 per zone, spread by risk x length) x share of the cell length on the run
for r = 1:numel(runLam), runLam(r) = T.lambda.mid(c.runs.cell(r)) * c.runs.len(r) / c.L_m(c.runs.cell(r)); end
S = struct('cand', C, 'dstar_m', dstar * 1e3, 'Nmin', Nmin, 'RunWeights', runLam);
if isfile(f) && ~o.Force, X = load(f);   alloc = X.alloc;   fprintf('get_allocation_siting: loaded %s\n', f);   return; end
oldp = fullfile(root, 'third_party', 'optimization', 'src');   newp = fullfile(root, 'third_party', 'optimization_siting', 'src');
rmpath(oldp);   addpath(newp);   cleanup = onCleanup(@() swap_path(newp, oldp));
P2 = P;   P2.assets.allow_filler = false;   cells = load_cells(P2);   A2 = place_existing_assets(P2, cells);   M = coverage_model(P2, cells, A2);
sc = P2.assets.scenarios(strcmp({P2.assets.scenarios.name}, scenario));
alloc = run_optimization(cells, P2, 'Scenario', sc, 'Assets', A2, 'Model', M, 'Siting', S, 'Verbose', false, 'ProgressSeconds', 600);
alloc.siting.candidates = numel(C);   alloc.siting.dstar_km = dstar;   alloc.saved = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
save(f, 'alloc');   fprintf('get_allocation_siting: solved %s in %.0f s (d* %.0f km, N_min %d, N %d, C_total %.0f), saved %s\n', scenario, alloc.elapsed_s, dstar, Nmin, alloc.n_interrogators, alloc.C_total, f);
end

function swap_path(a, b)
rmpath(a);   addpath(b);
end
