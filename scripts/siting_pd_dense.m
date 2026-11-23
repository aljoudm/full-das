% SITING_PD_DENSE  Dense Pd(d) run: 1,000 windows per intruder type and distance, every 0.5 km from 12 to 20 km (the range where d* is decided). RESUMABLE: one file per distance in
% results/siting/pd_chunks/ (S of every window, detection statistic of das_detect). Same engine, window, coupling (log-normal sigma 0.4), seeds scheme and threshold as scripts/siting_pd_curve.m;
% only the number of windows and the distance grid change. The rest of the curve (0-25 km, integer km, 80 windows per type) stays as it was (results/pd_curve_raw.mat).
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
P = load_params_fd();   lib = build_das_library(P);   p = das_params();   cfg = struct('L_win_m', P.fd.L_win_m, 'T_win_s', P.fd.T_win_s, 'fs_win_hz', P.fd.fs_win_hz, 'PRF_hz', p.f_rep);
types = {'walking', 'running', 'vehicle', 'digging', 'climbing'};   dk = [12 12.5 13 14 14.25 14.5 14.75 15:20];   nW = 1000;   nNew = 400;   % REDUCED on 23 Nov 2026 (project lead): 12, 12.5 and 13 km were already done with 1,000 windows per type and are kept; 14-20 km every 1 km with 400 windows per type
   sg = P.fd.coupling_sigma;   od = fullfile(root, 'results', 'siting', 'pd_chunks');   if ~isfolder(od), mkdir(od); end
if isempty(gcp('nocreate')), cl = parcluster('Processes');   cl.NumWorkers = 12;   parpool(cl, 12); end      % 12 of the 16 logical cores (the profile default is 4; not saved)
jmap = containers.Map(num2cell(dk), num2cell(1:numel(dk)));   jold = containers.Map({12, 12.5, 13, 14, 15, 16, 17, 18, 19, 20}, num2cell([1 2 3 4 5 6 7 8 9 10]));
for j = 1:numel(dk)
    f = fullfile(od, sprintf('d_%05.2f.mat', dk(j)));   if isfile(f), continue; end
    nW = nNew;   t0 = tic;   jj = j + 30;   % new distances: seeds from a separate index range (the chunks already done keep their seeds)
   S = zeros(nW, numel(types));
    for t = 1:numel(types)
        rs = RandStream('Threefry', 'Seed', 9100 + 10 * jj + t);   coup = exp(sg * randn(rs, nW, 1) - sg^2 / 2);   seed = 3000000 + (jj * 10 + t) * 10000 + (1:nW)';   s = zeros(nW, 1);   ty = types{t};   d = dk(j) * 1e3;
        parfor k = 1:nW
            W = das_window(ty, d, coup(k), seed(k), cfg);   s(k) = das_detect(W);
        end
        S(:, t) = s;
    end
    thr = lib.thr;   save(f, 'S', 'types', 'thr', 'nW');   fprintf('d = %.1f km: %d windows in %.0f s, Pd by type %s\n', dk(j), nW * numel(types), toc(t0), mat2str(mean(S > thr), 3));
end
disp('done');
