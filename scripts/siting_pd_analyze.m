% SITING_PD_ANALYZE  Assemble the Pd(d) data (integer km 0-25 with 80 windows per type from results/pd_curve_raw.mat; 12-20 km every 0.5 km with 1,000 windows per type from
% results/siting/pd_chunks/), fit the monotone (isotonic, non-increasing) curve, bootstrap its 95 % limits and apply the d* RULE fixed in the table (row siting_dstar_rule) BEFORE the dense run:
%   d* = farthest distance up to which the LOWER 95 % limit of the monotone Pd(d) curve stays >= Pd_DAS.
% Limits: 2000 bootstrap replicates; every replicate redraws the number of detections of every (distance, type) from Binomial(n, observed rate) (= window bootstrap), weights the types as in
% Stage 9, fits the weighted isotonic curve, and the 2.5 / 97.5 percentiles of the fitted curves are the limits. Writes results/siting/pd_curve.csv / .png, pd_model.mat (per-type isotonic Pd(d),
% used by das_observe: ONE model for the optimization and the simulation) and d_star.json (with N_min and the N-vs-d* range).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();
types = {'walking', 'running', 'vehicle', 'digging', 'climbing'};   nT = numel(types);   od = fullfile(root, 'results', 'siting');
R = load(fullfile(root, 'results', 'pd_curve_raw.mat'));   thr = R.thr;   dd = 0:25;   K = zeros(numel(dd), nT);   Nn = zeros(numel(dd), nT);
for j = 1:numel(dd), for t = 1:nT, m = R.ti == t & R.di == j;   K(j, t) = sum(R.S(m) > thr);   Nn(j, t) = nnz(m); end, end
ch = dir(fullfile(od, 'pd_chunks', 'd_*.mat'));   dk = [12 12.5 13 14 14.25 14.5 14.75 15:20];   have = false(size(dk));
for c = 1:numel(ch)
    X = load(fullfile(ch(c).folder, ch(c).name));   dkm = str2double(regexp(ch(c).name, '\d+\.\d+', 'match', 'once'));   assert(abs(X.thr - thr) < 1e-9, 'threshold differs');
    k = (X.S > thr);   kk = sum(k, 1);   nn = size(k, 1) * ones(1, nT);   j = find(abs(dd - dkm) < 1e-9);
    if ~isempty(j), K(j, :) = kk;   Nn(j, :) = nn; else, dd(end+1) = dkm;   K(end+1, :) = kk;   Nn(end+1, :) = nn; end %#ok<AGROW>
    have(abs(dk - dkm) < 1e-9) = true;
end
[dd, o] = sort(dd);   K = K(o, :);   Nn = Nn(o, :);   fprintf('dense chunks present for %d of %d distances (12-20 km, 0.5 km)\n', nnz(have), numel(dk));
S9 = load(fullfile(root, 'results', 'stage9', 'run_medium.mat'));   share = arrayfun(@(t) mean(S9.E.type == t), string(types));   share = share / sum(share);
Pd = K ./ Nn;   pm = Pd * share(:);   w = sum(Nn, 2);   Pt = P.v.Pd_DAS;
fit = pav_nonincr(pm, w);   Ptype = zeros(size(Pd));   for t = 1:nT, Ptype(:, t) = pav_nonincr(Pd(:, t), Nn(:, t)); end
B = 2000;   rng(8888, 'twister');   F = zeros(B, numel(dd));
for b = 1:B
    kb = binornd(Nn, min(max(Pd, 0), 1));   F(b, :) = pav_nonincr((kb ./ Nn) * share(:), w)';
end
lo = prctile(F, 2.5, 1)';   hi = prctile(F, 97.5, 1)';
% ---- per-type monotone fits and lower limits (INFORMATION ONLY: the adopted rule is the type-mix Pd; the weakest type is shown beside it)
LOt = zeros(numel(dd), nT);   for t = 1:nT, Ft = zeros(B, numel(dd));   for b = 1:B, Ft(b, :) = pav_nonincr(binornd(Nn(:, t), min(max(Pd(:, t), 0), 1)) ./ Nn(:, t), Nn(:, t))';   end,   LOt(:, t) = prctile(Ft, 2.5, 1)';   end
lo_weak = min(LOt, [], 2);   iw = find(lo_weak < Pt, 1);   if isempty(iw), dstar_weak = dd(end); else, dstar_weak = dd(iw - 1); end
sel = ismember(dd, [14 14.25 14.5 14.75 15]);   [~, wk] = min(Ptype(sel, :), [], 2);   tw = table(dd(sel)', pm(sel), fit(sel), lo(sel), string(types(wk))', min(Ptype(sel, :), [], 2), lo_weak(sel), 'VariableNames', {'distance_km', 'Pd_mix_observed', 'Pd_mix_fit', 'Pd_mix_lower95_RULE', 'weakest_type', 'Pd_weakest_fit', 'Pd_weakest_lower95'});
for t = 1:nT, tw.(['fit_' types{t}]) = Ptype(sel, t);   tw.(['lower95_' types{t}]) = LOt(sel, t); end
tw.n_per_type = Nn(sel, 1);   writetable(tw, fullfile(od, 'dstar_rule_table.csv'));   disp(tw(:, 1:7));
i1 = find(lo < Pt, 1);   if isempty(i1), dstar = dd(end); else, dstar = dd(i1 - 1); end                       % the rule: the farthest distance with lower 95 % limit >= Pd_DAS
i2 = find(fit < Pt, 1);   dstar_pt = dd(max(i2 - 1, 1));   i3 = find(hi < Pt, 1);   dstar_hi = dd(max(i3 - 1, 1));
ranges = [5 10 20 70 100];   opt = ranges(find(ranges >= dstar, 1));   L = P.v.L_boundary_m / 1e3;   Nmin = ceil(L / (2 * dstar));
T = table(dd(:), pm, lo, hi, fit, w, 'VariableNames', {'distance_km', 'Pd_mix', 'Pd_fit_lower95', 'Pd_fit_upper95', 'Pd_fit', 'n_windows_total'});   T = [T array2table(Pd, 'VariableNames', strcat('Pd_', types))];
T.label = repmat("SIMULATED", height(T), 1);   writetable(T, fullfile(od, 'pd_curve.csv'));
pd_model = struct('dist_km', dd(:), 'types', {types}, 'pd', Ptype, 'mix_fit', fit, 'lower95', lo, 'upper95', hi, 'share', share, 'n', Nn, 'k', K, 'd_star_km', dstar, 'rule', 'lower 95 % limit of monotone Pd(d) >= Pd_DAS', 'built', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
save(fullfile(od, 'pd_model.mat'), 'pd_model');
json = struct('Pd_target', Pt, 'rule', 'd* = farthest distance with the LOWER 95 % limit of the monotone Pd(d) >= Pd_DAS (fixed before the dense run)', 'd_star_km', dstar, 'd_star_km_weakest_type_lower_limit_INFO', dstar_weak, 'd_star_km_point_estimate_rule', dstar_pt, 'd_star_km_upper_limit_rule', dstar_hi, ...
    'febus_range_option_km', opt, 'N_min', Nmin, 'L_boundary_km', L, 'N_equals_5_for_d_star_between_km', [L / 10, L / 8], 'dense_windows_per_type_per_distance', '1000 at 12, 12.5, 13 km; 400 at 14-20 km', 'dense_grid_km', '12, 12.5, 13, 14..20', 'coarse_windows_per_type', 80, 'type_share', cell2struct(num2cell(share), types, 2));
fid = fopen(fullfile(od, 'd_star.json'), 'w');   fprintf(fid, '%s', jsonencode(json, 'PrettyPrint', true));   fclose(fid);
fprintf('d* (lower-95-limit rule, type MIX) = %.2f km | weakest-type rule (info) %.2f km | point-estimate rule %.2f km | upper-limit rule %.1f km | FEBUS option %d km | N_min = ceil(%.2f / %.1f) = %d\n', dstar, dstar_weak, dstar_pt, dstar_hi, opt, L, 2 * dstar, Nmin);
fig = figure('Color', 'w', 'Position', [60 60 1000 520]);   ax = axes(fig);   hold(ax, 'on');   fill(ax, [dd(:); flipud(dd(:))], 100 * [lo; flipud(hi)], [0.75 0.85 0.95], 'EdgeColor', 'none', 'FaceAlpha', 0.7);
plot(ax, dd, 100 * pm, 'o', 'Color', [0.05 0.3 0.7], 'MarkerSize', 4);   plot(ax, dd, 100 * fit, 'r-', 'LineWidth', 1.4);   plot(ax, dd, 100 * lo, 'b--', 'LineWidth', 1);   yline(ax, 100 * Pt, 'k--', sprintf('Pd_{DAS} = %.3f', Pt));   xline(ax, dstar, 'g-', sprintf('d* = %.1f km', dstar), 'LineWidth', 1.5);
xlabel(ax, 'total optical distance from the interrogator d [km]');   ylabel(ax, 'Pd [%]');   ylim(ax, [75 101]);   grid(ax, 'on');   legend(ax, {'95 % limits of the monotone fit', 'observed Pd (type mix)', 'monotone fit', 'lower 95 % limit'}, 'Location', 'southwest');
title(ax, 'Detection probability vs optical distance (SIMULATED, FEBUS A1-NEO, 0.2 dB/km; 80 windows per type at 0-11 and 21-25 km; 400-1,000 per type at 12-20 km)', 'FontSize', 8);
exportgraphics(fig, fullfile(od, 'pd_curve.png'), 'Resolution', 200);   close(fig);

function y = pav_nonincr(y, w)
% weighted pool-adjacent-violators for a NON-INCREASING sequence
y = y(:);   w = w(:);   n = numel(y);   v = y;   ww = w;   cnt = ones(n, 1);   idx = 1;   vals = zeros(n, 1);   wts = zeros(n, 1);   cn = zeros(n, 1);   m = 0;
for i = 1:n
    m = m + 1;   vals(m) = v(i);   wts(m) = ww(i);   cn(m) = 1;
    while m > 1 && vals(m - 1) < vals(m) - 1e-15
        vals(m - 1) = (vals(m - 1) * wts(m - 1) + vals(m) * wts(m)) / (wts(m - 1) + wts(m));   wts(m - 1) = wts(m - 1) + wts(m);   cn(m - 1) = cn(m - 1) + cn(m);   m = m - 1;
    end
end
y = repelem(vals(1:m), cn(1:m));
end
