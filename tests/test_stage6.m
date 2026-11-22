% TEST_STAGE6  DAS alarm -> cue -> verification -> patrol, over simulated days (medium scenario), with the TEMPORARY classifier stub.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);   fprintf('--- Stage 6 tests ---\n');
for sc = {'low', 'medium', 'high'}
    [al, ~, A] = get_allocation(P, sc{1});   G = gen_setup(T, TP, P, A);   s = RandStream('Threefry', 'Seed', 606);   nD = 20;   Rall = cell(nD, 1);   Eall = cell(nD, 1);
    for d = 1:nD
        ev = gen_day(T, TP, G, P, s, d);   ob = das_observe(ev, T, al, lib, s);   R = respond_day(ev, ob, T, TP, al, A, P, s);
        % per-day consistency checks
        assert(all(R.t_alarm(R.alarm) > ev.t_start(R.alarm)), 'alarm before the event');
        assert(all(R.verif_dt(R.asset ~= "none" & R.alarm) >= 0), 'negative verification time');
        assert(all(isnan(R.patrol_dt(~R.confirmed))), 'patrol dispatched without a confirmed verification');
        assert(all(R.patrol_dt(R.confirmed & ~isnan(R.patrol_dt)) >= R.verif_dt(R.confirmed & ~isnan(R.patrol_dt))), 'patrol before verification');
        dr = R.asset == "drone";   assert(all(R.verif_dt(dr) >= P.v.T_launch_s + R.d_asset_m(dr) / P.v.v_drone_ms - 1e-9), 'drone faster than its speed allows');
        Rall{d} = R;   Eall{d} = ev(:, {'kind', 'type', 'is_intrusion', 'cell'});
    end
    R = vertcat(Rall{:});   E = vertcat(Eall{:});
    intr = E.is_intrusion;   hot = R.zone == 3;
    fprintf('%-6s %d intrusions in %d days | alarms %d (true %d, false %d) | detection-to-alert %.2f s\n', sc{1}, nnz(intr), nD, nnz(R.alarm), nnz(R.alarm & intr), nnz(R.alarm & ~intr), P.fd.T_win_s + P.fd.t_proc_s + P.fd.t_ai_s);
    a = R.alarm & intr;
    fprintf('       true alarms: camera %d, drone %d, none %d | verified within T_resp %.1f %% (Hot %.1f %% of %d) | median verification time %.0f s | patrol reached %.1f %% (median %.0f s)\n', ...
        nnz(a & R.asset == "camera"), nnz(a & R.asset == "drone"), nnz(a & R.asset == "none"), 100 * mean(R.in_Tresp(a)), 100 * mean(R.in_Tresp(a & hot)), nnz(a & hot), median(R.verif_dt(a), 'omitnan'), ...
        100 * mean(~isnan(R.patrol_dt(a))), median(R.patrol_dt(a), 'omitnan'));
    fa = R.alarm & ~intr;   fprintf('       false alarms: %d (animals %d, authorized vehicles %d, noise %d); cleared by the asset %.1f %%\n', nnz(fa), nnz(fa & E.kind == "animal"), nnz(fa & E.kind == "normal_vehicle"), nnz(fa & E.kind == "noise"), 100 * mean(~R.confirmed(fa & R.asset ~= "none")));
end
assert(true);   fprintf('Stage 6: ALL PASSED\n');
