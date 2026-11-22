function [dL, w] = das_waveform(type, t, s, coupling)
% DAS_WAVEFORM  Fibre elongation dL(t) [m] and affected length w [m] of one event type (the input of the frozen DAS engine).
%
%   [dL, w] = das_waveform(type, t, s, coupling)     t slow-time axis [s]; s RandStream; coupling = amplitude factor (log-normal, mean 1)
%
%   walking, digging, vehicle copy DAS-Simulation define_events.m (impacts: amplitude, ring frequency, decay); running, climbing, animal
%   and the background-noise event ('no_event') are NEW and ASSUMED (no source): running = stronger, faster, higher-frequency steps;
%   climbing = irregular grips plus a slow sway; animal = weak fast steps; no_event = band-limited noise (wind / machinery).
T = t(end) + (t(2) - t(1));   dL = zeros(size(t));
switch type
    case 'walking',  dL = impacts(t, train(0.2, 1/1.8, 0.03, T, s), 60e-9, 30, 0.04, s);   w = 5;
    case 'running',  dL = impacts(t, train(0.2, 1/2.8, 0.03, T, s), 90e-9, 40, 0.03, s);   w = 5;
    case 'digging',  dL = impacts(t, train(0.3, 1.2, 0.05, T, s), 80e-9, 120, 0.08, s);     w = 3;
    case 'climbing'
        tk = sort(T * rand(s, 1, 4));   dL = impacts(t, tk, 40e-9, 15, 0.10, s) + 30e-9 * sin(2 * pi * 2 * t + 2 * pi * rand(s));   w = 3;
    case 'vehicle',  env = exp(-((t - T / 2) / 0.5).^2);   dL = 100e-9 * env .* (0.6 + 0.4 * sin(2 * pi * 25 * t));   w = 30;
    case 'animal',   dL = impacts(t, train(0.1, 1/4, 0.04, T, s), 20e-9, 45, 0.03, s);        w = 4;
    case 'no_event'
        x = randn(s, 1, numel(t));   [b, a] = butter(2, [5 60] / ((1 / (t(2) - t(1))) / 2));   dL = 8e-9 * filtfilt(b, a, x) / 0.25;   w = 50;
    otherwise, error('das_waveform:type', 'Unknown event type %s', type);
end
dL = coupling * dL;
end

function dL = impacts(t, tk, A, f_ring, t_decay, s)
% Sum of damped oscillations starting at times tk (one per impact), amplitude +-10 %
dL = zeros(size(t));
for j = 1:numel(tk)
    tt = t - tk(j);   on = tt >= 0;   Aj = A * (1 + 0.1 * randn(s));
    dL(on) = dL(on) + Aj * exp(-tt(on) / t_decay) .* sin(2 * pi * f_ring * tt(on));
end
end

function tk = train(t0, step, jit, T, s)
% impact times: regular train from t0 with step, timing jitter jit [s]
tk = t0 + (0:step:T);   tk = tk + jit * randn(s, 1, numel(tk));
end
