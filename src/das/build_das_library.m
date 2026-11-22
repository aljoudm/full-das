function lib = build_das_library(P, varargin)
% BUILD_DAS_LIBRARY  Library of DAS windows from the FROZEN phi-OTDR engine (one per type x distance x random fibre / coupling).
%
%   lib = build_das_library(P)                       P from load_params_fd; saves results/das_library.mat (NOT in git, ~300 MB)
%   lib = build_das_library(P, 'Force', true, 'Dist', [0.5 5 10 15 20]*1e3, 'NBg', 300)
%
%   Entries: lib.S (detection statistic of das_detect), lib.z_err, lib.snr_db, lib.dL (window, the AI input), lib.coupling, ...
%   lib.thr = detection threshold exp(mean(log S_bg) + det_k_sigma * std(log S_bg)) from noise-only windows (lib.bg_S);
%   lib.p_fa_window = normal-tail estimate of the intrinsic false-alarm probability per window and its empirical counterpart.
%   If L_win_m, T_win_s or fs_win_hz change in the table (the AI input changes), delete the file or pass 'Force': the library is rebuilt.
ip = inputParser;   addParameter(ip, 'Force', false);   addParameter(ip, 'Dist', [0.5 5 10 15 20] * 1e3);   addParameter(ip, 'NBg', 300);
addParameter(ip, 'Types', {'walking', 'running', 'vehicle', 'digging', 'climbing', 'animal', 'no_event'});   parse(ip, varargin{:});   o = ip.Results;
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));   f = fullfile(root, 'results', 'das_library.mat');
p = das_params();   fd = P.fd;
cfg = struct('L_win_m', fd.L_win_m, 'T_win_s', fd.T_win_s, 'fs_win_hz', fd.fs_win_hz, 'PRF_hz', p.f_rep);
key = [cfg.L_win_m cfg.T_win_s cfg.fs_win_hz cfg.PRF_hz fd.coupling_sigma fd.lib_n_per_bin fd.det_k_sigma numel(o.Dist) o.NBg];
if isfile(f) && ~o.Force
    S = load(f);   if isequal(S.lib.key, key), lib = S.lib;   fprintf('build_das_library: loaded %s\n', f);   return; end
    fprintf('build_das_library: table parameters changed, rebuilding\n');
end
types = o.Types;   nT = numel(types);   nD = numel(o.Dist);   nR = fd.lib_n_per_bin;   sg = fd.coupling_sigma;
[ti, di, ri] = ndgrid(1:nT, 1:nD, 1:nR);   ti = ti(:);   di = di(:);   ri = ri(:);   N = numel(ti);
s = RandStream('Threefry', 'Seed', 424242);   coup = exp(sg * randn(s, N, 1) - sg^2 / 2);   seed = 1000 + (1:N)';
Sv = zeros(N, 1);   ze = zeros(N, 1);   snr = zeros(N, 1);   dLw = cell(N, 1);   zw = [];
t0 = tic;
parfor k = 1:N
    W = das_window(types{ti(k)}, o.Dist(di(k)), coup(k), seed(k), cfg);
    [Sv(k), zh] = das_detect(W);   ze(k) = zh - W.z0;   snr(k) = W.snr_db;   dLw{k} = W.dL;
end
W = das_window('background', 1e3, 1, 1, cfg);   zw = W.z;   fs = W.fs;   tw = W.t;
bgS = zeros(o.NBg, 1);
parfor k = 1:o.NBg
    Wb = das_window('background', o.Dist(1 + mod(k, nD)), 1, 900000 + k, cfg);   bgS(k) = das_detect(Wb);
end
lb = log(bgS);   thr = exp(mean(lb) + fd.det_k_sigma * std(lb));
lib = struct('types', {types}, 'dist_m', o.Dist, 'n_per_bin', nR, 'cfg', cfg, 'key', key, 'type_idx', ti, 'dist_idx', di, 'S', Sv, 'z_err', ze, 'snr_db', snr, ...
    'coupling', coup, 'dL', {dLw}, 'z', zw, 't', tw, 'fs', fs, 'bg_S', bgS, 'thr', thr, 'built', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
lib.p_fa_window_normal = 0.5 * erfc(fd.det_k_sigma / sqrt(2));   lib.p_fa_window_empirical = mean(bgS > thr);
if ~isfolder(fileparts(f)), mkdir(fileparts(f)); end
save(f, 'lib', '-v7.3');   fprintf('build_das_library: %d windows + %d background in %.0f s, threshold S = %.1f, saved %s\n', N, o.NBg, toc(t0), thr, f);
end
