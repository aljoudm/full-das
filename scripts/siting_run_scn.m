% SITING_RUN_SCN  One siting allocation per MATLAB session (env SC = low | medium | high, DSTAR km, TAG): uses the cached candidate set of the base thresholds (results/siting/candidates_base.mat,
% made by scripts/siting_n5_test.m), solves the MILP, saves results/alloc_<SC>_22_siting[_TAG].mat and the map / site table in results/siting/.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();   sc = getenv('SC');   tag = getenv('TAG');   ds = str2double(getenv('DSTAR'));
X = load(fullfile(root, 'results', 'siting', 'candidates_base.mat'));   [al, C] = get_allocation_siting(P, sc, 'DStarKm', ds, 'Cand', X.C, 'Tag', tag, 'Force', true);
T = load_twin(P);   nm = sc;   if ~isempty(tag), nm = [sc '_' tag]; end,   R = siting_report(P, T, al, C, nm);
fprintf('RESULT %s d* %.2f N %d C_total %.0f unserved runs %d max optical %.2f km arcs %s\n', nm, ds, al.n_interrogators, al.C_total, R.unserved_runs, R.max_optical_km, mat2str(sort(al.interrogators.arc_m(:)') / 1e3, 4));
