function H = draw_twin3d(T, P, alloc, A, E, cam, varargin)
% DRAW_TWIN3D  3D digital twin in the style of DAS-map (aljoudm/DAS-map-, main_static.m): Esri World Imagery draped on the Copernicus DEM GLO-30, vertical exaggeration 2, perspective camera.
%
%   H = draw_twin3d(T, P, alloc, A, E, cam)                    T twin (load_twin), alloc/A (get_allocation), E = intruder table of a run or [], cam = twin3d_camera(...)
%   Options: 'Size' [w h] cm (default [16 10.5]); 'Legend' 'side' (legend panel to the right of the map, default) | 'none'; 'Crop' true (terrain cut to the boundary box + 2 km, default for
%   the overview); 'MeshExtent' / 'ImageExtent' [lon0 lon1 lat0 lat1] (zoom views); 'Imagery' file; 'Stride' mesh decimation; 'ZoomExtent' count only intruders inside; 'MaxIntruders' shown;
%   'Landmarks', 'Names' true/false; 'Fig' existing figure; 'BG' background colour of the frame (default dark grey: no white margins).
%   Layers: terrain + imagery; fibre along the boundary coloured by zone (Cold blue, Neutral amber, Hot red; lifted above a ridge-dilated mesh); DAS interrogators in their shelters,
%   drone stations (number of drones, altitude NOT to scale), existing camera sites and the named entrance checkpoints; intruders (green = detected and verified within T_resp, orange =
%   detected but not verified in time, magenta x = missed by the DAS). Overlay: legend panel, scale bar, north arrow, attribution.
ip = inputParser;   addParameter(ip, 'Imagery', '');   addParameter(ip, 'Landmarks', true);   addParameter(ip, 'Names', true);   addParameter(ip, 'Fig', []);   addParameter(ip, 'Size', [16 9]);
addParameter(ip, 'ZoomExtent', []);   addParameter(ip, 'MaxIntruders', 350);   addParameter(ip, 'MeshExtent', []);   addParameter(ip, 'ImageExtent', [39.5788 40.0622 21.2625 21.5831]);   addParameter(ip, 'Stride', 2);
addParameter(ip, 'Legend', 'side');   addParameter(ip, 'LegendPos', 'tl');   addParameter(ip, 'Crop', true);   addParameter(ip, 'BG', []);   addParameter(ip, 'Theme', 'light');   addParameter(ip, 'Sun', [300 28]);   parse(ip, varargin{:});   o = ip.Results;
dark = strcmp(o.Theme, 'dark');   if isempty(o.BG), if dark, o.BG = [0 0 0]; else, o.BG = [1 1 1]; end, end,   tc = 'k';   if dark, tc = 'w'; end                       % 'light' = white background for the report, 'dark' = black background for the presentation
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));   D = T.dem;   r = T.cells.ring;   VE = cam.VE;
if isempty(o.Imagery), o.Imagery = fullfile(root, 'data', 'imagery', 'esri_world_imagery_aoi.jpg'); end
lat0 = mean([min(D.lat) max(D.lat)]);   lon0 = mean([min(D.lon) max(D.lon)]);   kx = 111.195 * cosd(lat0);   ky = 111.195;
tx = @(lon) (lon - lon0) * kx;   ty = @(lat) (lat - lat0) * ky;
% ---- mesh extent: the whole DEM, or the boundary box + 2 km (overview), or an explicit extent (zoom)
ext = o.MeshExtent;
if isempty(ext) && o.Crop, m2 = 2 / ky;   ext = [min(T.ring_ll(:, 2)) - m2 / cosd(lat0), max(T.ring_ll(:, 2)) + m2 / cosd(lat0), min(T.ring_ll(:, 1)) - m2, max(T.ring_ll(:, 1)) + m2]; end
st = o.Stride;   ri = 1:numel(D.lat);   ci = 1:numel(D.lon);
if ~isempty(ext), ri = find(D.lat >= ext(3) & D.lat <= ext(4));   ci = find(D.lon >= ext(1) & D.lon <= ext(2)); end
ri = ri(1:st:end);   ci = ci(1:st:end);   lat = D.lat(ri);   lon = D.lon(ci);   Z = double(D.Z(ri, ci)) / 1000 * VE;   [LON, LAT] = meshgrid(lon, lat);   X = tx(LON);   Y = ty(LAT);
img = imread(o.Imagery);   [h, w, ~] = size(img);   ie = o.ImageExtent;                                   % crop the picture to the mesh so that the texture fills it completely
c0 = max(1, floor((min(lon) - ie(1)) / (ie(2) - ie(1)) * w) + 1);   c1 = min(w, ceil((max(lon) - ie(1)) / (ie(2) - ie(1)) * w));
r0 = max(1, floor((ie(4) - max(lat)) / (ie(4) - ie(3)) * h) + 1);   r1 = min(h, ceil((ie(4) - min(lat)) / (ie(4) - ie(3)) * h));   img = img(r0:r1, c0:c1, :);
% side lighting: hillshade of the (exaggerated) terrain, sun azimuth/altitude o.Sun [deg], multiplied into the imagery so that the relief shows
[gy, gx] = gradient(Z, mean(diff(Y(:, 1))), mean(diff(X(1, :))));   gy = gy;   sl = atan(hypot(gx, gy));   asp = atan2(-gx, -gy);   zen = deg2rad(90 - o.Sun(2));   az = deg2rad(o.Sun(1));
hs = cos(zen) .* cos(sl) + sin(zen) .* sin(sl) .* cos(az - asp);   hs = min(max(hs, 0), 1);   hs = hs ./ max(cos(zen), 0.2);   hs = imresize(flipud(hs), [size(img, 1) size(img, 2)], 'bilinear');
img = uint8(min(255, double(img) .* (0.45 + 0.65 * hs)));
sideLegend = strcmp(o.Legend, 'side');   mapW = 0.74 * sideLegend + 1 * ~sideLegend;
if isempty(o.Fig), fig = figure('Color', o.BG, 'Units', 'centimeters', 'Position', [2 2 o.Size], 'Renderer', 'opengl', 'InvertHardcopy', 'off'); else, fig = o.Fig; end
ax = axes(fig, 'Position', [0 0.07 mapW 0.93], 'Color', o.BG);   hold(ax, 'on');
surface(ax, flipud(X), flipud(Y), flipud(Z), img, 'FaceColor', 'texturemap', 'EdgeColor', 'none', 'FaceLighting', 'none');
Zd = imdilate(Z, strel('disk', 2)) + 0.035;                                      % ridge-clearance mesh for the fibre and the icons (km after VE)
zAt = @(lon, lat) interp2(LON, LAT, Zd, lon, lat, 'linear', max(Zd(:)));
% ---- fibre along the boundary, coloured by zone
pl = T.ring_ll;   pc = r.cell(:);   zn = T.cells.zoneCode(pc);   zc = [0.25 0.55 1.0; 1.0 0.75 0.15; 0.95 0.15 0.15];   H.fibre = gobjects(3, 1);
for k = 1:3
    m = zn == k;   m = m & mod((1:numel(m))', 2) == 1;   lo = pl(:, 2);   la = pl(:, 1);   lo(~m) = NaN;   la(~m) = NaN;
    H.fibre(k) = plot3(ax, tx(lo), ty(la), zAt(lo, la), '.', 'Color', zc(k, :), 'MarkerSize', 6);
end
% ---- assets
cs = A.sites([A.sites.in]);   isCp = string({cs.kind}) == "checkpoint";   cll = @(s) deal(r.lon0 + [s.x] / r.kx, r.lat0 + [s.y] / r.ky);
[lo, la] = cll(cs(~isCp));   H.cam = plot3(ax, tx(lo), ty(la), zAt(lo, la) + 0.03, 'o', 'MarkerFaceColor', [0.1 0.8 1], 'MarkerEdgeColor', 'k', 'MarkerSize', 4);
[lo, la] = cll(cs(isCp));    H.cp = plot3(ax, tx(lo), ty(la), zAt(lo, la) + 0.05, 'd', 'MarkerFaceColor', [0.2 1 0.4], 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
ia = alloc.interrogators;   H.iu = plot3(ax, tx(ia.lon), ty(ia.lat), zAt(ia.lon, ia.lat) + 0.06, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'MarkerSize', 8);
if isfield(ia, 'site_lon'), plot3(ax, tx(ia.site_lon), ty(ia.site_lat), zAt(ia.site_lon, ia.site_lat) + 0.08, 's', 'MarkerFaceColor', [1 1 0.6], 'MarkerEdgeColor', 'k', 'LineWidth', 1, 'MarkerSize', 7); end
st3 = alloc.drones.station_xy;   dla = r.lat0 + st3(:, 2) / r.ky;   dlo = r.lon0 + st3(:, 1) / r.kx;   zg = zAt(dlo, dla);   zu = zg + 1.2;     % drone stations: altitude NOT to scale
for i = 1:numel(dla), plot3(ax, tx(dlo(i)) * [1 1], ty(dla(i)) * [1 1], [zg(i) zu(i)], '-', 'Color', [0.55 0.2 0.9], 'LineWidth', 0.8); end
H.uav = plot3(ax, tx(dlo), ty(dla), zu, '^', 'MarkerFaceColor', [0.65 0.3 1], 'MarkerEdgeColor', 'w', 'MarkerSize', 8);
for i = 1:numel(dla), text(ax, tx(dlo(i)), ty(dla(i)), zu(i) + 0.35, sprintf('%d', alloc.drones.n(i)), 'Color', 'w', 'FontSize', 7, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.5], 'Margin', 0.5); end
% ---- landmarks (label offsets chosen so that neighbouring names do not overlap: dx, dy in km, alignment)
if o.Landmarks
    Lm = readtable(fullfile(root, 'third_party', 'dasmap_data', 'holy_sites.csv'), 'TextType', 'string');
    off = containers.Map({'Masjid al-Haram', 'Jamarat', 'Mina', 'Muzdalifah', 'Arafat'}, {[-0.9 -1.3 1], [-1.2 2.2 1], [0.5 -0.9 2], [0.6 0 2], [-0.3 2.2 1]});     % [dx dy align(0 centre,1 right,2 left)]
    for i = 1:height(Lm)
        zz = zAt(Lm.lon(i), Lm.lat(i));   plot3(ax, tx(Lm.lon(i)), ty(Lm.lat(i)), zz + 0.05, 'p', 'MarkerFaceColor', [1 1 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        q = [0 0.6 0];   if isKey(off, char(Lm.name(i))), q = off(char(Lm.name(i))); end,   ha = {'center', 'right', 'left'};
        plot3(ax, [tx(Lm.lon(i)) tx(Lm.lon(i)) + q(1)], [ty(Lm.lat(i)) ty(Lm.lat(i)) + q(2)], [zz + 0.05 zz + 0.45], 'k-', 'LineWidth', 0.5);
        text(ax, tx(Lm.lon(i)) + q(1), ty(Lm.lat(i)) + q(2), zz + 0.45, Lm.name(i), 'FontSize', 6.5, 'FontWeight', 'bold', 'Color', 'k', 'BackgroundColor', [1 1 1 0.8], 'Margin', 0.4, 'HorizontalAlignment', ha{q(3) + 1}, 'Interpreter', 'none');
    end
end
if o.Names
    for i = find(isCp)
        xx = tx(r.lon0 + cs(i).x / r.kx);   yy = ty(r.lat0 + cs(i).y / r.ky);   ha = 'left';   dx = 0.25;   dy = 0;
        if xx > 12, ha = 'right';   dx = -0.25; end,   if contains(string(cs(i).name), "Sharaye"), dx = 0.3;   dy = 1.2;   ha = 'left'; end,   if contains(string(cs(i).name), "Hada"), dy = -1.3; end,   if contains(string(cs(i).name), "Nawariyah"), dy = 1.6;   dx = -1.0;   ha = 'right'; end                % Al-Sharaye: above the fibre, not on it
        zc0 = zAt(r.lon0 + cs(i).x / r.kx, r.lat0 + cs(i).y / r.ky);   if abs(dy) > 0.5 || abs(dx) > 0.5, plot3(ax, [xx xx + dx], [yy yy + dy], [zc0 + 0.05 zc0 + 0.25], 'k-', 'LineWidth', 0.5); end
        text(ax, xx + dx, yy + dy, zc0 + 0.25, char(cs(i).name), 'FontSize', 5.5, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.8], 'Margin', 0.3, 'Interpreter', 'none', 'HorizontalAlignment', ha);
    end
end
% ---- intruders of a simulated run
H.int = gobjects(3, 1);   cnt = [0 0 0];   tot = [0 0 0];
if ~isempty(E)
    ll = T.ring_ll(E.piece, :);   ver = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none") & E.in_Tresp;   late = E.detected & ~ver;   miss = ~E.detected;   sel = {ver, late, miss};
    mk = {'o', 's', 'x'};   col = {[0.1 0.85 0.2], [1 0.6 0], [1 0 1]};
    if ~isempty(o.ZoomExtent), inb = ll(:, 2) >= o.ZoomExtent(1) & ll(:, 2) <= o.ZoomExtent(2) & ll(:, 1) >= o.ZoomExtent(3) & ll(:, 1) <= o.ZoomExtent(4); else, inb = true(height(E), 1); end
    rsub = RandStream('Threefry', 'Seed', 5);   keep = false(height(E), 1);   idx = find(inb);   idx = idx(randperm(rsub, numel(idx), min(numel(idx), o.MaxIntruders)));   keep(idx) = true;   tot = [nnz(sel{1} & inb), nnz(sel{2} & inb), nnz(sel{3} & inb)];
    for k = 1:3
        m = sel{k} & keep;   cnt(k) = nnz(m);   zz = zAt(ll(m, 2), ll(m, 1)) + 0.09;
        if k < 3, H.int(k) = plot3(ax, tx(ll(m, 2)), ty(ll(m, 1)), zz, mk{k}, 'MarkerFaceColor', col{k}, 'MarkerEdgeColor', 'k', 'MarkerSize', 3.5);
        else, H.int(k) = plot3(ax, tx(ll(m, 2)), ty(ll(m, 1)), zz, mk{k}, 'Color', col{k}, 'LineWidth', 1.1, 'MarkerSize', 5); end
    end
end
% ---- view
axis(ax, 'equal');   axis(ax, 'off');   if isempty(cam.target), cam.target = [mean(X(:)) mean(Y(:)) mean(Z(:))]; end
if isfield(cam, 'pan') && ~isempty(cam.pan), cam.target(1:2) = cam.target(1:2) + cam.pan; end,   set_camera(ax, cam.target, cam);   ax.Clipping = 'off';   xlim(ax, [min(X(:)) max(X(:))]);   ylim(ax, [min(Y(:)) max(Y(:))]);   zlim(ax, [0 max(Z(:)) + 3]);
L = 3;   if cam.dist < 20, L = 2; end
if cam.dist >= 20, x0 = mean(X(:)) + 11;   y0 = min(Y(:)) + 0.3; else, x0 = cam.target(1) - L / 2;   y0 = cam.target(2) - 0.25 * cam.dist; end
zb = zAt(lon0 + x0 / kx, lat0 + y0 / ky) + 0.1 + 0.6 * (cam.dist < 20);
plot3(ax, [x0 x0 + L], [y0 y0], [zb zb], 'k-', 'LineWidth', 3);   plot3(ax, [x0 x0 + L], [y0 y0], [zb zb], 'w-', 'LineWidth', 1.2);
text(ax, x0 + L / 2, y0, zb + 0.3, sprintf('%d km', L), 'FontSize', 6, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1 0.8], 'Margin', 0.4);
% ---- overlay: north arrow, attribution, legend panel
ov = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1]);   hold(ov, 'on');
patch(ov, mapW * [0.94 0.92 0.96], [0.955 0.90 0.90] - 0.0, 'w', 'EdgeColor', 'k');   text(ov, mapW * 0.94, 0.975, 'N', 'FontWeight', 'bold', 'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', tc);
patch(ov, [0 mapW mapW 0], [0 0 0.07 0.07], o.BG, 'EdgeColor', 'none');   text(ov, 0.005, 0.035, 'Imagery: Esri, Vantor, Earthstar Geographics, and the GIS User Community. Terrain: Copernicus DEM GLO-30 (vertical exaggeration x' + string(VE) + ').' + newline + 'Data: OpenStreetMap contributors.', 'FontSize', 4.5, 'Color', tc, 'VerticalAlignment', 'middle', 'Interpreter', 'none');
ent = {'Cold zone fibre', 'Neutral zone fibre', 'Hot zone fibre', 'DAS interrogator', 'Drone station (n drones)', 'Entrance checkpoint', 'Existing camera site'};
sty = {{'.', zc(1, :)}, {'.', zc(2, :)}, {'.', zc(3, :)}, {'s', [1 1 1]}, {'^', [0.65 0.3 1]}, {'d', [0.2 1 0.4]}, {'o', [0.1 0.8 1]}};
if isfield(ia, 'site_lon'), ent = [ent(1:4), {'Interrogator shelter'}, ent(5:end)];   sty = [sty(1:4), {{'s', [1 1 0.6]}}, sty(5:end)]; end
if ~isempty(E), ent = [ent, {sprintf('Verified in T_{resp} (%d/%d)', cnt(1), tot(1)), sprintf('Detected, late (%d/%d)', cnt(2), tot(2)), sprintf('Missed by DAS (%d/%d)', cnt(3), tot(3))}];
    sty = [sty, {{'o', [0.1 0.85 0.2]}, {'s', [1 0.6 0]}, {'x', [1 0 1]}}]; end
H.legend_entries = ent;
if sideLegend
    patch(ov, [mapW 1 1 mapW], [0 0 1 1], o.BG, 'EdgeColor', 'none');   n = numel(ent);   dy = min(0.06, 0.8 / n);   y1 = 0.93;   text(ov, mapW + 0.01, 0.975, 'Legend', 'Color', tc, 'FontWeight', 'bold', 'FontSize', 7);
    for i = 1:n
        yy = y1 - (i - 0.5) * dy;
        if sty{i}{1} == '.', plot(ov, mapW + 0.02, yy, '.', 'Color', sty{i}{2}, 'MarkerSize', 14);
        elseif sty{i}{1} == 'x', plot(ov, mapW + 0.02, yy, 'x', 'Color', sty{i}{2}, 'LineWidth', 1.4, 'MarkerSize', 6);
        else, plot(ov, mapW + 0.02, yy, sty{i}{1}, 'MarkerFaceColor', sty{i}{2}, 'MarkerEdgeColor', 'k', 'MarkerSize', 5); end
        text(ov, mapW + 0.045, yy, ent{i}, 'FontSize', 5.6, 'Color', tc, 'VerticalAlignment', 'middle');
    end
end
% ---- zoom views: segment title (nearest entrance checkpoint, length of the boundary inside the window) and a 2D inset of the whole boundary with the window marked
if ~isempty(o.ZoomExtent) && sideLegend
    ze = o.ZoomExtent;   inz = pl(:, 2) >= ze(1) & pl(:, 2) <= ze(2) & pl(:, 1) >= ze(3) & pl(:, 1) <= ze(4);   sp = r.s(:);   both = inz(1:end-1) & inz(2:end);   segKm = sum(abs(diff(sp(:))) .* both) / 1e3;
    zc0 = [mean(ze(1:2)) mean(ze(3:4))];   cpi = find(isCp);   cpx = r.lon0 + [cs(cpi).x] / r.kx;   cpy = r.lat0 + [cs(cpi).y] / r.ky;   dd = hypot((cpx - zc0(1)) * kx, (cpy - zc0(2)) * ky);   [dmin, jm] = min(dd);   nm = char(cs(cpi(jm)).name);
    bear = mod(atan2d((cpx(jm) - zc0(1)) * kx, (cpy(jm) - zc0(2)) * ky), 360);   dirs = {'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'};   dn = dirs{mod(round(bear / 45), 8) + 1};
    H.zoom_caption = sprintf('Boundary segment near %s (%.1f km %s of the view centre), %.1f km of fibre in the window', nm, dmin, dn, segKm);   H.segment_km = segKm;   H.segment_name = nm;
    text(ov, 0.01, 0.965, sprintf('Near %s: %.1f km of boundary in view', nm, segKm), 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'k', 'BackgroundColor', [1 1 1 0.85], 'Margin', 1.5, 'Interpreter', 'none', 'VerticalAlignment', 'top');
    ai = axes(fig, 'Position', [mapW + 0.02, 0.06, 1 - mapW - 0.04, 0.2], 'Color', o.BG, 'XColor', tc, 'YColor', tc, 'Box', 'on');   hold(ai, 'on');   plot(ai, pl(:, 2), pl(:, 1), '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    plot(ai, pl(inz, 2), pl(inz, 1), '.', 'Color', [0.95 0.15 0.15], 'MarkerSize', 5);   rectangle(ai, 'Position', [ze(1) ze(3) ze(2) - ze(1) ze(4) - ze(3)], 'EdgeColor', [0.9 0 0], 'LineWidth', 1.5);
    plot(ai, cpx, cpy, 'd', 'MarkerFaceColor', [0.2 1 0.4], 'MarkerEdgeColor', 'k', 'MarkerSize', 4);   daspect(ai, [1 cosd(lat0) 1]);   axis(ai, 'tight');   set(ai, 'XTick', [], 'YTick', []);   xlabel(ai, 'red box = zoom window', 'FontSize', 5, 'Color', tc);
end
H.fig = fig;   H.ax = ax;   H.count = cnt;   H.zAt = zAt;   H.tx = tx;   H.ty = ty;   H.lon0 = lon0;   H.lat0 = lat0;   H.kx = kx;   H.ky = ky;
end
