% STAGE6_DUAL  Sensitivity: dual verification before a patrol is sent. For low / medium / high compare
%   mode 0 single check | mode 1 dual everywhere | mode 2 dual in Neutral and Cold only (single in Hot)
% 100 authorized vehicles / site / day, p_site_clear 0.99 (both PLACEHOLDERS), temporary uniform classifier stub, same seed for every case. Writes results/stage6_dual.csv.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   TP = terrain_pieces(T, P);   lib = build_das_library(P);   km = T.cells.ring.L / 1e3;   nD = 20;   rows = [];
names = {'single check', 'dual everywhere', 'dual in Neutral+Cold, single in Hot'};
for sc = {'low', 'medium', 'high'}
    [al, ~, A] = get_allocation(P, sc{1});   G = gen_setup(T, TP, P, A);
    for mode = 0:2
        P2 = P;   P2.fd.dual_verify = mode;   s = RandStream('Threefry', 'Seed', 707);   Rs = cell(nD, 1);   Es = cell(nD, 1);
        for d = 1:nD
            ev = gen_day(T, TP, G, P2, s, d);   ob = das_observe(ev, T, al, lib, s);   Rs{d} = respond_day(ev, ob, T, TP, al, A, P2, s);   Es{d} = ev(:, {'kind', 'is_intrusion'});
        end
        R = vertcat(Rs{:});   E = vertcat(Es{:});   intr = E.is_intrusion;   ta = R.alarm & intr;   fa = R.alarm & ~E.is_intrusion;
        fa_after = fa & R.confirmed & ~isnan(R.patrol_dt);   pat = ta & ~isnan(R.patrol_dt);   ver = intr & R.alarm & R.asset ~= "none" & R.in_Tresp;   hasAsset = ta & R.asset ~= "none";
        late = hasAsset & ~R.in_Tresp;
        fprintf('\n=== %s | %s ===\n', sc{1}, names{mode + 1});
        fprintf('false patrols: %.4f per km per day (%.1f per day)\n', nnz(fa_after) / nD / km, nnz(fa_after) / nD);
        fprintf('verification later than T_resp: %d of %d true alarms with an asset (%.1f %%); median verification time %.0f s; median alarm-to-patrol %.0f s; patrol reached %.1f %%\n', nnz(late), nnz(hasAsset), 100 * nnz(late) / max(nnz(hasAsset), 1), median(R.verif_dt(hasAsset), 'omitnan'), median(R.patrol_dt(pat), 'omitnan'), 100 * nnz(pat) / nnz(ta));
        fprintf('intruders NOT verified within T_resp: %d of %d (%.1f %%), %.1f per day; in Hot zones %d of %d (%.1f %%)\n', nnz(intr) - nnz(ver), nnz(intr), 100 * (1 - nnz(ver) / nnz(intr)), (nnz(intr) - nnz(ver)) / nD, nnz(intr & R.zone == 3) - nnz(ver & R.zone == 3), nnz(intr & R.zone == 3), 100 * (1 - nnz(ver & R.zone == 3) / nnz(intr & R.zone == 3)));
        rows = [rows; mode, nnz(fa_after) / nD / km, nnz(late) / max(nnz(hasAsset), 1), median(R.verif_dt(hasAsset), 'omitnan'), median(R.patrol_dt(pat), 'omitnan'), nnz(pat) / nnz(ta), 1 - nnz(ver) / nnz(intr)];   %#ok<AGROW>
    end
end
sc = repelem({'low'; 'medium'; 'high'}, 3);
T2 = array2table(rows, 'VariableNames', {'mode', 'false_patrols_per_km_day', 'share_verified_late', 'median_verification_s', 'median_alarm_to_patrol_s', 'patrol_reached', 'intruders_not_verified_in_Tresp'});
T2.scenario = sc;   writetable(T2, fullfile(root, 'results', 'stage6_dual.csv'));
