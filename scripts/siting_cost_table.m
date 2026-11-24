% SITING_COST_TABLE  Cost of every siting solution WITH the shelter cost (table rows C_shelter = 120,000 PLACEHOLDER per new cabin, C_shelter_checkpoint = 30,000 ASSUMED per checkpoint room),
% and the energy of the air conditioning. Solutions solved before 24 Nov 2026 stored alloc.cost.shelters = 0; the shelter cost is added here from the kind of every chosen site, so that
% N and the sites of those solutions are the ones the MILP found (the MILP was re-solved with the shelter cost for low / medium / high and two extreme prices: same sites, see key_numbers.md).
% Output: results/siting/cost_with_shelters.csv
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();
cs = P.v.C_shelter;   cc = P.fd.C_shelter_checkpoint;   Pdas = P.v.P_DAS;   Psh = P.v.P_shelter;
names = {'medium_22_siting', 'low_22_siting', 'high_22_siting', 'medium_22_siting_N5', 'medium_22_siting_d13', 'medium_22_siting_slope5', 'medium_22_siting_slope15', 'medium_22_siting_road100', ...
    'medium_22_siting_road500', 'medium_22_siting_water25', 'medium_22_siting_water100', 'medium_22_siting_inside500', 'medium_22_siting_shelhi', 'medium_22_siting_shello'};
rows = cell(numel(names), 12);
for k = 1:numel(names)
    f = fullfile(root, 'results', ['alloc_' strrep(names{k}, 'medium_22', 'medium_22') '.mat']);   if ~isfile(f), f = fullfile(root, 'results', ['alloc_' names{k} '.mat']); end
    X = load(f);   a = X.alloc;   kd = string({a.interrogators.cand.kind});   nC = nnz(kd == 'checkpoint');   nR = numel(kd) - nC;   n = numel(kd);
    isHi = endsWith(names{k}, 'shelhi');   isLo = endsWith(names{k}, 'shello');   csk = cs;   cck = cc;   if isHi, csk = 300000;   cck = 150000; end,   if isLo, csk = 50000;   cck = 5000; end
    shel = nR * csk + nC * cck;   base = a.cost.interrogators + a.cost.fibre + a.cost.leadin;
    rows(k, :) = {strrep(names{k}, '_22_siting', ''), n, nC, nR, a.cost.interrogators, a.cost.fibre, a.cost.leadin, shel, base + shel, n * (Pdas + Psh), n * Psh * 8760 / 1000, a.C_total};
end
T = cell2table(rows, 'VariableNames', {'case', 'N', 'n_checkpoint_rooms', 'n_new_cabins', 'interrogators_SAR', 'sensing_fibre_SAR', 'leadin_fibre_SAR', 'shelters_SAR', 'C_total_SAR', 'power_W', 'cooling_kWh_per_year', 'C_total_stored_in_alloc_SAR'});
writetable(T, fullfile(root, 'results', 'siting', 'cost_with_shelters.csv'));   disp(T);
