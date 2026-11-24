% SITING_FIGURES_V2  Two report figures, NEW files only (the old ones in results/siting/ are not touched):
%   report/final/figures/siting_map_medium_v2.png : the siting map of results/siting/siting_map_medium.png without the title, without the hollow squares of the previous (main-model) positions,
%       sites numbered S1..S6 in the order of their position along the boundary, candidate dots larger and darker, same 140 dpi and size.
%   report/final/figures/pd_curve_v2.png          : results/siting/pd_curve.png without the title (re-plotted from results/siting/pd_curve.csv and d_star.json, everything else as it was), 200 dpi.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();   fd = fullfile(root, 'report', 'final', 'figures');   if ~isfolder(fd), mkdir(fd); end
% =========================================================== 1) siting map
T = load_twin(P);   X = load(fullfile(root, 'results', 'alloc_medium_22_siting.mat'));   alloc = X.alloc;   Cc = load(fullfile(root, 'results', 'siting', 'candidates_base.mat'));   C = Cc.C;
c = T.cells;   r = c.ring;   runs = c.runs;   L = r.L;   dstar = alloc.siting.dstar_m;   ia = alloc.interrogators;   ns = numel(ia.arc_m);   cand = ia.cand;
mid = (runs.s0 + runs.s1) / 2;   nR = numel(mid);   lam = zeros(nR, 1);   for k = 1:nR, lam(k) = T.lambda.mid(runs.cell(k)) * runs.len(k) / c.L_m(runs.cell(k)); end %#ok<NASGU>
dmat = inf(nR, ns);   for s = 1:ns, dr = mod(mid - ia.arc_m(s), L);   dl = mod(ia.arc_m(s) - mid, L);   dmat(:, s) = ia.leadin_m(s) + min(dr, dl); end
[dopt, srv0] = min(dmat, [], 2);   unserved = dopt > dstar + 1e-6;
[~, ord] = sort(ia.arc_m);   newNo = zeros(ns, 1);   newNo(ord) = 1:ns;                    % new number of old site s = rank of its boundary arc position
srv = newNo(srv0);   cov = zeros(ns, 1);   far = zeros(ns, 1);
for s = 1:ns, m = srv0 == s & ~unserved;   cov(newNo(s)) = sum(runs.len(m)) / 1e3;   far(newNo(s)) = max(dopt(m)) / 1e3; end
fprintf('new numbering: '); for q = 1:ns, s = ord(q);   fprintf('S%d = %.2f km (%s, %s)  ', q, ia.arc_m(s) / 1e3, cand(s).kind, char(cand(s).name)); end, fprintf('\n');
fig = figure('Color', 'w', 'Position', [60 60 1250 850]);   ax = axes(fig);   draw_twin(T, ax, 'Roads', false, 'Landmarks', true);   hold(ax, 'on');   legend(ax, 'off');   title(ax, '');
cl = lines(ns);   pl = T.ring_ll;   pieceRun = zeros(numel(r.s), 1);   for k = 1:nR, pieceRun(r.s(:) >= runs.s0(k) & r.s(:) <= runs.s1(k)) = k; end
for s = 1:ns, mm = pieceRun > 0 & ismember(pieceRun, find(srv == s));   xx = pl(:, 2);   yy = pl(:, 1);   xx(~mm) = NaN;   yy(~mm) = NaN;   plot(ax, xx, yy, '.', 'Color', cl(s, :), 'MarkerSize', 9, 'HandleVisibility', 'off'); end
hC = plot(ax, [C.lon], [C.lat], '.', 'Color', [0.45 0.45 0.45], 'MarkerSize', 14, 'DisplayName', sprintf('candidate shelter sites (%d)', numel(C)));
for s = 1:ns, plot(ax, [ia.lon(s) ia.site_lon(s)], [ia.lat(s) ia.site_lat(s)], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); end
hS = plot(ax, ia.site_lon, ia.site_lat, 's', 'MarkerFaceColor', [1 1 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'MarkerSize', 11, 'DisplayName', sprintf('chosen shelters (%d)', ns));
for s = 1:ns, text(ax, ia.site_lon(s) + 0.004, ia.site_lat(s) + 0.004, sprintf('S%d (%s)', newNo(s), cand(s).kind), 'FontSize', 8, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.8], 'Margin', 1); end
hh = [hC, hS];   for q = 1:ns, s = ord(q);   hh(end+1) = plot(ax, NaN, NaN, '-', 'Color', cl(q, :), 'LineWidth', 4, 'DisplayName', sprintf('S%d serves %.1f km (max optical distance %.1f km)', q, cov(q), far(q))); end %#ok<AGROW>
legend(ax, hh, 'Location', 'northwest', 'Color', 'w', 'FontSize', 8);
exportgraphics(fig, fullfile(fd, 'siting_map_medium_v2.png'), 'Resolution', 140);   close(fig);
% =========================================================== 2) Pd(d) curve without the title
Tc = readtable(fullfile(root, 'results', 'siting', 'pd_curve.csv'));   J = jsondecode(fileread(fullfile(root, 'results', 'siting', 'd_star.json')));   dstar_km = J.d_star_km;   Pt = J.Pd_target;
dd = Tc.distance_km;   pm = Tc.Pd_mix;   lo = Tc.Pd_fit_lower95;   hi = Tc.Pd_fit_upper95;   fit = Tc.Pd_fit;
fig = figure('Color', 'w', 'Position', [60 60 1000 520]);   ax = axes(fig);   hold(ax, 'on');   fill(ax, [dd(:); flipud(dd(:))], 100 * [lo; flipud(hi)], [0.75 0.85 0.95], 'EdgeColor', 'none', 'FaceAlpha', 0.7);
plot(ax, dd, 100 * pm, 'o', 'Color', [0.05 0.3 0.7], 'MarkerSize', 4);   plot(ax, dd, 100 * fit, 'r-', 'LineWidth', 1.4);   plot(ax, dd, 100 * lo, 'b--', 'LineWidth', 1);   yline(ax, 100 * Pt, 'k--', sprintf('Pd_{DAS} = %.3f', Pt));
xline(ax, dstar_km, 'g-', 'LineWidth', 1.5);   text(ax, dstar_km + 0.3, 79, sprintf('d* = %.2f km', dstar_km), 'Color', [0 0.55 0], 'FontWeight', 'bold', 'FontSize', 11);
xlabel(ax, 'total optical distance from the interrogator d [km]');   ylabel(ax, 'Pd [%]');   ylim(ax, [75 101]);   grid(ax, 'on');   legend(ax, {'95 % limits of the monotone fit', 'observed Pd (type mix)', 'monotone fit', 'lower 95 % limit'}, 'Location', 'southwest');
exportgraphics(fig, fullfile(fd, 'pd_curve_v2.png'), 'Resolution', 200);   close(fig);
