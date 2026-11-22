function W = das_window(type, dist_m, coupling, seed, cfg)
% DAS_WINDOW  Run the FROZEN phi-OTDR engine on a short fibre window around one event (the window-plus-library strategy).
%
%   W = das_window(type, dist_m, coupling, seed, cfg)
%     type      'walking' | 'running' | 'vehicle' | 'digging' | 'climbing' | 'animal' | 'no_event' | 'background' (no event at all)
%     dist_m    distance of the event from its interrogator along the fibre: sets the signal power through the round-trip loss
%               exp(-2 alpha dist) (the receiver noise is fixed), i.e. the same local SNR as at that distance on a long fibre
%     coupling  amplitude factor of the event (log-normal, mean 1);   seed  engine seed (new random fibre fingerprint)
%     cfg       struct: L_win_m, T_win_s, fs_win_hz, PRF_hz (engine pulse repetition rate, from das_params)
%
%   W.dL      recovered elongation [time x channel] (single) at fs_win_hz, channels every dz_samp (the AI input)
%   W.t, W.z  axes (z relative to the window start [m]);  W.z0 true event position;  W.act activity along z [m]
%   W.S       detection statistic = max(act) / median(act);  W.z_hat estimated position;  W.loc_err [m]
%   W.snr_db  local SNR at the event (mean backscatter power at that point / receiver noise)
p0 = das_params();   PRF = cfg.PRF_hz;   Np = round(cfg.T_win_s * PRF);
Pw = evalc('P = params(struct(''L'', cfg.L_win_m, ''PRF'', PRF, ''Npulses'', Np, ''seed'', seed));');   %#ok<NASGU> engine prints are muted
alpha = P.alpha;   P0 = p0.P0 * exp(-2 * alpha * dist_m);
evalc('P = params(struct(''L'', cfg.L_win_m, ''PRF'', PRF, ''Npulses'', Np, ''seed'', seed, ''P0'', P0));');
evalc('F = fiber_model(P);');
s = RandStream('Threefry', 'Seed', seed + 1e6);   z0 = cfg.L_win_m / 2;
if strcmp(type, 'background')
    ev = struct('name', {}, 'type', {}, 'z0', {}, 'w', {}, 'dL', {}, 'phi_t', {}, 'ramp', {});
    ev(1).name = 'none';   ev(1).type = 'none';   ev(1).z0 = z0;   ev(1).w = 3;   dL = zeros(1, P.Npulses);
else
    [dL, w] = das_waveform(type, P.t_slow, s, coupling);   ev = struct('name', type, 'type', type, 'z0', z0, 'w', w, 'dL', dL);
end
ev.phi_t = P.k_strain * dL;   ev.ramp = min(max((P.z_fine(:) - (z0 - ev.w / 2)) / ev.w, 0), 1);
evalc('Wf = simulate_waterfall(P, F, ev);');
evalc('D = detector(P, Wf, ''coherent'');');   evalc('R = process_das(P, D);');
act = R.act(:);   med = median(act);   [mx, k] = max(act);
W.S = mx / med;   W.z_hat = R.z(k);   W.z0 = z0;   W.loc_err = W.z_hat - z0;   W.act = act;   W.zr = R.z(:);
% local SNR at the event: mean backscatter power there over the receiver noise
iz = max(1, round(z0 / P.dz_adc));   W.snr_db = 10 * log10(P.P_bs0 * exp(-2 * alpha * z0) / P.P_noise);
% decimate to the AI sampling rate (anti-alias low-pass inside decimate)
dec = max(1, round(PRF / cfg.fs_win_hz));   X = double(R.dL).';                         % time x channel
W.dL = single(decimate_cols(X, dec));   W.fs = PRF / dec;   W.t = (0:size(W.dL, 1) - 1) / W.fs;   W.z = R.z(:).';
W.type = type;   W.dist_m = dist_m;   W.coupling = coupling;   W.seed = seed;   W.dL_rms_nm = std(R.dL(k, :)) * 1e9;
end

function Y = decimate_cols(X, dec)
if dec == 1, Y = X; return; end
[b, a] = butter(4, 0.8 / dec);   Y = filtfilt(b, a, X);   Y = Y(1:dec:end, :);
end
