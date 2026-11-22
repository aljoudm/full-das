function [E, FA] = run_scenario(P, T, TP, lib, scenario, nD, seed, mode)
% RUN_SCENARIO  Simulate nD days of one allocation scenario through the whole chain and keep what the metrics need.
%
%   [E, FA] = run_scenario(P, T, TP, lib, 'medium', 60, 8080, 'uniform')
%   mode      classifier stub mode: 'uniform' (BASE, Pc from the literature, ASSUMED) | 'confusion_counts' (Brno matrix, SENSITIVITY only)
%   E         table, one row per REAL intruder: day, type, zone, piece, t_start, detected, class_out, threat, site_routed, asset, t_alarm, t_verif, verif_dt, in_Tresp, confirmed, patrol_dt, height_ok, along
%   FA        struct, one row per day: false alarms before verification (drone/camera-cued, site-routed) and after (reaching a patrol), alarms
%   Chain per day: gen_day -> das_observe (window library of the frozen engine) -> classifier (ai_interface) -> respond_day (cue, verification, patrol) -> height_eligibility.
setenv('AI_CLASSIFIER_MODE', mode);   cleanup = onCleanup(@() setenv('AI_CLASSIFIER_MODE', ''));
[al, ~, A] = get_allocation(P, scenario);   G = gen_setup(T, TP, P, A);   s = RandStream('Threefry', 'Seed', seed);
Es = cell(nD, 1);   fa = zeros(nD, 5);
for d = 1:nD
    ev = gen_day(T, TP, G, P, s, d);   ob = das_observe(ev, T, al, lib, s);   R = respond_day(ev, ob, T, TP, al, A, P, s);   el = height_eligibility(ev, ob, P);
    i = ev.is_intrusion;   f = R.alarm & ~i;
    fa(d, :) = [nnz(f & ~R.site_routed), nnz(f & R.site_routed), nnz(f & R.confirmed & ~isnan(R.patrol_dt)), nnz(R.alarm), nnz(~i)];
    Es{d} = table(repmat(d, nnz(i), 1), ev.type(i), R.zone(i), ev.piece(i), ev.t_start(i), ob.detected(i), R.class_out(i), R.threat(i), R.site_routed(i), R.asset(i), R.t_alarm(i), R.t_verif(i), R.verif_dt(i), R.in_Tresp(i), R.confirmed(i), R.patrol_dt(i), el.ok(i), ev.along(i), ...
        'VariableNames', {'day', 'type', 'zone', 'piece', 't_start', 'detected', 'class_out', 'threat', 'site_routed', 'asset', 't_alarm', 't_verif', 'verif_dt', 'in_Tresp', 'confirmed', 'patrol_dt', 'height_ok', 'along'});
end
E = vertcat(Es{:});   FA = struct('day', (1:nD)', 'fa_cued', fa(:, 1), 'fa_site', fa(:, 2), 'fa_patrol', fa(:, 3), 'alarms', fa(:, 4), 'non_intrusion_events', fa(:, 5), 'scenario', scenario, 'mode', mode, 'nDays', nD);
end
