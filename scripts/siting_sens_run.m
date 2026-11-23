% SITING_SENS_RUN  One sensitivity case of the siting thresholds (env SENS_NAME = base | slope5 | slope15 | road100 | road500 | water25 | water100 | inside500; env SENS_DSTAR optional d* in km).
% Writes results/siting/sens/case_<name>.csv (one case per MATLAB session: several MILP solves in one session crash this MATLAB licence).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   P = load_params_fd();   nm = getenv('SENS_NAME');   if isempty(nm), nm = 'base'; end
args = {'Tag', nm, 'Force', true};   ds = str2double(getenv('SENS_DSTAR'));   if ~isnan(ds), args = [args {'DStarKm', ds}]; end
switch nm
    case 'slope5', args = [args {'Slope', 0.05}];      case 'slope15', args = [args {'Slope', 0.15}];
    case 'road100', args = [args {'RoadM', 100}];      case 'road500', args = [args {'RoadM', 500}];
    case 'water25', args = [args {'WaterM', 25}];      case 'water100', args = [args {'WaterM', 100}];
    case 'inside500', args = [args {'InsideMax', 500}];
end
T = load_twin(P);
try
    [al, C] = get_allocation_siting(P, 'medium', args{:});   ia = al.interrogators;   [~, o] = sort(ia.arc_m);
    R = siting_report(P, T, al, C, ['medium_' nm], fullfile(root, 'results', 'siting', 'sens'));
    kinds = strjoin(string({ia.cand(o).kind}), '/');   slopes = strjoin(compose('%.1f', [ia.cand(o).slope_pct]), '/');   arcs = strjoin(compose('%.1f', ia.arc_m(o) / 1e3), '/');
    row = table(string(nm), numel(C), al.n_interrogators, al.C_total, string(arcs), string(kinds), string(slopes), R.max_optical_km, 'VariableNames', {'run_case', 'candidates', 'N', 'C_total', 'arcs_km', 'kinds', 'slopes_pct', 'max_optical_km'});
catch ME
    row = table(string(nm), NaN, NaN, NaN, "", string(ME.message), "", NaN, 'VariableNames', {'run_case', 'candidates', 'N', 'C_total', 'arcs_km', 'kinds', 'slopes_pct', 'max_optical_km'});
end
writetable(row, fullfile(root, 'results', 'siting', 'sens', ['case_' nm '.csv']));   disp(row);      % one file per case (no shared file, no column mismatch); scripts/siting_sens_table.m assembles them
