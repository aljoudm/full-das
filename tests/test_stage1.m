% TEST_STAGE1  Digital-twin loader: cell counts, lengths, lambda conservation, comparison with the DAS-map cells.csv, figure.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   c = T.cells;
fprintf('--- Stage 1 tests ---\n');
% 1) cells and zones (DAS-map README: 139 = 36 Hot / 56 Neutral / 47 Cold; 39.4 / 59.0 / 47.1 km; 145.5 km)
assert(c.n == 139 && sum(c.zoneCode == 3) == 36 && sum(c.zoneCode == 2) == 56 && sum(c.zoneCode == 1) == 47, 'zone counts');
Lz = arrayfun(@(k) sum(c.L_m(c.zoneCode == k)) / 1e3, [3 2 1]);
fprintf('cells %d (H/N/C %d/%d/%d); boundary km H/N/C = %.1f / %.1f / %.1f (README 39.4 / 59.0 / 47.1)\n', c.n, 36, 56, 47, Lz);
assert(all(abs(Lz - [39.4 59.0 47.1]) < 0.06), 'zone lengths');
assert(abs(sum(c.L_m) - 145461) < 5 && abs(c.ring.L - 145461.4) < 1, 'ring length');
% 2) lambda: zone sums equal the table ranges; Hot/Neutral equal the old cells.csv (same formula); Cold is not zero any more
zr = T.lambda.zone_range;   assert(isequal(zr, [1 2; 8 10; 11 20]), 'zone ranges %s', mat2str(zr));
old = readtable(fullfile(root, 'third_party', 'dasmap_data', 'cells.csv'));
for k = [2 3]
    in = c.zoneCode == k;   assert(max(abs(T.lambda.mid(in) - old.lambda_cell_mid(in))) < 1e-9, 'lambda differs from DAS-map for zone %d', k);
end
inC = c.zoneCode == 1;   assert(all(old.lambda_cell_mid(inC) == 0) && all(T.lambda.mid(inC) > 0), 'Cold lambda');
fprintf('lambda mid per day: Hot %.2f, Neutral %.2f, Cold %.2f (zone total); max cell Hot %.2f (README 0.91)\n', ...
    sum(T.lambda.mid(c.zoneCode == 3)), sum(T.lambda.mid(c.zoneCode == 2)), sum(T.lambda.mid(inC)), max(T.lambda.mid(c.zoneCode == 3)));
% 3) independent check: cell risk of the copy equals cells.csv
assert(max(abs(c.risk(:) - old.cell_risk_P90)) < 1e-9, 'risk differs');
% 4) terrain and roads loaded; boundary inside the DEM
assert(numel(T.roads) == 4549 && all(T.ring_ll(:,1) > min(T.dem.lat) & T.ring_ll(:,1) < max(T.dem.lat)), 'roads / dem');
fprintf('roads %d, DEM %dx%d, max slope %.0f deg\n', numel(T.roads), size(T.dem.Z), max(T.dem.slope_deg(:)));
% 5) figure
ax = draw_twin(T);   title(ax, 'Digital twin: boundary zones (Hot / Neutral / Cold), OSM roads, DEM hillshade');
exportgraphics(ancestor(ax, 'figure'), fullfile(root, 'results', 'figures', 'stage1_twin_map.png'), 'Resolution', 150);   close all;
fprintf('Stage 1: ALL PASSED\n');
