% STAGE6_REPORT  Numbers asked for after Stage 6: size of the "normal traffic" zone, false alarms before / after verification vs the target,
% sensitivity to the authorized-vehicle rate, and why patrol reach differs between scenarios. TEMPORARY classifier stub (uniform errors).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);   r = T.cells.ring;
wil = @(k, n) deal(0, 0);   % placeholder to keep the script readable
[~, ~, A] = get_allocation(P, 'medium');
% ---- 1) the zone of the rule: boundary within d_road_nonthreat_m of a paved road OR d_site_nonthreat_m of an existing camera site
cs = A.sites([A.sites.in]);   dsite = min(hypot(r.x(:) - [cs.x], r.y(:) - [cs.y]), [], 2);
zone = TP.d_road < P.fd.d_road_nonthreat_m | dsite < P.fd.d_site_nonthreat_m;
fprintf('--- rule zone (road < %.0f m or site < %.0f m): %.2f km of %.2f km = %.1f %% of the boundary (road part %.2f km, site part %.2f km)\n', P.fd.d_road_nonthreat_m, P.fd.d_site_nonthreat_m, ...
    sum(r.len(zone)) / 1e3, r.L / 1e3, 100 * sum(r.len(zone)) / r.L, sum(r.len(TP.d_road < P.fd.d_road_nonthreat_m)) / 1e3, sum(r.len(dsite < P.fd.d_site_nonthreat_m)) / 1e3);
% ---- 2) run days for the three scenarios and the vehicle-rate sensitivity (medium)
FAR_T = 0.01;   nD = 30;   out = [];
cases = {'low', 100, 0.99; 'medium', 100, 0.99; 'high', 100, 0.99; 'medium', 50, 0.99; 'medium', 500, 0.99; 'medium', 100, 0.9; 'medium', 100, 0.999};
for c = 1:size(cases, 1)
    sc = cases{c, 1};   P2 = P;   P2.fd.n_vehicle_site_day = cases{c, 2};   P2.fd.p_site_clear = cases{c, 3};
    [al, ~, A] = get_allocation(P2, sc);   G = gen_setup(T, TP, P2, A);   s = RandStream('Threefry', 'Seed', 707);   Rs = cell(nD, 1);   Es = cell(nD, 1);
    for d = 1:nD
        ev = gen_day(T, TP, G, P2, s, d);   ob = das_observe(ev, T, al, lib, s);   Rd = respond_day(ev, ob, T, TP, al, A, P2, s);
        Rs{d} = Rd;   Es{d} = [ev(:, {'kind', 'type', 'is_intrusion', 'piece'}), table(ob.detected, 'VariableNames', {'detected'})];
    end
    R = vertcat(Rs{:});   E = vertcat(Es{:});   km = r.L / 1e3;   intr = E.is_intrusion;
    inz = intr & zone(E.piece);
    fa = R.alarm & ~intr;   fa_main = fa & ~R.site_routed;   fa_site = fa & R.site_routed;
    fa_after = fa & R.confirmed & ~isnan(R.patrol_dt);                          % false alarm that reaches a patrol
    ta = R.alarm & intr;   conf = ta & R.confirmed;   pat = ta & ~isnan(R.patrol_dt);
    k = nnz(pat);   n = nnz(ta);   z = 1.96;   p = k / n;   lo = (p + z^2 / (2 * n) - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n);   hi = (p + z^2 / (2 * n) + z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) / (1 + z^2 / n);
    fprintf('\n=== %s, %d authorized vehicles/site/day, %d days ===\n', sc, cases{c, 2}, nD);
    fprintf('intruders %d; inside the rule zone %d (%.1f %%), detected there %d (%.1f %%); of those classified as vehicle (site-routed) %d\n', nnz(intr), nnz(inz), 100 * nnz(inz) / nnz(intr), nnz(inz & E.detected), 100 * nnz(inz & E.detected) / max(nnz(inz), 1), nnz(R.site_routed(intr)));
    fprintf('FALSE ALARMS before verification, per km per day (target %.3f): drone/camera-cued %.4f (%.1f per day) | site-routed low priority %.4f (%.1f per day) | all %.4f (%.1f per day)\n', FAR_T, nnz(fa_main) / nD / km, nnz(fa_main) / nD, nnz(fa_site) / nD / km, nnz(fa_site) / nD, nnz(fa) / nD / km, nnz(fa) / nD);
    fprintf('FALSE ALARMS after verification (reach a patrol): %.4f per km per day (%.2f per day) | share of all alarms that are false before / after: %.1f %% / %.1f %%\n', nnz(fa_after) / nD / km, nnz(fa_after) / nD, 100 * nnz(fa) / nnz(R.alarm), 100 * nnz(fa_after) / max(nnz(fa_after) + nnz(pat), 1));
    fprintf('patrol reached %d of %d true alarms = %.1f %% (95 %% Wilson %.1f to %.1f); confirmed by the asset %.1f %%; patrol reached among confirmed %.1f %%; no asset %d\n', k, n, 100 * p, 100 * lo, 100 * hi, 100 * nnz(conf) / n, 100 * nnz(pat) / max(nnz(conf), 1), nnz(ta & R.asset == "none"));
    hot = ta & R.zone == 3;   fprintf('verified within T_resp: all %.1f %%, Hot %.1f %% (n = %d)\n', 100 * mean(R.in_Tresp(ta)), 100 * mean(R.in_Tresp(hot)), nnz(hot));
    out = [out; cases{c, 2}, nnz(fa_main) / nD / km, nnz(fa_site) / nD / km, nnz(fa_after) / nD / km, p, lo, hi, 100 * mean(R.in_Tresp(hot))]; %#ok<AGROW>
end
fprintf('\nTarget FAR = %.3f alarms/km/day = %.2f per day on %.2f km\n', FAR_T, FAR_T * r.L / 1e3, r.L / 1e3);
