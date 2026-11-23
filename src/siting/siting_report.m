function R = siting_report(P, T, alloc, C, scenario, outDir)
% SITING_REPORT  2D map and per-site table of a siting allocation.
%
%   R = siting_report(P, T, alloc, C, 'medium', outDir)
%   Table (one row per chosen shelter): id, kind (road / checkpoint), lat, lon, distance to the road [m], ground slope [%], distance to the nearest waterway [m], lead-in fibre [m],
%   boundary arc position [km], channel reach d* - lead-in [km], covered arc segment [km] (the runs for which this shelter is the nearest one within the reach), covered length [km],
%   farthest optical distance [km] (lead-in + arc distance of the farthest covered run end), expected intruders per day served.
%   Map: satellite background, all candidates (grey), chosen shelters (yellow squares, S1..), lead-in fibre (black), the boundary coloured by the shelter that serves it, and the interrogator
%   positions of the main (previous) allocation as hollow white squares.
if nargin < 6, outDir = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'results', 'siting'); end
c = T.cells;   r = c.ring;   runs = c.runs;   L = r.L;   dstar = alloc.siting.dstar_m;   ia = alloc.interrogators;   ns = numel(ia.arc_m);   cand = ia.cand;
mid = (runs.s0 + runs.s1) / 2;   nR = numel(mid);   lam = zeros(nR, 1);   for k = 1:nR, lam(k) = T.lambda.mid(runs.cell(k)) * runs.len(k) / c.L_m(runs.cell(k)); end
% ---- every run goes to the nearest shelter by OPTICAL distance (lead-in + arc distance along the ring); the MILP's own assignment minimises the same quantity
dmat = inf(nR, ns);
for s = 1:ns
    dr = mod(mid - ia.arc_m(s), L);   dl = mod(ia.arc_m(s) - mid, L);   dmat(:, s) = ia.leadin_m(s) + min(dr, dl);
end
[dopt, srv] = min(dmat, [], 2);   unserved = dopt > dstar + 1e-6;
rows = cell(ns, 15);
for s = 1:ns
    m = srv == s & ~unserved;   a = mid(m);   rel = mod(a - ia.arc_m(s) + L / 2, L) - L / 2;                                   % signed arc offsets around the shelter (-L/2..L/2)
    far = max(dopt(m)) + 0;   cs = cand(s);
    rows(s, :) = {sprintf('S%d', s), string(cs.kind), cs.lat, cs.lon, cs.road_m, cs.slope_pct, cs.water_m, ia.leadin_m(s), ia.arc_m(s) / 1e3, (dstar - ia.leadin_m(s)) / 1e3, ...
        (ia.arc_m(s) + min(rel)) / 1e3, (ia.arc_m(s) + max(rel)) / 1e3, sum(runs.len(m)) / 1e3, far / 1e3, sum(lam(m))};
end
R.table = cell2table(rows, 'VariableNames', {'site', 'kind', 'lat', 'lon', 'road_m', 'slope_pct', 'waterway_m', 'leadin_m', 'boundary_arc_km', 'reach_km', 'covered_from_km', 'covered_to_km', 'covered_length_km', 'farthest_optical_km', 'intruders_per_day'});
R.table.name = string({cand.name})';   R.unserved_runs = nnz(unserved);   R.max_optical_km = max(dopt(~unserved)) / 1e3;   R.weighted_distance = sum(lam .* dopt);
R.expected_mean_optical_km = sum(lam .* dopt) / sum(lam) / 1e3;   R.srv = srv;   R.dopt = dopt;
if ~isfolder(outDir), mkdir(outDir); end
writetable(R.table, fullfile(outDir, sprintf('siting_sites_%s.csv', scenario)));
% ---- map
fig = figure('Color', 'w', 'Position', [60 60 1250 850]);   ax = axes(fig);   draw_twin(T, ax, 'Roads', false, 'Landmarks', true);   hold(ax, 'on');   legend(ax, 'off');
cl = lines(ns);   pc = r.cell(:);   pl = T.ring_ll;   [~, kk] = min(abs(r.s(:)' - mid), [], 1);   % boundary pieces: serving shelter of the run that contains them
pieceRun = zeros(numel(r.s), 1);   for k = 1:nR, pieceRun(r.s(:) >= runs.s0(k) & r.s(:) <= runs.s1(k)) = k; end
for s = 1:ns, mm = pieceRun > 0 & ismember(pieceRun, find(srv == s)); xx = pl(:, 2);   yy = pl(:, 1);   xx(~mm) = NaN;   yy(~mm) = NaN;   plot(ax, xx, yy, '.', 'Color', cl(s, :), 'MarkerSize', 9, 'HandleVisibility', 'off'); end
% all candidates
cx = [C.lon];   cy = [C.lat];   hC = plot(ax, cx, cy, '.', 'Color', [0.8 0.8 0.8], 'MarkerSize', 6, 'DisplayName', sprintf('candidate shelter sites (%d)', numel(C)));
% main allocation (previous): interrogator arcs of results/alloc_<scenario>_22.mat
f0 = fullfile(fileparts(fileparts(outDir)), 'results', sprintf('alloc_%s_22.mat', scenario));   hO = gobjects(0);
if isfile(f0), X = load(f0);   hO = plot(ax, X.alloc.interrogators.lon, X.alloc.interrogators.lat, 's', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'w', 'LineWidth', 2, 'MarkerSize', 12, 'DisplayName', 'previous interrogator positions (main model)'); end
for s = 1:ns, plot(ax, [ia.lon(s) ia.site_lon(s)], [ia.lat(s) ia.site_lat(s)], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); end
hS = plot(ax, ia.site_lon, ia.site_lat, 's', 'MarkerFaceColor', [1 1 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'MarkerSize', 11, 'DisplayName', sprintf('chosen shelters (%d)', ns));
for s = 1:ns, text(ax, ia.site_lon(s) + 0.004, ia.site_lat(s) + 0.004, sprintf('S%d (%s)', s, cand(s).kind), 'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.8], 'Margin', 1); end
hh = [hC, hO, hS];   for s = 1:ns, hh(end+1) = plot(ax, NaN, NaN, '-', 'Color', cl(s, :), 'LineWidth', 4, 'DisplayName', sprintf('S%d serves %.1f km (max optical distance %.1f km)', s, R.table.covered_length_km(s), R.table.farthest_optical_km(s))); end %#ok<AGROW>
legend(ax, hh, 'Location', 'northwest', 'Color', 'w', 'FontSize', 8);   title(ax, sprintf('Interrogator siting, %s scenario: d* = %.2f km, N_{min} = %d, N = %d (SIMULATED Pd(d); thresholds ASSUMED)', scenario, dstar / 1e3, alloc.siting.Nmin, ns), 'FontSize', 10);
exportgraphics(fig, fullfile(outDir, sprintf('siting_map_%s.png', scenario)), 'Resolution', 140);   close(fig);
end
