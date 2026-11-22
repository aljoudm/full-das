function R = respond_day(ev, obs, T, TP, alloc, A, P, s)
% RESPOND_DAY  Stage 6: DAS alarm -> cue the nearest ready drone (or a camera covering the point) -> verification -> patrol.
%
%   R = respond_day(ev, obs, T, TP, alloc, A, P, s)       ev from gen_day, obs from das_observe, alloc / A from get_allocation, s RandStream
%
%   For every event, in time order:
%     1. detected by the DAS? classify (ai_interface, stub): class_out. Threat = walking / running / vehicle / digging / climbing; a 'vehicle' within
%        d_road_nonthreat_m of a paved road or d_site_nonthreat_m of an existing camera site (checkpoint / interdiction point) is normal traffic (logged, no alarm).
%     2. alarm at t_alarm = t_start + T_win_s + t_proc_s + t_ai_s  (detection-to-alert time).
%     3. cue: a camera site within Cov_CCTV / 2 of the DAS position (verification after t_cam_s), else the ready drone with the shortest arrival time
%        (t_launch + distance / v_drone). A station with n drones has n explicit drone states; a drone that flew is busy for
%        2 x flight + T_mission_s + T_charge (so concurrent alarms can find no drone). The drone must reach the point within T_resp to count.
%     4. verification: the asset confirms a true intruder with Pc_asset (Pc_drone 0.89, Pc_CCTV 0.85) and clears a false alarm with the same probability.
%     5. patrol: only after a confirmed verification; the nearest free patrol (sites of the existing assets, round robin, ASSUMED) drives there at v_patrol x route factor.
%   Output table R (one row per event, same order as ev): class_out, conf, threat, alarm, t_alarm, asset ('camera'|'drone'|'none'), t_verif, verif_dt (alarm to asset on
%   scene), in_Tresp, confirmed, patrol_dt (alarm to patrol on scene), station, d_asset_m, zone.
v = P.v;   f = P.fd;   n = height(ev);   r = T.cells.ring;
R = table(strings(n, 1), zeros(n, 1), false(n, 1), false(n, 1), nan(n, 1), strings(n, 1), nan(n, 1), nan(n, 1), false(n, 1), false(n, 1), nan(n, 1), zeros(n, 1), nan(n, 1), ...
    'VariableNames', {'class_out', 'conf', 'threat', 'alarm', 't_alarm', 'asset', 't_verif', 'verif_dt', 'in_Tresp', 'confirmed', 'patrol_dt', 'station', 'd_asset_m'});
R.zone = T.cells.zoneCode(ev.cell);   R.zone(ev.cell == 0) = 0;
% --- classification of every DAS detection (stub, one place: ai_interface)
det = obs.detected;   truth = ev.type;   truth(ev.kind == "normal_vehicle") = "vehicle";
cl = ai_interface('classify_batch', truth(det), s);   R.class_out(det) = cl.class;   R.conf(det) = cl.confidence;
threatSet = ["walking" "running" "vehicle" "digging" "climbing"];
cam0 = A.sites([A.sites.in]);   dsite = min(hypot(r.x(ev.piece) - [cam0.x], r.y(ev.piece) - [cam0.y]), [], 2);
roadVeh = R.class_out == "vehicle" & (TP.d_road(ev.piece) < f.d_road_nonthreat_m | dsite < f.d_site_nonthreat_m);   % normal traffic: logged, no alarm
R.threat = det & ismember(R.class_out, threatSet) & ~roadVeh;
t_alert = P.fd.T_win_s + f.t_proc_s + f.t_ai_s;   R.alarm = R.threat;   R.t_alarm(R.threat) = ev.t_start(R.threat) + t_alert;
% --- assets
cam = A.sites([A.sites.in]);   cx = [cam.x]';   cy = [cam.y]';   halfCov = v.Cov_CCTV_m / 2;
sx = alloc.drones.station_xy(:, 1);   sy = alloc.drones.station_xy(:, 2);   nDr = alloc.drones.n(:);   free = arrayfun(@(k) zeros(1, k), nDr, 'UniformOutput', false);   % time each drone is free again
nP = alloc.scenario.N_patrol;   [px, py] = patrol_sites(A, nP);   pfree = zeros(nP, 1);
Pc_dr = v.Pc_drone;   Pc_cc = v.Pc_CCTV;
[~, ord] = sort(ev.t_start);
for k = ord(:)'
    if ~R.alarm(k), continue; end
    ta = R.t_alarm(k);   xh = obs.x_hat(k);   yh = obs.y_hat(k);
    dcam = min(hypot(cx - xh, cy - yh));
    if dcam <= halfCov
        R.asset(k) = "camera";   R.t_verif(k) = ta + f.t_cam_s;   R.d_asset_m(k) = dcam;   Pc = Pc_cc;
    else
        best = inf;   bs = 0;
        for st = 1:numel(sx)
            if ~any(free{st} <= ta), continue; end
            tt = v.T_launch_s + hypot(sx(st) - xh, sy(st) - yh) / v.v_drone_ms;
            if tt < best, best = tt;   bs = st; end
        end
        if bs > 0
            j = find(free{bs} <= ta, 1);   dd = hypot(sx(bs) - xh, sy(bs) - yh);
            free{bs}(j) = ta + best + dd / v.v_drone_ms + f.T_mission_s + v.T_charge_min * 60;
            R.asset(k) = "drone";   R.t_verif(k) = ta + best;   R.station(k) = bs;   R.d_asset_m(k) = dd;   Pc = Pc_dr;
        else
            R.asset(k) = "none";   continue;
        end
    end
    R.verif_dt(k) = R.t_verif(k) - ta;   R.in_Tresp(k) = R.verif_dt(k) <= v.T_resp_s;
    if ev.is_intrusion(k), R.confirmed(k) = rand(s) <= Pc; else, R.confirmed(k) = rand(s) > Pc; end
    if R.confirmed(k)
        d = hypot(px - xh, py - yh);   d(pfree > R.t_verif(k)) = inf;   [dm, ip] = min(d);
        if isfinite(dm)
            tp = R.t_verif(k) + dm * f.k_road_patrol / f.v_patrol;   R.patrol_dt(k) = tp - ta;   pfree(ip) = tp + f.T_patrol_busy_s;
        end
    end
end
R.asset(R.asset == "") = "none";
end

function [px, py] = patrol_sites(A, n)
% patrol home positions: the checkpoints first, then interdiction points, round robin (existing assets; positions ASSUMED)
cs = A.sites([A.sites.in]);   isCp = string({cs.kind}) == "checkpoint";   cs = [cs(isCp), cs(~isCp)];
idx = mod((0:n-1), numel(cs)) + 1;   px = [cs(idx).x]';   py = [cs(idx).y]';
end
