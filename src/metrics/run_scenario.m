function [E, FA] = run_scenario(P, T, TP, lib, scenario, minIntruders, seed, mode, pGroup)
% RUN_SCENARIO  Simulate days of one allocation scenario through the whole chain until at least minIntruders real intruder EVENTS have occurred.
%
%   [E, FA] = run_scenario(P, T, TP, lib, 'medium', 10000, 8080, 'uniform', 0)
%   mode      classifier stub mode: 'uniform' (BASE, Pc from the literature, ASSUMED) | 'confusion_counts' (Brno matrix, SENSITIVITY only)
%   pGroup    share of intrusion events that are groups of 2 to 5 people (base 0; sensitivity 0.25, 0.5)
%   COMMON RANDOM NUMBERS: day d of every scenario uses the same generator streams (seed, d): the same events, detections and classifications in every scenario, so differences between
%   scenarios come from the assets only. (Streams: one for events and DAS, one for the response; the response draws a fixed block of numbers per event.)
%   E         table, one row per REAL intruder event; FA struct, one row per day (false alarms before / after verification).
setenv('AI_CLASSIFIER_MODE', mode);   cleanup = onCleanup(@() setenv('AI_CLASSIFIER_MODE', ''));
[al, ~, A] = get_allocation(P, scenario);   G = gen_setup(T, TP, P, A);
Es = {};   fa = zeros(0, 5);   n = 0;   d = 0;
while n < minIntruders || d < 20
    d = d + 1;   sG = RandStream('Threefry', 'Seed', seed * 100000 + d);   sR = RandStream('Threefry', 'Seed', seed * 100000 + d + 50000);
    ev = gen_day(T, TP, G, P, sG, d, struct('p_group', pGroup));   ob = das_observe(ev, T, al, lib, sG);   R = respond_day(ev, ob, T, TP, al, A, P, sR);   el = height_eligibility(ev, ob, P);
    i = ev.is_intrusion;   f = R.alarm & ~i;
    fa(d, :) = [nnz(f & ~R.site_routed), nnz(f & R.site_routed), nnz(f & R.confirmed & ~isnan(R.patrol_dt)), nnz(R.alarm), nnz(~i)];
    Es{d, 1} = table(repmat(d, nnz(i), 1), ev.type(i), R.zone(i), ev.piece(i), ev.t_start(i), ob.detected(i), R.class_out(i), R.threat(i), R.site_routed(i), R.asset(i), R.t_alarm(i), R.t_verif(i), R.verif_dt(i), R.in_Tresp(i), R.confirmed(i), R.patrol_dt(i), el.ok(i), ev.along(i), ev.group_size(i), R.patrol_needed(i), R.patrol_sent(i), ob.dist_m(i), ...
        'VariableNames', {'day', 'type', 'zone', 'piece', 't_start', 'detected', 'class_out', 'threat', 'site_routed', 'asset', 't_alarm', 't_verif', 'verif_dt', 'in_Tresp', 'confirmed', 'patrol_dt', 'height_ok', 'along', 'group_size', 'patrol_needed', 'patrol_sent', 'dist_m'}); %#ok<AGROW>
    n = n + nnz(i);
end
E = vertcat(Es{:});   FA = struct('day', (1:d)', 'fa_cued', fa(:, 1), 'fa_site', fa(:, 2), 'fa_patrol', fa(:, 3), 'alarms', fa(:, 4), 'non_intrusion_events', fa(:, 5), 'scenario', scenario, 'mode', mode, 'nDays', d, 'pGroup', pGroup);
end
