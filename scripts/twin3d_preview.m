% TWIN3D_PREVIEW  One preview of the 3D overview with the chosen camera (env TWIN_THEME = light | dark, TWIN_DIST optional). Writes report/figures/twin3d_preview_<theme>.png.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   addpath(fullfile(root, 'third_party', 'dasmap_viz'));
P = load_params_fd();   T = load_twin(P);   [al, ~, A] = get_allocation(P, 'medium');   S = load(fullfile(root, 'results', 'stage9', 'run_medium.mat'));
th = getenv('TWIN_THEME');   if isempty(th), th = 'light'; end,   cam = twin3d_camera('overview');   d = str2double(getenv('TWIN_DIST'));   if ~isnan(d), cam.dist = d; end
H = draw_twin3d(T, P, al, A, S.E, cam, 'Size', [16 9], 'MaxIntruders', 250, 'Theme', th);
exportgraphics(H.fig, fullfile(root, 'report', 'figures', ['twin3d_preview_' th '.png']), 'Resolution', 150);   close(H.fig);
