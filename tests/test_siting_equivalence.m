% TEST_SITING_EQUIVALENCE  The siting-branch MILP (third_party/optimization_siting, branch interrogator-siting) without the 'Siting' option must give EXACTLY the results of the
% frozen main version: C_total 11,373,506 SAR, 4 interrogators, Hot cells verified 9 / 22 / 34 (low / medium / high).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
oldp = fullfile(root, 'third_party', 'optimization', 'src');   newp = fullfile(root, 'third_party', 'optimization_siting', 'src');
rmpath(oldp);   addpath(newp);   cleanup = onCleanup(@() (rmpath(newp) + addpath(oldp)));
P = load_params_fd();   P.v.C_shelter = 0;   P.assets.allow_filler = false;   cells = load_cells(P);   A = place_existing_assets(P, cells);   M = coverage_model(P, cells, A);   exp = [9 22 34];
for k = 1:3
    sc = P.assets.scenarios(k);   al = run_optimization(cells, P, 'Scenario', sc, 'Assets', A, 'Model', M, 'Verbose', false);
    fprintf('%-6s C_total %.2f | interrogators %d | Hot verified %d | arcs %s\n', sc.name, al.C_total, al.n_interrogators, al.hot_verified, mat2str(sort(al.interrogators.arc_m(:)') / 1e3, 4));
    assert(abs(al.C_total - 11373506.17) < 1 && al.n_interrogators == 4 && al.hot_verified == exp(k), 'branch without siting differs from main');
end
fprintf('Siting-branch equivalence: ALL PASSED\n');
% note: P.v.C_shelter = 0 reproduces the frozen report numbers, which were computed WITHOUT a cabin cost (table row C_shelter was 0 until 24 Nov 2026)
