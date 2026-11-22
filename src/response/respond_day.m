function R = respond_day(ev, obs, T, TP, alloc, A, P, s)
% RESPOND_DAY  Stage 6: DAS alarm -> cue the nearest ready drone (or a camera covering the point) -> verification -> patrol.
%
%   R = respond_day(ev, obs, T, TP, alloc, A, P, s)       ev from gen_day, obs from das_observe, alloc / A from get_allocation, s RandStream
%
%   For every event, in time order:
%     1. detected by the DAS? classify (ai_interface, stub): class_out. Threat = walking / running / vehicle / digging / climbing; a 'vehicle' within
%        d_road_nonthreat_m of a paved road or d_site_nonthreat_m of an existing camera site (checkpoint / interdiction point) is probably normal traffic: the alert is NOT
%        cancelled, it is routed with LOW priority to the site guard and its existing cameras (asset 'site', verification after t_cam_s) and never uses a drone.
%     2. alarm at t_alarm = t_start + T_win_s + t_proc_s + t_ai_s  (detection-to-alert time).
%     3. cue: a camera site within Cov_CCTV / 2 of the DAS position (verification after t_cam_s), else the ready drone with the shortest arrival time
%        (t_launch + distance / v_drone). A station with n drones has n explicit drone states; a drone that flew is busy for
%        2 x flight + T_mission_s + T_charge (so concurrent alarms can find no drone). The drone must reach the point within T_resp to count.
%     4. verification: the asset confirms a true intruder with Pc_asset (Pc_drone 0.89, Pc_CCTV 0.85) and clears a false alarm with the same probability.
%     5. patrol: only after a confirmed verification; the nearest free patrol (sites of the existing assets, round robin, ASSUMED) drives there at v_patrol x route factor.
%   Output table R (one row per event, same order as ev): class_out, conf, threat, alarm, t_alarm, asset ('camera'|'drone'|'none'), t_verif, verif_dt (alarm to asset on
%   scene), in_Tresp, confirmed, patrol_dt (alarm to patrol on scene), station, d_asset_m, zone.
v = P.v;   f = P.fd;   n = height(ev);   r = T.cells.ring;
R = table(strings(n, 1), zeros(n, 1), false(n, 1), false(n, 1), false(n, 1), nan(n, 1), strings(n, 1), nan(n, 1), nan(n, 1), false(n, 1), false(n, 1), nan(n, 1), zeros(n, 1), nan(n, 1), ...
    'VariableNames', {'class_out', 'conf', 'threat', 'site_routed', 'alarm', 't_alarm', 'asset', 't_verif', 'verif_dt', 'in_Tresp', 'confirmed', 'patrol_dt', 'station', 'd_asset_m'});
R.zone = T.cells.zoneCode(ev.cell);   R.zone(ev.cell == 0) = 0;
% --- classification of every DAS detection (stub, one place: ai_interface)
det = obs.detected;   truth = ev.type;   truth(ev.kind == "normal_vehicle") = "vehicle";
cl = ai_interface('classify_batch', truth(det), s);   R.class_out(det) = cl.class;   R.conf(det) = cl.confidence;
threatSet = ["walking" "running" "vehicle" "digging" "climbing"];
cam0 = A.sites([A.sites.in]);   dsite = min(hypot(r.x(ev.piece) - [cam0.x], r.y(ev.piece) - [cam0.y]), [], 2);
roadVeh = R.class_out == "vehicle" & (TP.d_road(ev.piece) < f.d_road_nonthreat_m | dsite < f.d_site_nonthreat_m);   % normal traffic: logged, no alarm
R.threat = det & ismember(R.class_out, threatSet);   R.site_routed = R.threat & roadVeh;      % low priority: goes to the site guard and its cameras, not cancelled
t_alert = P.fd.T_win_s + f.t_proc_s + f.t_ai_s;   R.alarm = R.threat;   R.t_alarm(R.threat) = ev.t_start(R.threat) + t_alert;
% --- assets
cam = A.sites([A.sites.in]);   cx = [cam.x]';   cy = [cam.y]';   halfCov = v.Cov_CCTV_m / 2;
sx = alloc.drones.station_xy(:, 1);   sy = alloc.drones.station_xy(:, 2);   nDr = alloc.drones.n(:);   free = arrayfun(@(k) zeros(1, k), nDr, 'UniformOutput', false);   % time each drone is free again
nP = alloc.scenario.N_patrol;   [px, py] = patrol_sites(A, nP);   pfree = zeros(nP, 1);
Pc_dr = v.Pc_drone;   Pc_cc = v.Pc_CCTV;
dualMode = 0;   if isfield(f, 'dual_verify'), dualMode = f.dual_verify; end      % 0 single check; 1 dual everywhere; 2 dual in Neutral and Cold only, single in Hot
[~, ord] = sort(ev.t_start);
for k = ord(:)'
    if ~R.alarm(k), continue; end
    ta = R.t_alarm(k);   xh = obs.x_hat(k);   yh = obs.y_hat(k);
    dcam = min(hypot(cx - xh, cy - yh));   wantDual = ~R.site_routed(k) && (dualMode == 1 || (dualMode == 2 && R.zone(k) ~= 3));
    tFirst = NaN;
    if R.site_routed(k)
        R.asset(k) = "site";   tFirst = f.t_cam_s;   Pc = Pc_cc;                              % site guard + the site's existing cameras
    elseif dcam <= halfCov
        R.asset(k) = "camera";   tFirst = f.t_cam_s;   R.d_asset_m(k) = dcam;   Pc = Pc_cc;
    else
        [best, bs] = pick_drone(free, ta, sx, sy, xh, yh, v);
        if bs == 0, R.asset(k) = "none";   continue; end
        [free, dd] = reserve(free, bs, ta, best, sx, sy, xh, yh, v, f);
        R.asset(k) = "drone";   tFirst = best;   R.station(k) = bs;   R.d_asset_m(k) = dd;   Pc = Pc_dr;
    end
    second = false;   tSecond = 0;
    if wantDual                                                      % second INDEPENDENT check: a drone (after a camera) or another drone (after a drone)
        [best2, bs2] = pick_drone(free, ta, sx, sy, xh, yh, v);
        if bs2 > 0, [free, ~] = reserve(free, bs2, ta, best2, sx, sy, xh, yh, v, f);   second = true;   tSecond = best2;
        else, R.asset(k) = R.asset(k) + " (single: no second drone ready)"; end
    end
    R.t_verif(k) = ta + max(tFirst, tSecond);   R.verif_dt(k) = R.t_verif(k) - ta;   R.in_Tresp(k) = R.verif_dt(k) <= v.T_resp_s;
    if ev.is_intrusion(k), c1 = rand(s) <= Pc;
    elseif R.site_routed(k), c1 = rand(s) > f.p_site_clear;           % authorized traffic at a guarded site: cleared with p_site_clear (PLACEHOLDER)
    else, c1 = rand(s) > Pc; end
    if second && c1 && ev.is_intrusion(k), c1 = rand(s) <= Pc_dr;
    elseif second && c1, c1 = rand(s) > Pc_dr; end                    % both checks must confirm
    R.confirmed(k) = c1;
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

function [best, bs] = pick_drone(free, ta, sx, sy, xh, yh, v)
% ready drone with the shortest arrival time (launch + flight); bs = 0 if no station has a ready drone
best = inf;   bs = 0;
for st = 1:numel(sx)
    if ~any(free{st} <= ta), continue; end
    tt = v.T_launch_s + hypot(sx(st) - xh, sy(st) - yh) / v.v_drone_ms;
    if tt < best, best = tt;   bs = st; end
end
end

function [free, dd] = reserve(free, bs, ta, best, sx, sy, xh, yh, v, f)
% the drone is busy for the flight out and back, the mission and the full charge
j = find(free{bs} <= ta, 1);   dd = hypot(sx(bs) - xh, sy(bs) - yh);
free{bs}(j) = ta + best + dd / v.v_drone_ms + f.T_mission_s + v.T_charge_min * 60;
end
