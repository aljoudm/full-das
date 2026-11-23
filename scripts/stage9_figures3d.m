% STAGE9_FIGURES3D  3D digital-twin figures for the report and the presentation (SIMULATED intruders): overview and a zoom on a Hot stretch.
% PNG, 300 dpi, A4 text width 16 cm, fixed cameras (src/viz/twin3d_camera.m), saved in report/figures/.  Uses results/stage9/run_medium.mat when it exists, else stage8.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();   addpath(fullfile(root, 'third_party', 'dasmap_viz'));
P = load_params_fd();   T = load_twin(P);   [al, ~, A] = get_allocation(P, 'medium');   fd = fullfile(root, 'report', 'figures');   if ~isfolder(fd), mkdir(fd); end
f9 = fullfile(root, 'results', 'stage9', 'run_medium.mat');   f8 = fullfile(root, 'results', 'stage8', 'run_medium.mat');
if isfile(f9), S = load(f9); else, S = load(f8); end
E = S.E;   cam = twin3d_camera('overview');   th = getenv('TWIN_THEME');   if isempty(th), th = 'light'; end,   which = getenv('TWIN_WHICH');   res = 300;   if ~isempty(getenv('TWIN_RES')), res = str2double(getenv('TWIN_RES')); end   % one figure per MATLAB session (openGL)
if isempty(which) || strcmp(which, 'overview')
    H = draw_twin3d(T, P, al, A, E, cam, 'Size', [16 9], 'Theme', th);
    exportgraphics(H.fig, fullfile(fd, ['twin3d_overview_' th '.png']), 'Resolution', res);   close(H.fig);   if strcmp(which, 'overview'), return; end
end
% ---- zoom on a fixed Hot stretch north-east of Makkah, where the DAS misses cluster. Extent saved here. Higher-resolution imagery crop (about 6 m/px) made once from the
% local DAS-map tex_base.jpg (Esri World Imagery export of prepare_terrain.m, see third_party/PROVENANCE.md).
ext = [39.84 39.99 21.47 21.58];   zf = fullfile(root, 'data', 'imagery', 'esri_zoom_hot_nw.jpg');
if ~isfile(zf)
    srcImg = fullfile(getenv('USERPROFILE'), 'Downloads', 'DAS Map', 'data', 'dem', 'tex_base.jpg');   I = imread(srcImg);   [h, w, ~] = size(I);   la = [21.2625 21.5831];   lo = [39.5788 40.0622];
    r0 = round((la(2) - ext(4)) / diff(la) * h) + 1;   r1 = round((la(2) - ext(3)) / diff(la) * h);   c0 = round((ext(1) - lo(1)) / diff(lo) * w) + 1;   c1 = round((ext(2) - lo(1)) / diff(lo) * w);
    imwrite(I(r0:r1, c0:c1, :), zf, 'Quality', 88);
end
lat0 = mean([min(T.dem.lat) max(T.dem.lat)]);   lon0 = mean([min(T.dem.lon) max(T.dem.lon)]);   kx = 111.195 * cosd(lat0);   ky = 111.195;
c = [mean(ext(3:4)), mean(ext(1:2))];   Zc = interp2(T.dem.lon, T.dem.lat, double(T.dem.Z), c(2), c(1)) / 1000 * cam.VE;
cz = twin3d_camera('zoom', [(c(2) - lon0) * kx, (c(1) - lat0) * ky, Zc]);
H = draw_twin3d(T, P, al, A, E, cz, 'Size', [16 9], 'Theme', th, 'ZoomExtent', ext, 'MeshExtent', ext, 'Stride', 1, 'Imagery', zf, 'LegendPos', 'bl', 'MaxIntruders', 260);
exportgraphics(H.fig, fullfile(fd, ['twin3d_zoom_hot_' th '.png']), 'Resolution', res);   close(H.fig);
fprintf('zoom centre lat %.4f lon %.4f; shown in the zoom window: verified %d, late %d, missed %d\n', c(1), c(2), H.count);
