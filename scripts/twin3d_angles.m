% TWIN3D_ANGLES  Three trial versions of the 3D overview with the camera at 30, 40 and 55 degrees elevation (due south, looking north, no rotation; same settings otherwise), side by side, to
% choose the angle. Writes report/figures/twin3d_angles_30_40_55.png and the three single images (preview size). Uses the Stage 9 medium run.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   addpath(fullfile(root, 'third_party', 'dasmap_viz'));
P = load_params_fd();   T = load_twin(P);   [al, ~, A] = get_allocation(P, 'medium');   S = load(fullfile(root, 'results', 'stage9', 'run_medium.mat'));   E = S.E;   fd = fullfile(root, 'report', 'figures');
els = [30 40 55];   imgs = cell(1, 3);   tmp = tempname;   only = str2double(getenv('TWIN_EL'));       % render ONE angle per MATLAB session (several openGL figures in one session crash this MATLAB); without TWIN_EL the images are stitched
if ~isnan(only)
    k = find(els == only);   cam = twin3d_camera('overview', only);
    H = draw_twin3d(T, P, al, A, E, cam, 'Size', [16 9], 'MaxIntruders', 250);   exportgraphics(H.fig, fullfile(fd, sprintf('twin3d_angle_%d.png', only)), 'Resolution', 150);   close(H.fig);   return;
end
for k = 1:3
    imgs{k} = imread(fullfile(fd, sprintf('twin3d_angle_%d.png', els(k))));   continue;
    cam = twin3d_camera('overview', els(k));   cam.dist = 92 * (1 + 0.12 * (els(k) == 55) - 0.08 * (els(k) == 30));
    H = draw_twin3d(T, P, al, A, E, cam, 'Size', [16 10.5], 'MaxIntruders', 250);   exportgraphics(H.fig, [tmp sprintf('_%d.png', els(k))], 'Resolution', 150);   close(H.fig);   imgs{k} = imread([tmp sprintf('_%d.png', els(k))]);
    copyfile([tmp sprintf('_%d.png', els(k))], fullfile(fd, sprintf('twin3d_angle_%d.png', els(k))));
end
h = min(cellfun(@(x) size(x, 1), imgs));   row = cell(1, 3);   for k = 1:3, im = imgs{k}(1:h, :, :);   im = insertText(im, [8 8], sprintf('camera elevation %d deg', els(k)), 'FontSize', 26, 'BoxColor', 'white', 'BoxOpacity', 0.85);   row{k} = im; end
imwrite(horzcat(row{:}), fullfile(fd, 'twin3d_angles_30_40_55.png'));
