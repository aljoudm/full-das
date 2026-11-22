function T = load_twin(P)
% LOAD_TWIN  The digital twin of the map: boundary cells, zones, roads, terrain, per-cell intrusion rates.
%
%   T = load_twin(P)      P from load_params_fd
%
% Fields
%   T.cells    struct from the frozen load_cells (139 cells, zone, length, risk, runs, ring)
%   T.lambda   per-cell intrusion rate [events/day]: .min .mid .max (n x 1) and .zone_range (3x2: Cold, Neutral, Hot)
%              Same rule as DAS-map zone_classify: zone lambda x (risk*length) / sum over the zone. Cold uses the table range (1-2),
%              not the 0 of the old cells.csv (decision 21 Nov 2026). All values ASSUMED (table rows lambda_*).
%   T.roads    struct array (class, lat, lon) from OSM (osm_contributors); T.ring_ll = [lat lon] of the 5 m boundary pieces
%   T.dem      Z, lat, lon (Copernicus GLO-30 DSM crop) and slope_deg on the same grid (T.dem.slope_deg)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
c = load_cells(P);   T.cells = c;   n = c.n;
% --- per-cell lambda from the table ranges (strings like "11-20")
zr = zeros(3, 2);   names = {'lambda_cold', 'lambda_neutral', 'lambda_hot'};
for k = 1:3
    v = P.raw(strcmp({P.raw.sym}, names{k})).value;
    t = sscanf(char(v), '%f-%f');   assert(numel(t) == 2, 'load_twin:lambda', 'Cannot read range of %s: %s', names{k}, v);
    zr(k, :) = t(:)';
end
w = c.risk(:) .* c.L_m(:);   lam = zeros(n, 3);   % columns min, mid, max
for k = 1:3
    in = c.zoneCode(:) == k;
    share = w(in) / sum(w(in));
    rng3 = [zr(k, 1), mean(zr(k, :)), zr(k, 2)];
    lam(in, :) = share * rng3;
    assert(all(abs(sum(lam(in, :), 1) - rng3) < 1e-9), 'load_twin:lambdasum', 'Zone lambda is not conserved');
end
T.lambda = struct('min', lam(:, 1), 'mid', lam(:, 2), 'max', lam(:, 3), 'zone_range', zr);
% --- roads
R = load(fullfile(root, 'third_party', 'dasmap_data', 'roads_osm.mat'));   T.roads = R.roads;
% --- boundary pieces in lat/lon
r = c.ring;   T.ring_ll = [r.lat0 + r.y(:) / r.ky, r.lon0 + r.x(:) / r.kx];
% --- terrain
D = load(fullfile(root, 'data', 'dem', 'dem_aoi.mat'));
kyd = 111195;   kxd = 111195 * cosd(mean(D.lat));
[gx, gy] = gradient(double(D.Z), mean(diff(D.lon(:))) * kxd, mean(diff(D.lat(:))) * kyd);   % lat ascends with row index
T.dem = struct('Z', D.Z, 'lat', D.lat(:), 'lon', D.lon(:), 'slope_deg', atand(hypot(gx, gy)));
end
