% TRESP_SENSITIVITY  Share of intruders verified within T_resp = 120, 180, 300 and 600 s, WITHOUT re-running the Monte Carlo: the stored verification times of the final Stage 9 runs
% (results/stage9_siting_final/run_<scenario>.mat) are compared with each threshold. Verified = the intruder raised an alarm, an asset (camera, drone or site guard) was assigned and
% verif_dt <= T_resp; shares over ALL real intruders (including DAS misses and classifier non-alarms) and over the Hot-cell intruders. The response itself (dispatch, drone busy times,
% drone layout optimised for 300 s) is the one of T_resp = 300 s: only the threshold changes. Check: the 300 s values must equal metrics_summary.csv. Output results/tresp_sensitivity.csv.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
d = fullfile(root, 'results', 'stage9_siting_final');   S9 = readtable(fullfile(d, 'metrics_summary.csv'));   scn = {'low', 'medium', 'high'};   Tr = [120 180 300 600];
B = 2000;   rows = cell(0, 11);
for s = 1:3
    X = load(fullfile(d, ['run_' scn{s} '.mat']));   E = X.E;   nD = X.FA.nDays;   hot = E.zone == 3;   hasAsset = E.threat & E.asset ~= "none" & ~startsWith(E.asset, "none");
    dayIdx = arrayfun(@(k) find(E.day == k), 1:nD, 'UniformOutput', false);
    for t = Tr
        ver = hasAsset & E.verif_dt <= t;   rs = RandStream('Threefry', 'Seed', 654);   bs = zeros(B, 2);
        for b = 1:B, ii = vertcat(dayIdx{randi(rs, nD, nD, 1)});   bs(b, :) = [mean(ver(ii)), nnz(ver(ii) & hot(ii)) / nnz(hot(ii))]; end
        ci = prctile(bs, [2.5 97.5]);
        rows(end+1, :) = {string(scn{s}), t, mean(ver), ci(1, 1), ci(2, 1), nnz(ver & hot) / nnz(hot), ci(1, 2), ci(2, 2), height(E), nnz(hot), nD}; %#ok<SAGROW>
    end
    a = mean(hasAsset & E.verif_dt <= 300);   h = nnz(hasAsset & E.verif_dt <= 300 & hot) / nnz(hot);   q = S9(strcmp(S9.run_case, scn{s}), :);
    assert(abs(a - q.value(strcmp(q.metric, 'verified_Tresp'))) < 1e-9 && abs(h - q.value(strcmp(q.metric, 'verified_Tresp_hot'))) < 1e-9, 'the 300 s values differ from metrics_summary.csv');
end
R = cell2table(rows, 'VariableNames', {'scenario', 'T_resp_s', 'verified_all', 'all_lo95', 'all_hi95', 'verified_hot', 'hot_lo95', 'hot_hi95', 'intruders', 'hot_intruders', 'days'});
R.label = repmat("SIMULATED", height(R), 1);   writetable(R, fullfile(root, 'results', 'tresp_sensitivity.csv'));   disp(R(:, 1:8));   fprintf('300 s check against metrics_summary.csv passed\n');
