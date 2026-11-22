function H = draw_twin3d(T, P, alloc, A, E, cam, varargin)
% DRAW_TWIN3D  3D digital twin in the style of DAS-map (aljoudm/DAS-map-, main_static.m): Esri World Imagery draped on the Copernicus DEM GLO-30, vertical exaggeration 2, perspective camera.
%
%   H = draw_twin3d(T, P, alloc, A, E, cam)                       T twin (load_twin), alloc/A (get_allocation), E = intruder table of a run (stage8/9) or [] , cam = twin3d_camera(...)
%   H = draw_twin3d(..., 'Imagery', file, 'Landmarks', true, 'Names', true, 'Fig', fig, 'Size', [16 11])   figure size in cm (A4 text width 16 cm)
%   Layers: terrain + imagery; fibre along the boundary coloured by zone (Cold blue, Neutral amber, Hot red; lifted above a ridge-dilated mesh); DAS interrogators in their shelters,
%   drone stations (number of drones, NOT TO SCALE altitude), existing camera sites and the named entrance checkpoints; intruders: green = detected and verified within T_resp,
%   orange = detected but not verified in time, magenta = missed by the DAS. Overlay: legend, scale bar, north arrow, attribution.
ip = inputParser;   addParameter(ip, 'Imagery', '');   addParameter(ip, 'Landmarks', true);   addParameter(ip, 'Names', true);   addParameter(ip, 'Fig', []);   addParameter(ip, 'Size', [16 11]);
addParameter(ip, 'ZoomExtent', []);   addParameter(ip, 'MaxIntruders', 350);   addParameter(ip, 'MeshExtent', []);   addParameter(ip, 'Stride', 3);   addParameter(ip, 'LegendPos', 'tl');   parse(ip, varargin{:});   o = ip.Results;
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));   D = T.dem;   r = T.cells.ring;   VE = cam.VE;
if isempty(o.Imagery), o.Imagery = fullfile(root, 'data', 'imagery', 'esri_world_imagery_aoi.jpg'); end
lat0 = mean([min(D.lat) max(D.lat)]);   lon0 = mean([min(D.lon) max(D.lon)]);   kx = 111.195 * cosd(lat0);   ky = 111.195;
tx = @(lon) (lon - lon0) * kx;   ty = @(lat) (lat - lat0) * ky;
% ---- mesh (decimated so that the 30 m DEM becomes about 90 m cells)
st = o.Stride;   ri = 1:st:numel(D.lat);   ci = 1:st:numel(D.lon);
if ~isempty(o.MeshExtent), ri = find(D.lat >= o.MeshExtent(3) & D.lat <= o.MeshExtent(4));   ci = find(D.lon >= o.MeshExtent(1) & D.lon <= o.MeshExtent(2));   ri = ri(1:st:end);   ci = ci(1:st:end); end
lat = D.lat(ri);   lon = D.lon(ci);   Z = double(D.Z(ri, ci)) / 1000 * VE;   [LON, LAT] = meshgrid(lon, lat);   X = tx(LON);   Y = ty(LAT);
if isempty(o.Fig), fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 o.Size], 'Renderer', 'opengl'); else, fig = o.Fig; end
ax = axes(fig, 'Position', [0 0 1 1]);   hold(ax, 'on');
img = imread(o.Imagery);
if ~isempty(o.ZoomExtent), img = img; end %#ok<ASGSL>
surface(ax, flipud(X), flipud(Y), flipud(Z), img, 'FaceColor', 'texturemap', 'EdgeColor', 'none', 'FaceLighting', 'none');
Zd = imdilate(Z, strel('disk', 3)) + 0.035;                                      % ridge-clearance mesh for the fibre and the icons (km after VE)
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
st3 = alloc.drones.station_xy;   dla = r.lat0 + st3(:, 2) / r.ky;   dlo = r.lon0 + st3(:, 1) / r.kx;   zg = zAt(dlo, dla);   zu = zg + 1.2;     % drone stations: altitude NOT to scale
for i = 1:numel(dla), plot3(ax, tx(dlo(i)) * [1 1], ty(dla(i)) * [1 1], [zg(i) zu(i)], '-', 'Color', [0.55 0.2 0.9], 'LineWidth', 0.8); end
H.uav = plot3(ax, tx(dlo), ty(dla), zu, '^', 'MarkerFaceColor', [0.65 0.3 1], 'MarkerEdgeColor', 'w', 'MarkerSize', 8);
for i = 1:numel(dla), text(ax, tx(dlo(i)), ty(dla(i)), zu(i) + 0.35, sprintf('%d', alloc.drones.n(i)), 'Color', 'w', 'FontSize', 7, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.5], 'Margin', 0.5); end
% ---- landmarks
if o.Landmarks
    Lm = readtable(fullfile(root, 'third_party', 'dasmap_data', 'holy_sites.csv'), 'TextType', 'string');
    for i = 1:height(Lm)
        zz = zAt(Lm.lon(i), Lm.lat(i));   plot3(ax, tx(Lm.lon(i)), ty(Lm.lat(i)), zz + 0.05, 'p', 'MarkerFaceColor', [1 1 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        text(ax, tx(Lm.lon(i)), ty(Lm.lat(i)), zz + 0.45, Lm.name(i), 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'k', 'BackgroundColor', [1 1 1 0.78], 'Margin', 0.5, 'HorizontalAlignment', 'center', 'Interpreter', 'none');
    end
end
if o.Names
    for i = find(isCp)
        xx = tx(r.lon0 + cs(i).x / r.kx);   ha = 'left';   dx = 0.2;   if xx > 12, ha = 'right';   dx = -0.2; end
        text(ax, xx + dx, ty(r.lat0 + cs(i).y / r.ky), zAt(r.lon0 + cs(i).x / r.kx, r.lat0 + cs(i).y / r.ky) + 0.25, char(cs(i).name), 'FontSize', 6, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.78], 'Margin', 0.3, 'Interpreter', 'none', 'HorizontalAlignment', ha);
    end
end
% ---- intruders of a simulated run
H.int = gobjects(3, 1);   cnt = [0 0 0];
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
axis(ax, 'equal');   axis(ax, 'off');   set_camera(ax, cam.target, cam);   ax.Clipping = 'off';
xlim(ax, [min(X(:)) max(X(:))]);   ylim(ax, [min(Y(:)) max(Y(:))]);   zlim(ax, [0 max(Z(:)) + 3]);
% 3D scale bar on the ground (approximate in a perspective view)
L = 5;   if cam.dist < 20, L = 2; end
if cam.dist >= 20, x0 = min(X(:)) + 4;   y0 = min(Y(:)) + 3; else, x0 = cam.target(1) - L / 2;   y0 = cam.target(2) - 0.25 * cam.dist; end
zb = zAt(lon0 + x0 / kx, lat0 + y0 / ky) + 0.1 + 0.6 * (cam.dist < 20);
plot3(ax, [x0 x0 + L], [y0 y0], [zb zb], 'k-', 'LineWidth', 3);   plot3(ax, [x0 x0 + L], [y0 y0], [zb zb], 'w-', 'LineWidth', 1.2);
text(ax, x0 + L / 2, y0, zb + 0.3, sprintf('%d km (approximate, perspective)', L), 'FontSize', 7, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1 0.8], 'Margin', 0.5);
% ---- 2D overlay: legend, north arrow, attribution
ov = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1]);   hold(ov, 'on');
ent = {'Cold zone fibre', 'Neutral zone fibre', 'Hot zone fibre', 'DAS interrogator (in a shelter)', 'Drone station (n drones; altitude not to scale)', 'Entrance checkpoint (with cameras)', 'Existing camera site'};
sty = {{'.', zc(1, :)}, {'.', zc(2, :)}, {'.', zc(3, :)}, {'s', [1 1 1]}, {'^', [0.65 0.3 1]}, {'d', [0.2 1 0.4]}, {'o', [0.1 0.8 1]}};
if ~isempty(E), ent = [ent, {sprintf('Intruder detected + verified within T_{resp} (%d shown of %d)', cnt(1), tot(1)), sprintf('Intruder detected, not verified in time (%d of %d)', cnt(2), tot(2)), sprintf('Intruder missed by the DAS (%d of %d)', cnt(3), tot(3))}];
    sty = [sty, {{'o', [0.1 0.85 0.2]}, {'s', [1 0.6 0]}, {'x', [1 0 1]}}]; end
n = numel(ent);   dy = 0.034;   if strcmp(o.LegendPos, 'bl'), y1 = 0.045 + n * dy + 0.01; else, y1 = 0.985; end
rect = patch(ov, [0.005 0.40 0.40 0.005], [y1 - n * dy - 0.01, y1 - n * dy - 0.01, y1 + 0.005, y1 + 0.005], 'w', 'FaceAlpha', 0.82, 'EdgeColor', [0.4 0.4 0.4]); %#ok<NASGU>
for i = 1:n
    yy = y1 - (i - 0.5) * dy;   if sty{i}{1} == '.', plot(ov, 0.02, yy, '.', 'Color', sty{i}{2}, 'MarkerSize', 14); else, plot(ov, 0.02, yy, sty{i}{1}, 'MarkerFaceColor', sty{i}{2}, 'MarkerEdgeColor', 'k', 'Color', sty{i}{2}, 'MarkerSize', 5); end
    text(ov, 0.04, yy, ent{i}, 'FontSize', 6, 'VerticalAlignment', 'middle');
end
patch(ov, [0.955 0.943 0.967], [0.965 0.915 0.915], 'k');   text(ov, 0.955, 0.975, 'N', 'FontWeight', 'bold', 'FontSize', 8, 'HorizontalAlignment', 'center');
text(ov, 0.005, 0.008, 'Imagery: Esri, Vantor, Earthstar Geographics, and the GIS User Community. Terrain: Copernicus DEM GLO-30 (vertical exaggeration x2). Data: OpenStreetMap contributors. SIMULATED intruders.', 'FontSize', 5, 'Color', 'w', 'BackgroundColor', [0 0 0 0.45], 'Interpreter', 'none');
H.fig = fig;   H.ax = ax;   H.count = cnt;   H.zAt = zAt;   H.tx = tx;   H.ty = ty;   H.lon0 = lon0;   H.lat0 = lat0;   H.kx = kx;   H.ky = ky;
end

