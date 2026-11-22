function M = compute_metrics(E, FA, T, P)
% COMPUTE_METRICS  System-level metrics of one scenario run, each with a 95 % bootstrap over DAYS (days are the independent units; 2000 resamples).
%
%   M = compute_metrics(E, FA, T, P)       E, FA from run_scenario
%   M.rows: table (metric, value, lo, hi, n_num, n_den, unit, source)
%   Definitions (over REAL intruders unless stated):
%     Pd              detected by the DAS (statistic above the threshold of the window library)
%     Pc_cond         class_out equals the true type, GIVEN detection
%     Pd_x_Pc         detected AND classified correctly (= Pd x Pc_cond by construction)
%     alarm_raised    detected and classified as a threat (a vehicle near a road or checkpoint goes to the site guard: still an alert)
%     verified_Tresp  an asset (camera, drone or site guard) on scene within T_resp of the alarm; verified_Tresp_hot the same over Hot-cell intruders
%     verified_of_alarms  verified within T_resp among the intruders that raised an alarm
%     patrol_reached  a patrol dispatched after a confirmed verification
%     height_measurable   conditions of the height method met (walking, parallel to the fibre within 3 m, >= 8 steps, SNR >= 12 dB, detected)
%     fa_cued / fa_site / fa_before_all   false alarms before verification per km per day (drone- or camera-cued, routed to site guards, all)
%     fa_patrol       false alarms that reach a patrol (after verification) per km per day; target P.fd.FAR_per_km_day
nD = FA.nDays;   km = T.cells.ring.L / 1e3;   days = E.day;   rs = RandStream('Threefry', 'Seed', 123);   B = 2000;   n = height(E);
det = E.detected;   corr = det & (E.class_out == E.type);   hot = E.zone == 3;   one = true(n, 1);
hasAsset = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none");   ver = hasAsset & E.in_Tresp;   pat = ~isnan(E.patrol_dt);
defs = {'Pd', det, one; 'Pc_cond', corr, det; 'Pd_x_Pc', corr, one; 'alarm_raised', E.threat, one; 'verified_Tresp', ver, one; 'verified_Tresp_hot', ver & hot, hot; ...
        'verified_of_alarms', ver, E.threat; 'patrol_reached', pat, one; 'patrol_reached_of_alarms', pat, E.threat; 'height_measurable', E.height_ok, one; 'height_measurable_of_walkers', E.height_ok, E.type == "walking"};
dayIdx = arrayfun(@(d) find(days == d), 1:nD, 'UniformOutput', false);
rows = cell(0, 8);
for k = 1:size(defs, 1)
    num = defs{k, 2};   den = defs{k, 3};   val = nnz(num) / max(nnz(den), 1);
    ci = bootstat(@(ii) nnz(num(ii)) / max(nnz(den(ii)), 1), dayIdx, nD, B, rs);
    rows(end+1, :) = {defs{k, 1}, val, ci(1), ci(2), nnz(num), nnz(den), '-', 'run_scenario'}; %#ok<AGROW>
end
ci = bootstat(@(ii) median(E.verif_dt(ii(hasAsset(ii))), 'omitnan'), dayIdx, nD, B, rs);   rows(end+1, :) = {'median_verification_s', median(E.verif_dt(hasAsset), 'omitnan'), ci(1), ci(2), nnz(hasAsset), nnz(hasAsset), 's', 'run_scenario'};
ci = bootstat(@(ii) median(E.patrol_dt(ii(pat(ii))), 'omitnan'), dayIdx, nD, B, rs);   rows(end+1, :) = {'median_alarm_to_patrol_s', median(E.patrol_dt(pat), 'omitnan'), ci(1), ci(2), nnz(pat), nnz(pat), 's', 'run_scenario'};
series = {'fa_cued', FA.fa_cued; 'fa_site', FA.fa_site; 'fa_before_all', FA.fa_cued + FA.fa_site; 'fa_patrol', FA.fa_patrol};
for k = 1:size(series, 1)
    x = series{k, 2};   bs = zeros(B, 1);
    for b = 1:B, ii = randi(rs, nD, nD, 1);   bs(b) = sum(x(ii)) / nD / km; end
    rows(end+1, :) = {series{k, 1}, sum(x) / nD / km, prctile(bs, 2.5), prctile(bs, 97.5), sum(x), nD, 'alarms per km per day', 'run_scenario'}; %#ok<AGROW>
end
M.rows = cell2table(rows, 'VariableNames', {'metric', 'value', 'lo', 'hi', 'n_num', 'n_den', 'unit', 'source'});
M.intruders = n;   M.days = nD;   M.scenario = FA.scenario;   M.mode = FA.mode;   M.FAR_target = P.fd.FAR_per_km_day;
tp = unique(E.type);   M.types = tp;   M.Pd_by_type = arrayfun(@(t) mean(det(E.type == t)), tp);   M.Pc_by_type = arrayfun(@(t) mean(corr(E.type == t & det)), tp);
end

function ci = bootstat(f, dayIdx, nD, B, rs)
x = zeros(B, 1);
for b = 1:B
    pick = randi(rs, nD, nD, 1);   ii = vertcat(dayIdx{pick});   x(b) = f(ii);
end
ci = prctile(x, [2.5 97.5]);
end
