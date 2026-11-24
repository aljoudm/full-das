% FINAL_STAGE9_CHART  Before / after chart of the Stage 9 rerun with the siting model (SIMULATED; medium scenario, 394 days, 10,004 intruders, same common random numbers).
% Left: share of intruders missed by the DAS against the distance from the interrogator. Right: Pd, Pd x Pc, verified within T_resp, patrol reached.
% Data: results/stage9_siting/comparison.csv and comparison_by_distance.csv. Output: report/figures/stage9_before_after.png (16 cm wide, 300 dpi).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
C = readtable(fullfile(root, 'results', 'stage9_siting', 'comparison.csv'));   D = readtable(fullfile(root, 'results', 'stage9_siting', 'comparison_by_distance.csv'));
D = D(strcmp(D.scenario, 'medium'), :);   C = C(strcmp(C.scenario, 'medium'), :);
fig = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 16 8.4], 'InvertHardcopy', 'off');   cb = [0.55 0.55 0.6];   ca = [0.1 0.45 0.75];
ax = axes(fig, 'Position', [0.08 0.30 0.40 0.62]);   hold(ax, 'on');   bins = {'0-5', '5-10', '10-14.75', '14.75-15', '15-20'};   bf = strcmp(D.model, 'stage9');   af = strcmp(D.model, 'stage9_siting');
yb = D.missed_pct(bf);   ya = zeros(5, 1);   ya(1:3) = D.missed_pct(af);   ya(4:5) = NaN;                    % after the change no event is farther than 14.23 km: the bins above 14.75 km are empty
bar(ax, (1:5) - 0.19, yb, 0.36, 'FaceColor', cb);   bar(ax, (1:3) + 0.19, ya(1:3), 0.36, 'FaceColor', ca);   set(ax, 'XTick', 1:5, 'XTickLabel', bins, 'FontSize', 6.5, 'XTickLabelRotation', 25);   xlabel(ax, 'distance from the interrogator [km]', 'FontSize', 7);   ylabel(ax, 'intruders missed by the DAS [%]', 'FontSize', 7);
text(ax, 4.75, 21.3, {'after: no events beyond 14.23 km'}, 'FontSize', 6, 'Color', ca, 'HorizontalAlignment', 'center');
legend(ax, {'before (4 interrogators)', 'after (6 sited)'}, 'FontSize', 6, 'Location', 'north', 'Box', 'off');   title(ax, 'DAS misses by distance', 'FontSize', 7.5);   grid(ax, 'on');
ax2 = axes(fig, 'Position', [0.58 0.30 0.40 0.62]);   hold(ax2, 'on');   mets = {'Pd', 'Pd_x_Pc', 'verified_Tresp', 'patrol_reached'};   lab = {'Pd', 'Pd x Pc', 'verified in T_{resp}', 'patrol reached'};   vb = zeros(4, 1);   va = vb;
for k = 1:4, vb(k) = 100 * C.value(strcmp(C.model, 'stage9') & strcmp(C.metric, mets{k}));   va(k) = 100 * C.value(strcmp(C.model, 'stage9_siting') & strcmp(C.metric, mets{k})); end
bar(ax2, (1:4) - 0.19, vb, 0.36, 'FaceColor', cb);   bar(ax2, (1:4) + 0.19, va, 0.36, 'FaceColor', ca);   set(ax2, 'XTick', 1:4, 'XTickLabel', lab, 'FontSize', 6.5, 'XTickLabelRotation', 20);   ylabel(ax2, '[% of all intruders]', 'FontSize', 7);   ylim(ax2, [0 115]);   ylim(ax, [0 24]);
for k = 1:4, text(ax2, k - 0.19, vb(k) + 2, sprintf('%.1f', vb(k)), 'FontSize', 5.5, 'HorizontalAlignment', 'center');   text(ax2, k + 0.19, va(k) + 2, sprintf('%.1f', va(k)), 'FontSize', 5.5, 'HorizontalAlignment', 'center'); end
title(ax2, 'Detection, verification and patrol', 'FontSize', 7.5);   grid(ax2, 'on');
annotation(fig, 'textbox', [0 0.005 1 0.05], 'String', 'SIMULATED, medium scenario, 394 days, 10,004 intruders, same random numbers before and after.', 'FontSize', 5.5, 'EdgeColor', 'none', 'HorizontalAlignment', 'center');
exportgraphics(fig, fullfile(root, 'report', 'figures', 'stage9_before_after.png'), 'Resolution', 300);   close(fig);
