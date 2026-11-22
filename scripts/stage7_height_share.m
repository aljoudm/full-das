% STAGE7_HEIGHT_SHARE  Share of intruders whose height can be estimated, for p_along = 0, 10 and 30 % (user decision 22 Nov), by path type.
% Prints the table and saves results/stage7_height_share.csv. Does not call the height model.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   T = load_twin(P);   [al, ~, A] = get_allocation(P, 'medium');   TP = terrain_pieces(T, P);   G = gen_setup(T, TP, P, A);   lib = build_das_library(P);
nD = 300;   pv = [0 0.10 0.30];   rows = [];
for ip = 1:numel(pv)
    s = RandStream('Threefry', 'Seed', 5000 + ip);   E = cell(nD, 1);
    for d = 1:nD, E{d} = gen_day(T, TP, G, P, s, d, struct('intrusion_only', true, 'p_along', pv(ip))); end
    ev = vertcat(E{:});   ob = das_observe(ev, T, al, lib, s);   el = height_eligibility(ev, ob, P);
    n = height(ev);   w = ev.type == "walking";   a = ev.along;
    rows = [rows; pv(ip), n, mean(w), mean(a), mean(el.ok), mean(el.ok(a)), mean(el.ok(w & ~a)), mean(el.ok(w))]; %#ok<AGROW>
    fprintf('p_along %.2f: %d intruders (%d days) | walking %.1f%% | along-boundary path %.1f%% | height measurable: %.1f%% of all, %.1f%% of along-boundary paths, %.1f%% of walking crossings, %.1f%% of all walkers\n', ...
        pv(ip), n, nD, 100 * rows(end, 3), 100 * rows(end, 4), 100 * rows(end, 5), 100 * rows(end, 6), 100 * rows(end, 7), 100 * rows(end, 8));
    rs = categorical(el.reason(w));   fprintf('   walkers by reason: %s\n', strjoin(arrayfun(@(c) sprintf('%s %.1f%%', string(c), 100 * mean(rs == c)), categories(rs), 'UniformOutput', false), ', '));
end
T2 = array2table(rows, 'VariableNames', {'p_along', 'n_intruders', 'share_walking', 'share_along_path', 'height_measurable_all', 'height_measurable_along', 'height_measurable_crossing_walkers', 'height_measurable_walkers'});
writetable(T2, fullfile(root, 'results', 'stage7_height_share.csv'));
% checks: no along-boundary walkers at 0 %, measurable share grows with p_along, only along-boundary paths can qualify
assert(rows(1, 5) == 0 && rows(2, 5) > 0 && rows(3, 5) > rows(2, 5) && all(rows(2:3, 7) == 0), 'height share does not behave as expected');
fprintf('Stage 7 (height share): ALL PASSED\n');
