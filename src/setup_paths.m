function root = setup_paths()
% SETUP_PATHS  Add every full-das source folder and the frozen third-party code to the MATLAB path. Returns the repo root.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(here);
addpath(genpath(fullfile(here, 'twin')), genpath(fullfile(here, 'alloc')), genpath(fullfile(here, 'intruders')), ...
        genpath(fullfile(here, 'das')), genpath(fullfile(here, 'ai')), genpath(fullfile(here, 'response')), ...
        genpath(fullfile(here, 'tracking')), genpath(fullfile(here, 'metrics')), genpath(fullfile(here, 'viz')), genpath(fullfile(here, 'profile')));
addpath(fullfile(root, 'config'));
addpath(fullfile(root, 'third_party', 'optimization', 'src'));     % run_optimization, load_cells, ... (frozen copy)
addpath(fullfile(root, 'third_party', 'das_engine'));              % phi-OTDR engine (frozen copy)
end
