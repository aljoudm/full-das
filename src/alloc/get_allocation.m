function [alloc, cells, A] = get_allocation(P, scenario, varargin)
% GET_ALLOCATION  Optimized DAS / drone allocation for one scenario, from run_optimization (frozen) or from the saved result.
%
%   [alloc, cells, A] = get_allocation(P, 'medium')
%   [...] = get_allocation(P, 'high', 'Sites', 32, 'Force', true)
%
%   scenario  'low' | 'medium' | 'high' (3 / 6 / 12 drones, 5 / 15 / 30 patrols, ASSUMED, from P.assets.scenarios)
%   'Sites'   22 (default, real interdiction crossings) or 32 (adds 10 filler sites; sensitivity)
%   'Force'   true = solve again even if results/alloc_<scenario>_<sites>.mat exists
%   The MATLAB trial licence may expire, so every solved case is saved in results/ and loaded next time.
ip = inputParser;   addParameter(ip, 'Sites', 22);   addParameter(ip, 'Force', false);   parse(ip, varargin{:});   o = ip.Results;
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
f = fullfile(root, 'results', sprintf('alloc_%s_%d.mat', scenario, o.Sites));
P.assets.allow_filler = (o.Sites == 32);
sc = P.assets.scenarios(strcmp({P.assets.scenarios.name}, scenario));
assert(isscalar(sc), 'get_allocation:scenario', 'Unknown scenario %s', scenario);
cells = load_cells(P);   A = place_existing_assets(P, cells);
if isfile(f) && ~o.Force
    S = load(f);   alloc = S.alloc;   fprintf('get_allocation: loaded %s\n', f);   return;
end
M = coverage_model(P, cells, A);
alloc = run_optimization(cells, P, 'Scenario', sc, 'Assets', A, 'Model', M, 'ProgressSeconds', 600, 'Verbose', false);
alloc.params_file = char(P.tsvFile);   alloc.sites = o.Sites;   alloc.saved = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
if ~isfolder(fileparts(f)), mkdir(fileparts(f)); end
save(f, 'alloc');   fprintf('get_allocation: solved %s in %.0f s, saved %s\n', scenario, alloc.elapsed_s, f);
end
