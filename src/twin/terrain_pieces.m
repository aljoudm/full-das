function TP = terrain_pieces(T, P)
% TERRAIN_PIECES  Terrain attributes of every 5 m boundary piece, used by the intruder model (entry weights, type proportions).
%
%   TP = terrain_pieces(T, P)       cached in results/cache_terrain_pieces.mat (delete the file to recompute)
%
%   TP.slope_deg  slope at the piece (Copernicus DSM)             TP.wadi   wadi proxy (DEM: lower than the local mean, gentle floor)
%   TP.d_track    distance to an OSM track / unclassified road [m] TP.d_urban distance to the centre of an OSM urban area / place [m]
%   TP.d_road     distance to the nearest OSM paved road [m]       TP.cls    class 1 wadi, 2 track, 3 urban, 4 slope, 5 flat (priority order)
%   All thresholds are table rows (value_type assumption / proxy).
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
cf = fullfile(root, 'results', 'cache_terrain_pieces.mat');
if isfile(cf), S = load(cf); if S.TP.n == numel(T.cells.ring.x), TP = S.TP; return; end, end
r = T.cells.ring;   D = T.dem;   f = P.fd;   n = numel(r.x);
ll2xy = @(lat, lon) deal((lon(:) - r.lon0) * r.kx, (lat(:) - r.lat0) * r.ky);
% --- DEM: slope and wadi proxy sampled at the pieces
Fs = griddedInterpolant({D.lat, D.lon}, double(D.slope_deg), 'linear', 'nearest');
Zs = imgaussfilt(double(D.Z), 300 / 30);                                  % sigma = 300 m on the 30 m grid
wad = (double(D.Z) - Zs < -f.wadi_depth_m) & (D.slope_deg < f.wadi_slope_max_deg);
Fw = griddedInterpolant({D.lat, D.lon}, double(wad), 'nearest', 'nearest');
TP.slope_deg = Fs(T.ring_ll(:, 1), T.ring_ll(:, 2));   TP.wadi = Fw(T.ring_ll(:, 1), T.ring_ll(:, 2)) > 0.5;
% --- OSM tracks / unclassified (densified to ~20 m) and urban centres
J = jsondecode(fileread(fullfile(root, 'data', 'osm', 'osm_tracks_unclassified_2026-11-22.json'), 'Encoding', 'UTF-8'));
px = zeros(0, 1);   py = zeros(0, 1);
for i = 1:numel(J.elements)
    g = J.elements(i).geometry;   if numel(g) < 2, continue; end
    [gx, gy] = ll2xy([g.lat], [g.lon]);   [qx, qy] = densify(gx, gy, 20);   px = [px; qx]; py = [py; qy]; %#ok<AGROW>
end
TP.d_track = nn_dist(px, py, r.x, r.y);
U = jsondecode(fileread(fullfile(root, 'data', 'osm', 'osm_urban_landuse_place_2026-11-22.json'), 'Encoding', 'UTF-8'));
ulat = zeros(0, 1);   ulon = zeros(0, 1);
for i = 1:numel(U.elements)
    if iscell(U.elements), e = U.elements{i}; else, e = U.elements(i); end   % jsondecode gives a cell array for mixed node / way records
    if isfield(e, 'center') && ~isempty(e.center), ulat(end+1) = e.center.lat; ulon(end+1) = e.center.lon; %#ok<AGROW>
    elseif isfield(e, 'lat'), ulat(end+1) = e.lat; ulon(end+1) = e.lon; end %#ok<AGROW>
end
[ux, uy] = ll2xy(ulat, ulon);   TP.d_urban = nn_dist(ux, uy, r.x, r.y);
% --- paved roads
rx = zeros(0, 1);   ry = zeros(0, 1);
for i = 1:numel(T.roads)
    [gx, gy] = ll2xy(T.roads(i).lat, T.roads(i).lon);   [qx, qy] = densify(gx, gy, 10);   rx = [rx; qx]; ry = [ry; qy]; %#ok<AGROW>
end
TP.d_road = nn_dist(rx, ry, r.x, r.y);
% --- class (priority wadi > track > urban > steep slope > flat)
cls = 5 * ones(n, 1);   cls(TP.slope_deg > f.slope_steep_deg) = 4;   cls(TP.d_urban < f.d_urban_m) = 3;
cls(TP.d_track < f.d_track_m) = 2;   cls(TP.wadi) = 1;   TP.cls = cls;   TP.n = n;
TP.class_names = {'wadi', 'track', 'urban', 'slope', 'flat'};
if ~isfolder(fileparts(cf)), mkdir(fileparts(cf)); end
save(cf, 'TP');
end

function [qx, qy] = densify(x, y, step)
x = x(:); y = y(:);   qx = x(1);   qy = y(1);
for k = 1:numel(x) - 1
    m = max(ceil(hypot(x(k+1) - x(k), y(k+1) - y(k)) / step), 1);   t = (1:m)' / m;
    qx = [qx; x(k) + t * (x(k+1) - x(k))]; qy = [qy; y(k) + t * (y(k+1) - y(k))]; %#ok<AGROW>
end
end

function d = nn_dist(px, py, x, y)
if isempty(px), d = inf(numel(x), 1); return; end
[~, d] = knnsearch([px py], [x(:) y(:)]);
end
