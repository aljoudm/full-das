function ax = draw_twin(T, ax)
% DRAW_TWIN  Base layer of the twin: hillshade, roads, boundary coloured by zone (Cold blue, Neutral amber, Hot red).
%   ax = draw_twin(T)        new figure axes;   draw_twin(T, ax) draws into ax. Axes are lon/lat with cosine aspect.
if nargin < 2 || isempty(ax), figure('Color', 'w', 'Position', [60 60 1100 800]); ax = axes; end
hold(ax, 'on');   D = T.dem;
dxm = mean(diff(D.lon)) * 111195 * cosd(mean(D.lat));   dym = mean(diff(D.lat)) * 111195;
[gx, gy] = gradient(double(D.Z), dxm, dym);   az = 315;   el = 45;                      % simple hillshade from the DEM
sl = pi/2 - atan(hypot(gx, gy));   asp = atan2(-gx, gy);
hs = sin(el*pi/180) * cos(sl) + cos(el*pi/180) * sin(sl) .* cos(az*pi/180 - asp);
hs = (hs - min(hs(:))) / (max(hs(:)) - min(hs(:)));
imagesc(ax, D.lon, D.lat, hs);   set(ax, 'YDir', 'normal');   colormap(ax, gray(256));   clim(ax, [0.2 1.05]);
rc = containers.Map({'motorway','trunk','primary','secondary','tertiary'}, {[0.35 0.35 0.35],[0.4 0.4 0.4],[0.5 0.5 0.5],[0.6 0.6 0.6],[0.7 0.7 0.7]});
for i = 1:numel(T.roads)
    cl = char(T.roads(i).class);   cl = erase(cl, '_link');   if ~isKey(rc, cl), continue; end
    plot(ax, T.roads(i).lon, T.roads(i).lat, '-', 'Color', [rc(cl) 0.8], 'LineWidth', 0.5);
end
zc = [0.20 0.45 0.85; 0.95 0.65 0.10; 0.85 0.15 0.15];                         % Cold, Neutral, Hot
pc = T.cells.ring.cell(:);   z = T.cells.zoneCode(pc);
for k = 1:3
    m = z == k;   xx = T.ring_ll(:, 2);   yy = T.ring_ll(:, 1);   xx(~m) = NaN;   yy(~m) = NaN;
    h(k) = plot(ax, xx, yy, '.', 'Color', zc(k, :), 'MarkerSize', 5); %#ok<AGROW>
end
legend(ax, h, {'Cold', 'Neutral', 'Hot'}, 'Location', 'northwest');
xlim(ax, [min(D.lon) max(D.lon)]);   ylim(ax, [min(D.lat) max(D.lat)]);   set(ax, 'DataAspectRatio', [1 cosd(mean(D.lat)) 1]);   xlabel(ax, 'longitude [deg]');   ylabel(ax, 'latitude [deg]');
end
