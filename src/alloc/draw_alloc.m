function draw_alloc(T, alloc, A, ax)
% DRAW_ALLOC  Allocation layer on the twin: interrogators (squares), drone stations (triangles, number of drones), camera sites (dots).
%   Fibre follows the whole boundary (DAS in all 139 cells in every scenario), so it is the zone-coloured boundary of draw_twin.
r = T.cells.ring;   hold(ax, 'on');
cs = A.sites([A.sites.in]);
plot(ax, r.lon0 + [cs.x] / r.kx, r.lat0 + [cs.y] / r.ky, 'o', 'MarkerFaceColor', [0.1 0.7 0.9], 'MarkerEdgeColor', 'k', 'MarkerSize', 5, 'DisplayName', 'existing camera site');
ia = alloc.interrogators;   plot(ax, ia.lon, ia.lat, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'MarkerSize', 10, 'DisplayName', 'DAS interrogator');
st = alloc.drones.station_xy;   lat = r.lat0 + st(:, 2) / r.ky;   lon = r.lon0 + st(:, 1) / r.kx;
plot(ax, lon, lat, '^', 'MarkerFaceColor', [0.2 0.8 0.2], 'MarkerEdgeColor', 'k', 'MarkerSize', 11, 'DisplayName', 'drone station (number = drones)');
for s = 1:numel(lat), text(ax, lon(s) + 0.004, lat(s), sprintf('%d', alloc.drones.n(s)), 'FontWeight', 'bold', 'Color', 'w', 'BackgroundColor', [0 0 0 0.5]); end
legend(ax, 'show', 'Location', 'northwest');
end
