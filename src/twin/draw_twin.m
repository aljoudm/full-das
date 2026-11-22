function ax = draw_twin(T, ax, varargin)
% DRAW_TWIN  Base layer of the twin: satellite imagery (default) or DEM hillshade, roads, boundary coloured by zone, named landmarks,
%            scale bar (km) and north arrow.
%
%   ax = draw_twin(T)                      new figure;  draw_twin(T, ax) draws into ax
%   draw_twin(T, ax, 'Background', 'hillshade')     'satellite' (default) | 'hillshade'
%   draw_twin(T, ax, 'Roads', false, 'Landmarks', false)
%   Zone colours: Cold blue, Neutral amber, Hot red. Imagery: Esri World Imagery (see data/imagery/README.md for the attribution).
ip = inputParser;   addParameter(ip, 'Background', 'satellite');   addParameter(ip, 'Roads', true);   addParameter(ip, 'Landmarks', true);   parse(ip, varargin{:});   o = ip.Results;
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 2 || isempty(ax), figure('Color', 'w', 'Position', [60 60 1200 820]); ax = axes; end
hold(ax, 'on');   D = T.dem;   lonL = [min(D.lon) max(D.lon)];   latL = [min(D.lat) max(D.lat)];
if strcmp(o.Background, 'satellite') && isfile(fullfile(root, 'data', 'imagery', 'esri_world_imagery_aoi.jpg'))
    I = imread(fullfile(root, 'data', 'imagery', 'esri_world_imagery_aoi.jpg'));
    image(ax, [39.5788 40.0622], [21.5831 21.2625], I);   set(ax, 'YDir', 'normal');
    rcol = [1 1 1];   rw = 0.7;   src = 'Imagery: Esri, Vantor, Earthstar Geographics, and the GIS User Community. Roads and boundary: OpenStreetMap contributors.';
else
    dxm = mean(diff(D.lon)) * 111195 * cosd(mean(D.lat));   dym = mean(diff(D.lat)) * 111195;
    [gx, gy] = gradient(double(D.Z), dxm, dym);   az = 315;   el = 45;
    sl = pi/2 - atan(hypot(gx, gy));   asp = atan2(-gx, gy);
    hs = sin(el*pi/180) * cos(sl) + cos(el*pi/180) * sin(sl) .* cos(az*pi/180 - asp);
    hs = (hs - min(hs(:))) / (max(hs(:)) - min(hs(:)));
    imagesc(ax, D.lon, D.lat, hs);   set(ax, 'YDir', 'normal');   colormap(ax, gray(256));   clim(ax, [0.2 1.05]);
    rcol = [0.35 0.35 0.35];   rw = 0.5;   src = 'Terrain: Copernicus DEM GLO-30. Roads and boundary: OpenStreetMap contributors.';
end
if o.Roads
    for i = 1:numel(T.roads)
        cl = erase(char(T.roads(i).class), '_link');
        if ismember(cl, {'motorway', 'trunk', 'primary'}), lw = rw * 1.6; else, lw = rw; end
        plot(ax, T.roads(i).lon, T.roads(i).lat, '-', 'Color', [rcol 0.6], 'LineWidth', lw, 'HandleVisibility', 'off');
    end
end
zn = {'Cold zone', 'Neutral zone', 'Hot zone'};   zc = [0.25 0.55 1.0; 1.0 0.75 0.15; 0.95 0.2 0.2];
pc = T.cells.ring.cell(:);   z = T.cells.zoneCode(pc);   h = gobjects(3, 1);
for k = 1:3
    m = z == k;   xx = T.ring_ll(:, 2);   yy = T.ring_ll(:, 1);   xx(~m) = NaN;   yy(~m) = NaN;
    h(k) = plot(ax, xx, yy, '.', 'Color', zc(k, :), 'MarkerSize', 7, 'DisplayName', zn{k});
end
if o.Landmarks, draw_landmarks(ax, root); end
xlim(ax, lonL);   ylim(ax, latL);   set(ax, 'DataAspectRatio', [1 cosd(mean(latL)) 1], 'Layer', 'top', 'Box', 'on');
xlabel(ax, 'longitude [deg E]');   ylabel(ax, 'latitude [deg N]');
legend(ax, h, 'Location', 'northwest', 'Color', [1 1 1], 'EdgeColor', [0.4 0.4 0.4]);
scale_bar(ax, latL, lonL, 10);   north_arrow(ax, latL, lonL);
text(ax, lonL(1) + 0.004, latL(1) + 0.004, src, 'FontSize', 7, 'Color', 'w', 'BackgroundColor', [0 0 0 0.45], 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
end

function draw_landmarks(ax, root)
% Named places: Masjid al-Haram, Mina, Muzdalifah, Arafat (holy_sites.csv of DAS-map, OSM)
L = readtable(fullfile(root, 'third_party', 'dasmap_data', 'holy_sites.csv'), 'TextType', 'string');
for i = 1:height(L)
    plot(ax, L.lon(i), L.lat(i), 'p', 'MarkerFaceColor', [1 1 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 11, 'HandleVisibility', 'off');
    ha = 'left';   dx = 0.006;   if L.name(i) == "Arafat", ha = 'right';   dx = -0.008; end
    text(ax, L.lon(i) + dx, L.lat(i) + 0.006, L.name(i), 'HorizontalAlignment', ha, 'FontWeight', 'bold', 'FontSize', 9, 'Color', 'k', 'BackgroundColor', [1 1 1 0.75], 'Margin', 1, 'Interpreter', 'none');
end
end

function scale_bar(ax, latL, lonL, km)
% scale bar of km kilometres at the lower right
kx = 111.195 * cosd(mean(latL));   x1 = lonL(2) - 0.012;   x0 = x1 - km / kx;   y0 = latL(1) + 0.012;
rectangle(ax, 'Position', [x0 - 0.003, y0 - 0.006, km / kx + 0.006, 0.019], 'FaceColor', [1 1 1 0.8], 'EdgeColor', 'none');
plot(ax, [x0 x1], [y0 y0], 'k-', 'LineWidth', 3, 'HandleVisibility', 'off');
plot(ax, [x0 x0 NaN x1 x1], [y0 y0 + 0.004 NaN y0 y0 + 0.004], 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
text(ax, (x0 + x1) / 2, y0 + 0.007, sprintf('%d km', km), 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
end

function north_arrow(ax, latL, lonL)
% north arrow at the upper right
x = lonL(2) - 0.018;   y = latL(2) - 0.040;   h = 0.028;
rectangle(ax, 'Position', [x - 0.012, y - 0.008, 0.024, h + 0.024], 'FaceColor', [1 1 1 0.8], 'EdgeColor', 'none');
patch(ax, [x x - 0.006 x + 0.006], [y + h, y, y], 'k', 'EdgeColor', 'k', 'HandleVisibility', 'off');
text(ax, x, y + h + 0.004, 'N', 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
end
