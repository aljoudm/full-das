function draw_alloc(T, alloc, A, ax)
% DRAW_ALLOC  Allocation layer on the twin: DAS interrogators, drone stations (number of drones), existing camera sites, named entrance checkpoints.
%   The DAS fibre follows the whole boundary (DAS in all 139 cells in every scenario), i.e. the zone-coloured boundary of draw_twin.
r = T.cells.ring;   hold(ax, 'on');   cs = A.sites([A.sites.in]);   isCp = string({cs.kind}) == "checkpoint";
xy = @(s) deal(r.lon0 + [s.x] / r.kx, r.lat0 + [s.y] / r.ky);
[lo, la] = xy(cs(~isCp));
plot(ax, lo, la, 'o', 'MarkerFaceColor', [0.1 0.8 1], 'MarkerEdgeColor', 'k', 'MarkerSize', 6, 'DisplayName', 'Existing camera sites (interdiction points)');
[lo, la] = xy(cs(isCp));
plot(ax, lo, la, 'd', 'MarkerFaceColor', [0.2 1 0.4], 'MarkerEdgeColor', 'k', 'MarkerSize', 10, 'DisplayName', 'Entrance checkpoints with cameras (5 of 6; Al-Laith is far from the boundary)');
for i = find(isCp), text(ax, r.lon0 + cs(i).x / r.kx + 0.005, r.lat0 + cs(i).y / r.ky - 0.006, char(cs(i).name), 'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.75], 'Margin', 1, 'Interpreter', 'none'); end
ia = alloc.interrogators;
plot(ax, ia.lon, ia.lat, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'MarkerSize', 11, 'DisplayName', 'DAS interrogators');
st = alloc.drones.station_xy;   lat = r.lat0 + st(:, 2) / r.ky;   lon = r.lon0 + st(:, 1) / r.kx;
plot(ax, lon, lat, '^', 'MarkerFaceColor', [0.55 0.2 0.9], 'MarkerEdgeColor', 'w', 'MarkerSize', 12, 'DisplayName', 'Drone stations (number = drones)');
for s = 1:numel(lat), text(ax, lon(s) + 0.006, lat(s) + 0.004, sprintf('%d', alloc.drones.n(s)), 'FontWeight', 'bold', 'Color', 'w', 'BackgroundColor', [0 0 0 0.6], 'Margin', 1); end
legend(ax, 'show', 'Location', 'northwest', 'Color', [1 1 1], 'EdgeColor', [0.4 0.4 0.4]);
end
