% TEST_STAGE2  Allocation through the FROZEN run_optimization with the full-das table. Must match the optimization report.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   P.v.C_shelter = 0;   fprintf('--- Stage 2 tests ---\n');
scen = {'low', 'medium', 'high'};   expHot = [9 22 34];   expDr = [3 6 12];
for k = 1:3
    [al, cells] = get_allocation(P, scen{k});
    fprintf('%-6s C_total %.0f | interrogators %d | fibre %.2f km | power %.0f W | drones %d at %d stations | Hot verified %d/36 | DAS cells %d | violations %d\n', ...
        scen{k}, al.C_total, al.n_interrogators, al.fibre_km, al.power.total_W, al.drones.total, al.drones.stations, al.hot_verified, al.cells_with_DAS, al.n_violations);
    assert(abs(al.C_total - 11373506.17) < 1, 'C_total');                       % key_results.md section 3
    assert(al.n_interrogators == 4, 'interrogators');
    assert(al.power.total_W == 1360, 'power');
    assert(al.hot_verified == expHot(k), 'Hot verified %d vs report %d', al.hot_verified, expHot(k));
    assert(al.drones.total == expDr(k), 'drones used');
    assert(al.cells_with_DAS == 139, 'DAS in all cells');
    assert(abs(al.fibre_km - 145.46) < 0.01, 'fibre km');
    assert(al.classifier_check.ok, 'classifier check');
end
% independent 2nd check: every Hot cell flagged verified has a station within R_resp (recomputed from station coordinates)
[al, cells] = get_allocation(P, 'medium');   r = cells.ring;
st = al.drones.station_xy;   ok = 0;
for i = find(cells.zoneCode(:)' == 3 & al.cells.verified(:)')
    m = r.cell(:) == i;   d = min(hypot(r.x(m) - st(:,1)', r.y(m) - st(:,2)'), [], 1);
    ok = ok + any(max(hypot(r.x(m) - st(:,1)', r.y(m) - st(:,2)'), [], 1) <= P.v.R_resp_m + 1);
end
fprintf('independent check: %d of %d verified Hot cells (medium) have a station reaching the whole cell within R_resp = %.0f m\n', ok, al.hot_verified, P.v.R_resp_m);
assert(ok >= al.hot_verified - 0, 'independent verification count');
fprintf('Stage 2: ALL PASSED\n');
% note: P.v.C_shelter = 0 reproduces the frozen report numbers, which were computed WITHOUT a cabin cost (table row C_shelter was 0 until 24 Nov 2026)
