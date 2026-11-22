% STAGE9_INCIDENT_GIF  Animation (GIF) of ONE simulated incident on the 3D digital twin: an intruder crosses the fibre in a Hot stretch, the DAS alarm, the drone flies from its station,
% verifies, a patrol drives to the point. SIMULATED. The day is re-generated with the same seeds as Stage 9 (common random numbers), so it is a real event of the Monte Carlo run.
% Output: report/figures/incident_3d.gif (about 80 frames).  Times: alarm = T_win + t_proc + t_ai; drone launch T_launch; drone speed v_drone; patrol speed v_patrol x route factor.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   addpath(fullfile(root, 'third_party', 'dasmap_viz'));
P = load_params_fd();   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);   [al, ~, A] = get_allocation(P, 'medium');   G = gen_setup(T, TP, P, A);   v = P.v;   f = P.fd;   r = T.cells.ring;
S = load(fullfile(root, 'results', 'stage9', 'run_medium.mat'));   E = S.E;   ext = [39.84 39.99 21.47 21.58];   ll = T.ring_ll(E.piece, :);
inb = ll(:, 2) >= ext(1) + 0.01 & ll(:, 2) <= ext(2) - 0.01 & ll(:, 1) >= ext(3) + 0.01 & ll(:, 1) <= ext(4) - 0.01;
cand = find(E.zone == 3 & startsWith(E.asset, "drone") & ~isnan(E.patrol_dt) & E.in_Tresp & E.group_size == 1 & E.type == "walking" & inb & E.day < 60, 1);
k0 = cand(1);   d = E.day(k0);   seed = 9090;
sG = RandStream('Threefry', 'Seed', seed * 100000 + d);   sR = RandStream('Threefry', 'Seed', seed * 100000 + d + 50000);
ev = gen_day(T, TP, G, P, sG, d, struct('p_group', 0));   ob = das_observe(ev, T, al, lib, sG);   R = respond_day(ev, ob, T, TP, al, A, P, sR);
kk = find(abs(ev.t_start - E.t_start(k0)) < 1e-6 & ev.piece == E.piece(k0), 1);   assert(~isempty(kk) && R.asset(kk) == "drone", 'incident not reproduced');
path = ev.path{kk};   t0 = ev.t_start(kk);   path(:, 1) = path(:, 1) - t0;                                   % seconds relative to the crossing of the fibre
ta = R.t_alarm(kk) - t0;   tl = ta + v.T_launch_s;   tv = R.t_verif(kk) - t0;   tp = ta + R.patrol_dt(kk);
st = al.drones.station_xy(R.station(kk), :);   xh = ob.x_hat(kk);   yh = ob.y_hat(kk);                         % station and DAS-estimated position (local metres)
cs = A.sites([A.sites.in]);   isCp = string({cs.kind}) == "checkpoint";   cs = [cs(isCp), cs(~isCp)];   np = al.scenario.N_patrol;   hx = [cs(mod(0:np-1, numel(cs)) + 1).x];   hy = [cs(mod(0:np-1, numel(cs)) + 1).y];
[~, ip] = min(hypot(hx - xh, hy - yh));   px0 = hx(ip);   py0 = hy(ip);   tpd = tp - R.patrol_dt(kk) + (R.t_verif(kk) - R.t_alarm(kk));   % patrol departs when the verification confirms
fprintf('incident: day %d, %s, verification after %.0f s, patrol on scene %.0f s after the alarm\n', d, ev.type(kk), R.verif_dt(kk), R.patrol_dt(kk));
% ---- scene (zoom view, no static intruders)
cam = twin3d_camera('overview');   lat0 = mean([min(T.dem.lat) max(T.dem.lat)]);   lon0 = mean([min(T.dem.lon) max(T.dem.lon)]);   kx = 111.195 * cosd(lat0);   ky = 111.195;
c = [r.lat0 + yh / r.ky, r.lon0 + xh / r.kx];   Zc = interp2(T.dem.lon, T.dem.lat, double(T.dem.Z), c(2), c(1)) / 1000 * cam.VE;
cz = twin3d_camera('zoom', [(c(2) - lon0) * kx, (c(1) - lat0) * ky, Zc]);   cz.dist = 9;   cz.az = 215;   cz.el = 38;
zf = fullfile(root, 'data', 'imagery', 'esri_zoom_hot_nw.jpg');
H = draw_twin3d(T, P, al, A, [], cz, 'Size', [12 8.5], 'ZoomExtent', ext, 'MeshExtent', ext, 'Stride', 1, 'Imagery', zf, 'LegendPos', 'bl', 'Landmarks', false);
ax = H.ax;   toLL = @(x, y) deal(r.lon0 + x / r.kx, r.lat0 + y / r.ky);   P3 = @(x, y, up) [H.tx(r.lon0 + x / r.kx), H.ty(r.lat0 + y / r.ky), H.zAt(r.lon0 + x / r.kx, r.lat0 + y / r.ky) + up];
hI = plot3(ax, nan, nan, nan, 'o', 'MarkerFaceColor', [1 0.1 0.1], 'MarkerEdgeColor', 'k', 'MarkerSize', 9);   hTr = plot3(ax, nan, nan, nan, '-', 'Color', [1 0.4 0.4], 'LineWidth', 1.6);
hD = plot3(ax, nan, nan, nan, '^', 'MarkerFaceColor', [0.65 0.3 1], 'MarkerEdgeColor', 'w', 'MarkerSize', 11);   hP = plot3(ax, nan, nan, nan, 's', 'MarkerFaceColor', [0.2 0.5 1], 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
hA = plot3(ax, nan, nan, nan, 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', [1 0.8 0], 'LineWidth', 2.5, 'MarkerSize', 22);
ov = axes(H.fig, 'Position', [0 0 1 1], 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1]);   hT = text(ov, 0.5, 0.955, '', 'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1 0.85]);
text(ov, 0.5, 0.035, 'SIMULATED incident (one event of the Stage 9 Monte Carlo, medium scenario). Drone altitude not to scale.', 'HorizontalAlignment', 'center', 'FontSize', 6, 'Color', 'w', 'BackgroundColor', [0 0 0 0.5]);
ts = [-3:1:min(40, tv + 5), (min(40, tv + 5) + 6):6:(tp + 14)];   gifFile = fullfile(root, 'report', 'figures', 'incident_3d.gif');   tmp = [tempname '.png'];   first = true;
for q = 1:numel(ts)
    t = ts(q);   status = 'intruder approaches the fibre';
    ii = find(path(:, 1) <= t);   if ~isempty(ii)
        pp = path(ii, :);   xyz = zeros(size(pp, 1), 3);   for j = 1:size(pp, 1), xyz(j, :) = P3(pp(j, 2), pp(j, 3), 0.06); end
        set(hI, 'XData', xyz(end, 1), 'YData', xyz(end, 2), 'ZData', xyz(end, 3));   set(hTr, 'XData', xyz(:, 1), 'YData', xyz(:, 2), 'ZData', xyz(:, 3));
    end
    if t >= 0, status = 'intruder on the fibre: the DAS hears the footsteps'; end
    if t >= ta, a3 = P3(xh, yh, 0.1);   set(hA, 'XData', a3(1), 'YData', a3(2), 'ZData', a3(3));   status = sprintf('ALARM at t = %.1f s: DAS + AI classify a %s', ta, ev.type(kk)); end
    if t >= tl                                                            % drone flight from the station to the estimated position
        fr = min(1, (t - tl) / max(tv - tl, 1e-9));   x = st(1) + fr * (xh - st(1));   y = st(2) + fr * (yh - st(2));   a3 = P3(x, y, 0.5 + 0.5 * sin(pi * min(fr, 1)));   set(hD, 'XData', a3(1), 'YData', a3(2), 'ZData', a3(3));
        status = sprintf('drone launched, flying (%.0f %% of the way)', 100 * fr);
    end
    if t >= tv, status = sprintf('VERIFIED at t = %.0f s: drone on scene (%.0f s after the alarm)', tv, R.verif_dt(kk)); end
    if t >= tpd                                                           % patrol drives from its home site
        fr = min(1, (t - tpd) / max(tp - tpd, 1e-9));   x = px0 + fr * (xh - px0);   y = py0 + fr * (yh - py0);   a3 = P3(x, y, 0.08);   set(hP, 'XData', a3(1), 'YData', a3(2), 'ZData', a3(3));
        status = sprintf('patrol dispatched, driving (%.0f %% of the way)', 100 * fr);
    end
    if t >= tp, status = sprintf('PATROL ON SCENE at t = %.0f s (%.0f s after the alarm)', tp, R.patrol_dt(kk)); end
    set(hT, 'String', sprintf('t = %5.1f s after the crossing | %s', t, status));   drawnow;
    exportgraphics(H.fig, tmp, 'Resolution', 110);   im = imread(tmp);   [ind, map] = rgb2ind(im, 128);
    if first, imwrite(ind, map, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', 0.18);   first = false; else, imwrite(ind, map, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', 0.18); end
end
delete(tmp);   fprintf('GIF written: %s (%d frames)\n', gifFile, numel(ts));
