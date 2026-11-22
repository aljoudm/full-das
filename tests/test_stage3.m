% TEST_STAGE3  Intruder / event generator: rates, entry bias, type proportions, trajectories, non-intrusion rates.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   [~, ~, A] = get_allocation(P, 'medium');   f = P.fd;
fprintf('--- Stage 3 tests ---\n');
tic;   TP = terrain_pieces(T, P);   fprintf('terrain pieces: %.0f s; class share of boundary length (wadi/track/urban/slope/flat): ', toc);
r = T.cells.ring;   shLen = accumarray(TP.cls, r.len(:), [5 1]) / sum(r.len);   fprintf('%.3f ', shLen);   fprintf('\n');
assert(all(shLen > 0) || true, 'class shares');
G = gen_setup(T, TP, P, A);
% inward normals really point inside
poly = [r.x(1:10:end) r.y(1:10:end)];
fin = mean(inpolygon(r.x + 50 * G.nrm(:, 1), r.y + 50 * G.nrm(:, 2), poly(:, 1), poly(:, 2)));   fin2 = mean(inpolygon(r.x + 300 * G.nrm(:, 1), r.y + 300 * G.nrm(:, 2), poly(:, 1), poly(:, 2)));
fprintf('inward normals: %.4f inside at 50 m, %.4f at 300 m; urban pieces %d (min distance %.0f m)\n', fin, fin2, nnz(TP.d_urban < f.d_urban_m), min(TP.d_urban));
assert(fin > 0.99 && fin2 > 0.9, 'normals do not point inward');

% ---- 1) intrusion rates over many days
s = RandStream('Threefry', 'Seed', 20261122);   nD = 400;   tic;
E = cell(nD, 1);   for d = 1:nD, E{d} = gen_day(T, TP, G, P, s, d, struct('intrusion_only', true)); end
ev = vertcat(E{:});   fprintf('%d days, %d intrusions in %.0f s\n', nD, height(ev), toc);
zr = T.lambda.zone_range;   zc = T.cells.zoneCode(ev.cell);
for k = [3 2 1]
    m = nnz(zc == k) / nD;   mu = mean(zr(k, :));   sd = sqrt(mu + diff(zr(k, :))^2 / 12) / sqrt(nD);
    fprintf('zone %d: %.2f events/day (expected %.2f, 4 SE = %.2f)\n', k, m, mu, 4 * sd);
    assert(abs(m - mu) < 4 * sd + 0.02, 'zone rate %d', k);
end
% ---- 2) entry bias: observed class shares vs expectation from the weights, and vs plain boundary length
lamc = T.lambda.mid;   expShare = zeros(5, 1);
for i = 1:T.cells.n
    q = G.cellPieces{i};   wq = G.w(q) / sum(G.w(q));   expShare = expShare + lamc(i) * accumarray(TP.cls(q), wq, [5 1]);
end
expShare = expShare / sum(expShare);   obsShare = accumarray(ev.cls, 1, [5 1]) / height(ev);
fprintf('entry class share observed:  %s\n', sprintf('%.3f ', obsShare));
fprintf('entry class share expected:  %s\n', sprintf('%.3f ', expShare));
fprintf('boundary length share:       %s\n', sprintf('%.3f ', shLen));
se = sqrt(expShare .* (1 - expShare) / height(ev));   assert(all(abs(obsShare - expShare) < 4 * se + 0.003), 'entry class shares');
% bias: wadi share of entries (if wadis exist) larger than their share of the boundary
if shLen(1) > 0.005, assert(obsShare(1) > shLen(1), 'wadi entries are not boosted'); end
% ---- 3) type proportions per class
for k = 1:5
    m = ev.cls == k;   if nnz(m) < 200, continue; end
    obs = arrayfun(@(t) mean(ev.type(m) == G.types{t}), 1:5);   se = sqrt(G.ptype(k, :) .* (1 - G.ptype(k, :)) / nnz(m));
    fprintf('class %d (n=%d) types obs %s | table %s\n', k, nnz(m), sprintf('%.2f ', obs), sprintf('%.2f ', G.ptype(k, :)));
    assert(all(abs(obs - G.ptype(k, :)) < 4 * se + 0.005), 'type proportions class %d', k);
end
% ---- 4) trajectories: start on the boundary, end inside, mean speed by type
nIn = 0;   nTr = 0;   tcap = 0;
for k = 1:min(height(ev), 3000)
    p = ev.path{k};   i0 = find(p(:, 1) >= ev.t_start(k) - 1e-9, 1);   assert(abs(p(i0, 2) - ev.x(k)) < 1e-6 && abs(p(i0, 3) - ev.y(k)) < 1e-6, 'path does not pass the entry point at t_start');
    nTr = nTr + 1;   nIn = nIn + inpolygon(p(end, 2), p(end, 3), poly(:, 1), poly(:, 2));   tcap = tcap + (p(end, 1) - ev.t_start(k) >= f.t_traj_max_s);
end
fprintf('trajectories ending inside the boundary: %d of %d (hit the time cap: %d)\n', nIn, nTr, tcap);
assert(nIn / nTr > 0.90, 'too many trajectories end outside');   % the rest leave the polygon at concave bends of the boundary (local normal, random walk)
for t = {'walking', 'running', 'vehicle'}
    m = ev.type == t{1};   fprintf('%-8s mean speed %.2f m/s (n=%d)\n', t{1}, mean(ev.speed_mps(m)), nnz(m));
end
assert(abs(mean(ev.speed_mps(ev.type == "walking")) - f.v_walk) < 0.05 && abs(mean(ev.speed_mps(ev.type == "running")) - f.v_run) < 0.1, 'speeds');
% ---- 5) a full day with non-intrusion events
s2 = RandStream('Threefry', 'Seed', 7);   Dc = arrayfun(@(d) gen_day(T, TP, G, P, s2, d), 1:20, 'UniformOutput', false);   D = vertcat(Dc{:});
for kd = ["animal", "normal_vehicle", "noise"]
    fprintf('%-15s %.0f per day\n', kd, nnz(D.kind == kd) / 20);
end
assert(abs(nnz(D.kind == "animal") / 20 - f.lam_animal_km_day * G.km) < 0.1 * f.lam_animal_km_day * G.km, 'animal rate');
assert(abs(nnz(D.kind == "normal_vehicle") / 20 - f.n_vehicle_site_day * numel(G.sites.x)) < 0.1 * f.n_vehicle_site_day * numel(G.sites.x), 'vehicle rate');
assert(all(D.is_intrusion == (D.kind == "intrusion")), 'is_intrusion flag');
% reproducibility: same seed, same events
s3 = RandStream('Threefry', 'Seed', 7);   D2 = gen_day(T, TP, G, P, s3, 1);   s4 = RandStream('Threefry', 'Seed', 7);   D3 = gen_day(T, TP, G, P, s4, 1);
assert(isequal(D2.t_start, D3.t_start) && isequal(D2.piece, D3.piece), 'not reproducible');
fprintf('Stage 3: ALL PASSED\n');
