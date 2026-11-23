% SITING_SENS_TABLE  Assemble results/siting/sens/case_*.csv into results/siting/sensitivity.csv (order: base, slope5, slope15, road100, road500, water25, water100, inside500).
root = fileparts(fileparts(mfilename('fullpath')));   order = {'base', 'slope5', 'slope15', 'road100', 'road500', 'water25', 'water100', 'inside500'};   T = table();
for i = 1:numel(order)
    f = fullfile(root, 'results', 'siting', 'sens', ['case_' order{i} '.csv']);   if ~isfile(f), continue; end
    x = readtable(f, 'TextType', 'string', 'VariableNamingRule', 'preserve');   x.Properties.VariableNames{1} = 'run_case';   x.arcs_km = string(x.arcs_km);   x.kinds = string(x.kinds);   x.slopes_pct = string(x.slopes_pct);   T = [T; x]; %#ok<AGROW>
end
writetable(T, fullfile(root, 'results', 'siting', 'sensitivity.csv'));   disp(T);
