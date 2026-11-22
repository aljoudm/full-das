% STAGE8_FIGURES  Figures of Stage 8 (all SIMULATED, from results/stage8/*): (1) boundary map with the zones and the intruders (detected+verified, detected but not verified in time,
% missed), (2) timeline of one incident from the alarm to the patrol, (3) bar chart of the three scenarios. Files: results/figures/stage8_*.png
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   fd = fullfile(root, 'results', 'figures');   if ~isfolder(fd), mkdir(fd); end
M = readtable(fullfile(root, 'results', 'stage8', 'metrics_summary.csv'), 'TextType', 'string');   M.Properties.VariableNames{'xCase'} = 'case_';   v = P.v;   f = P.fd;
% ---------------- 1) map (medium)
S = load(fullfile(root, 'results', 'stage8', 'run_medium.mat'));   E = S.E;   ll = T.ring_ll(E.piece, :);
ver = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none") & E.in_Tresp;   late = E.detected & ~ver;   miss = ~E.detected;
ax = draw_twin(T);   hold(ax, 'on');
h1 = plot(ax, ll(ver, 2), ll(ver, 1), 'o', 'MarkerFaceColor', [0.1 0.8 0.2], 'MarkerEdgeColor', 'k', 'MarkerSize', 5, 'DisplayName', sprintf('detected and verified within T_{resp} (%d)', nnz(ver)));
h2 = plot(ax, ll(late, 2), ll(late, 1), 's', 'MarkerFaceColor', [1 0.6 0], 'MarkerEdgeColor', 'k', 'MarkerSize', 5, 'DisplayName', sprintf('detected, not verified in time (%d)', nnz(late)));
h3 = plot(ax, ll(miss, 2), ll(miss, 1), 'x', 'Color', [1 0 1], 'LineWidth', 1.5, 'MarkerSize', 7, 'DisplayName', sprintf('missed by the DAS (%d)', nnz(miss)));
hh = findobj(ax, 'Type', 'line', '-regexp', 'DisplayName', 'zone');   legend(ax, [hh(:); h1; h2; h3], 'Location', 'northwest', 'Color', [1 1 1]);
title(ax, sprintf('Medium scenario, %d simulated days, %d intruders (SIMULATED; base classifier stub ASSUMED)', S.FA.nDays, height(E)), 'FontSize', 10);
exportgraphics(ancestor(ax, 'figure'), fullfile(fd, 'stage8_map_intruders_medium.png'), 'Resolution', 140);   close all;
% ---------------- 2) timeline of one incident (a verified intruder that was confirmed and reached by a patrol, drone-cued)
k = find(ver & ~isnan(E.patrol_dt) & startsWith(E.asset, "drone") & E.zone == 3, 1);   if isempty(k), k = find(ver & ~isnan(E.patrol_dt), 1); end
t0 = E.t_start(k);   t_alarm = E.t_alarm(k);   t_ver = E.t_verif(k);   t_pat = t_alarm + E.patrol_dt(k);
ev = [0, f.T_win_s, f.T_win_s + f.t_proc_s, t_alarm - t0, v.T_launch_s + (t_alarm - t0), t_ver - t0, t_pat - t0];
lab = {'intruder crosses the fibre', 'DAS window complete', 'processing done', 'AI class + alarm', 'drone launched', 'drone on scene (verification)', 'patrol on scene'};
fig = figure('Color', 'w', 'Position', [60 60 1150 520]);   cols = [0.2 0.5 0.9];
for pnl = 1:2
    ax = subplot(2, 1, pnl);   hold(ax, 'on');   lim = [35, ev(end) * 1.05];   xl = lim(pnl);   plot(ax, [0 xl], [0 0], 'k-', 'LineWidth', 1.5);
    patch(ax, [t_alarm - t0 t_ver - t0 t_ver - t0 t_alarm - t0], [-0.06 -0.06 0.06 0.06], [0.1 0.8 0.2], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
    yy = [-1.0 1.0 -0.55 0.55 -0.9 0.9 -0.9];
    for i = 1:numel(ev)
        if ev(i) > xl, continue; end
        plot(ax, [ev(i) ev(i)], [0 yy(i) * 0.95], '-', 'Color', [0.5 0.5 0.5]);   plot(ax, ev(i), 0, 'o', 'MarkerFaceColor', cols, 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
        if pnl == 2 && i <= 5, continue; end                              % the zoom panel labels the first events
        text(ax, ev(i), yy(i), sprintf('%s (%.1f s)', lab{i}, ev(i)), 'HorizontalAlignment', 'left', 'FontSize', 8, 'Rotation', 0, 'BackgroundColor', [1 1 1 0.8]);
    end
    xlim(ax, [-1 xl * 1.0]);   ylim(ax, [-1.2 1.2]);   set(ax, 'YTick', []);   box(ax, 'on');
    if pnl == 1, title(ax, 'zoom: first 35 s (green = alarm to verification)', 'FontSize', 9); else, xlabel(ax, 'seconds after the intruder crosses the fibre'); title(ax, 'whole incident', 'FontSize', 9); end
end
sgtitle(sprintf('One simulated incident (%s intruder, Hot zone, asset %s): alarm %.1f s, verified after %.0f s, patrol on scene %.0f s after the alarm (SIMULATED; t_{proc}, T_{resp}, patrol speed are PLACEHOLDER/ASSUMED)', E.type(k), E.asset(k), t_alarm - t0, E.verif_dt(k), E.patrol_dt(k)), 'FontSize', 9);
exportgraphics(fig, fullfile(fd, 'stage8_timeline_incident.png'), 'Resolution', 140);   close all;
% ---------------- 3) bar chart of the three scenarios (base stub) + Brno-matrix sensitivity as a fourth group
cs = ["low", "medium", "high", "medium_BrnoMatrix_SENSITIVITY"];   mets = ["Pd", "Pc_cond", "Pd_x_Pc", "verified_Tresp", "verified_Tresp_hot", "patrol_reached", "height_measurable"];
mt = ["Pd", "Pc | detection", "Pd x Pc", "verified in T_{resp}", "verified in T_{resp}, Hot", "patrol reached", "height measurable"];
V = zeros(numel(mets), numel(cs));   LO = V;   HI = V;
for i = 1:numel(mets), for j = 1:numel(cs), r = M(M.case_ == cs(j) & M.metric == mets(i), :);   V(i, j) = r.value;   LO(i, j) = r.lo;   HI(i, j) = r.hi; end, end
fig = figure('Color', 'w', 'Position', [60 60 1200 520]);   ax = axes(fig);   b = bar(ax, 100 * V, 'grouped');   hold(ax, 'on');
cl = [0.75 0.85 0.95; 0.35 0.6 0.9; 0.05 0.3 0.7; 0.9 0.7 0.3];   for j = 1:numel(cs), b(j).FaceColor = cl(j, :); end
for j = 1:numel(cs), x = b(j).XEndPoints;   errorbar(ax, x, 100 * V(:, j), 100 * (V(:, j) - LO(:, j)), 100 * (HI(:, j) - V(:, j)), 'k.', 'LineWidth', 0.8); end
set(ax, 'XTickLabel', mt, 'XTickLabelRotation', 20);   ylabel(ax, '% of real intruders (or of the stated base)');   ylim(ax, [0 105]);   grid(ax, 'on');
legend(ax, {'low (3 drones)', 'medium (6)', 'high (12)', 'medium, Brno matrix (SENSITIVITY)'}, 'Location', 'northeast');
title(ax, 'System-level metrics, SIMULATED (60 days per case, 95 % bootstrap over days). Base classifier: uniform stub, Pc 0.983 (ASSUMED); Brno matrix = SENSITIVITY only', 'FontSize', 9);
exportgraphics(fig, fullfile(fd, 'stage8_scenarios_bars.png'), 'Resolution', 140);
% false-alarm bars (log scale) against the target
fig = figure('Color', 'w', 'Position', [60 60 820 420]);   ax = axes(fig);   hold(ax, 'on');   fm = ["fa_cued", "fa_site", "fa_patrol"];   fl = ["before verification: drone/camera-cued", "before verification: routed to site guards", "after verification: reaching a patrol"];
FV = zeros(3, 3);   for i = 1:3, for j = 1:3, FV(i, j) = M.value(M.case_ == cs(j) & M.metric == fm(i)); end, end
bb = bar(ax, FV);   set(ax, 'YScale', 'log', 'XTickLabel', fl, 'XTickLabelRotation', 12);   yline(ax, f.FAR_per_km_day, 'r--', sprintf('target %.2f', f.FAR_per_km_day), 'LineWidth', 1.5);
ylabel(ax, 'false alarms per km per day');   legend(ax, {'low', 'medium', 'high'}, 'Location', 'northwest');   grid(ax, 'on');
title(ax, 'False alarms vs the target (SIMULATED; authorized-vehicle rate and p_{site\_clear} are PLACEHOLDERS)', 'FontSize', 9);
exportgraphics(fig, fullfile(fd, 'stage8_false_alarms.png'), 'Resolution', 140);   close all;
disp('figures written');
