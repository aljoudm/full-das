function C = make_candidates(T, P, A, varargin)
% MAKE_CANDIDATES  Candidate shelter sites for the DAS interrogators, from OSM roads, the DEM and OSM waterways.
%
%   C = make_candidates(T, P, A)                         T twin (load_twin), P load_params_fd, A existing assets (checkpoints)
%   C = make_candidates(T, P, A, 'Slope', 0.10, 'RoadM', 200, 'WaterM', 50)      sensitivity runs
%   Rules (all thresholds are table rows, ASSUMED): INSIDE the protected area, siting_inside_min_m (50 m) to siting_inside_max_m (200 m) from the boundary line (checkpoints, on the line, are the only exception); within siting_road_m (200 m) of a road for access and maintenance (OSM paved roads motorway..tertiary and unclassified roads);
%   ground slope below siting_slope_pct (10 % = 5.7 deg) on the 30 m DEM (not on a mountain); not within siting_water_m (50 m) of an OSM waterway (not in a wadi channel);
%   within siting_search_km (3 km) of the boundary so that the lead-in fibre stays short; the 5 entrance checkpoints are ALWAYS candidates (guarded, powered and air-conditioned
%   already), whatever the filters say, and are marked kind = 'checkpoint' (preferred in the third objective of the MILP).
%   Candidates are the points of a 100 m grid in the corridor that pass the rules; one candidate (the closest to the boundary) is kept per 300 m of boundary arc.
%   Output struct array C: lat, lon, x, y (local m), kind ('road'|'checkpoint'), arc_m (arc position of the nearest boundary point), leadin_m (route length of the lead-in fibre
%   from the shelter to the boundary = siting_leadin_factor x straight distance), road_m, slope_pct, water_m, run (index of the boundary run that contains arc_m), name.
ip = inputParser;   addParameter(ip, 'Slope', P.fd.siting_slope_pct / 100);   addParameter(ip, 'RoadM', P.fd.siting_road_m);   addParameter(ip, 'WaterM', P.fd.siting_water_m);
addParameter(ip, 'SearchKm', P.fd.siting_inside_max_m / 1e3);   addParameter(ip, 'InsideMin', P.fd.siting_inside_min_m);   addParameter(ip, 'InsideMax', P.fd.siting_inside_max_m);   addParameter(ip, 'Step', 50);   parse(ip, varargin{:});   o = ip.Results;
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));   r = T.cells.ring;   D = T.dem;
ll2xy = @(lat, lon) deal((lon(:) - r.lon0) * r.kx, (lat(:) - r.lat0) * r.ky);
% ---- road points (paved + unclassified), densified to 25 m: used to measure the distance of a candidate to a road
rx = zeros(0, 1);   ry = zeros(0, 1);
for i = 1:numel(T.roads)
    [gx, gy] = ll2xy(T.roads(i).lat, T.roads(i).lon);   [qx, qy] = densify(gx, gy, 25);   rx = [rx; qx]; ry = [ry; qy]; %#ok<AGROW>
end
J = jsondecode(fileread(fullfile(root, 'data', 'osm', 'osm_tracks_unclassified_2026-11-22.json'), 'Encoding', 'UTF-8'));
for i = 1:numel(J.elements)
    if ~strcmp(J.elements(i).tags.highway, 'unclassified'), continue; end                    % tracks (dirt) are not used for the access road
    g = J.elements(i).geometry;   if numel(g) < 2, continue; end
    [gx, gy] = ll2xy([g.lat], [g.lon]);   [qx, qy] = densify(gx, gy, 25);   rx = [rx; qx]; ry = [ry; qy]; %#ok<AGROW>
end
% ---- candidate grid (o.Step m) over the corridor around the boundary, kept if within SearchKm of the boundary and within RoadM of a road
[GX, GY] = meshgrid(min(r.x) - o.SearchKm * 1e3 : o.Step : max(r.x) + o.SearchKm * 1e3, min(r.y) - o.SearchKm * 1e3 : o.Step : max(r.y) + o.SearchKm * 1e3);   px = GX(:);   py = GY(:);
[kb, dB] = knnsearch([r.x(:) r.y(:)], [px py]);   in = inpolygon(px, py, r.x(:), r.y(:));   keep = dB <= o.InsideMax & dB >= o.InsideMin & in;   px = px(keep);   py = py(keep);   kb = kb(keep);   dB = dB(keep);   % INSIDE the boundary (protected side), InsideMin..InsideMax m from the line
[~, dRoad] = knnsearch([rx ry], [px py]);   keep = dRoad <= o.RoadM;   px = px(keep);   py = py(keep);   kb = kb(keep);   dB = dB(keep);   dRoad = dRoad(keep);
% ---- slope on the DEM
lat = r.lat0 + py / r.ky;   lon = r.lon0 + px / r.kx;
Fs = griddedInterpolant({D.lat, D.lon}, double(D.slope_deg), 'linear', 'nearest');   slopePct = 100 * tand(Fs(lat, lon));
% ---- distance to the nearest road (by construction ~0 for these points) and to the nearest waterway
wf = dir(fullfile(root, 'data', 'osm', 'osm_waterways_*.json'));   wx = zeros(0, 1);   wy = zeros(0, 1);
if ~isempty(wf)
    W = jsondecode(fileread(fullfile(wf(end).folder, wf(end).name), 'Encoding', 'UTF-8'));
    for i = 1:numel(W.elements)
        g = W.elements(i).geometry;   if numel(g) < 2, continue; end
        [gx, gy] = ll2xy([g.lat], [g.lon]);   [qx, qy] = densify(gx, gy, 20);   wx = [wx; qx]; wy = [wy; qy]; %#ok<AGROW>
    end
    if isempty(wx), waterM = inf(numel(px), 1); else, [~, waterM] = knnsearch([wx wy], [px py]); end
else, waterM = nan(numel(px), 1);   warning('make_candidates:water', 'No waterway file: the waterway filter is NOT applied.');
end
ok = slopePct < 100 * o.Slope & (isnan(waterM) | waterM >= o.WaterM);
px = px(ok);   py = py(ok);   kb = kb(ok);   dB = dB(ok);   slopePct = slopePct(ok);   waterM = waterM(ok);   dRoad = dRoad(ok);
% ---- thin to one candidate per 300 m cell of the boundary arc (keeps the MILP small): the one closest to the boundary in each 300 m arc bin
arc = r.s(kb);   bin = floor(arc / 300);   [~, ordr] = sort(dB);   [~, ia] = unique(bin(ordr), 'stable');   sel = sort(ordr(ia));
px = px(sel);   py = py(sel);   kb = kb(sel);   dB = dB(sel);   slopePct = slopePct(sel);   waterM = waterM(sel);   dRoad = dRoad(sel);
n = numel(px);   kind = repmat("road", n, 1);   name = repmat("road site", n, 1);
% ---- the checkpoints: always candidates
cs = A.sites([A.sites.in]);   cp = cs(string({cs.kind}) == "checkpoint");
for i = 1:numel(cp)
    [k, d] = knnsearch([r.x(:) r.y(:)], [cp(i).x cp(i).y]);   Fsl = 100 * tand(Fs(r.lat0 + cp(i).y / r.ky, r.lon0 + cp(i).x / r.kx));
    px(end+1, 1) = cp(i).x;   py(end+1, 1) = cp(i).y;   kb(end+1, 1) = k;   dB(end+1, 1) = d;   dRoad(end+1, 1) = 0;   slopePct(end+1, 1) = Fsl;   waterM(end+1, 1) = NaN;   kind(end+1, 1) = "checkpoint";   name(end+1, 1) = string(cp(i).name); %#ok<AGROW>
end
n = numel(px);   arcm = r.s(kb);   lead = P.fd.siting_leadin_factor * dB;
runIdx = zeros(n, 1);   for i = 1:n, runIdx(i) = find(arcm(i) >= T.cells.runs.s0 & arcm(i) <= T.cells.runs.s1, 1);   if isempty(runIdx(i)) || runIdx(i) == 0, [~, runIdx(i)] = min(abs((T.cells.runs.s0 + T.cells.runs.s1) / 2 - arcm(i))); end, end
C = struct('lat', num2cell(r.lat0 + py / r.ky), 'lon', num2cell(r.lon0 + px / r.kx), 'x', num2cell(px), 'y', num2cell(py), 'kind', cellstr(kind), 'arc_m', num2cell(arcm), 'leadin_m', num2cell(lead), ...
    'road_m', num2cell(dRoad), 'slope_pct', num2cell(slopePct), 'water_m', num2cell(waterM), 'run', num2cell(runIdx), 'name', cellstr(name));
end

function [qx, qy] = densify(x, y, step)
x = x(:); y = y(:);   qx = x(1);   qy = y(1);
for k = 1:numel(x) - 1
    m = max(ceil(hypot(x(k+1) - x(k), y(k+1) - y(k)) / step), 1);   t = (1:m)' / m;
    qx = [qx; x(k) + t * (x(k+1) - x(k))]; qy = [qy; y(k) + t * (y(k+1) - y(k))]; %#ok<AGROW>
end
end
