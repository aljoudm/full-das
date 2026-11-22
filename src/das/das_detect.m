function [S, z_hat, E] = das_detect(W, band)
% DAS_DETECT  Detection statistic and localization on a DAS window (the output of das_window).
%
%   [S, z_hat, E] = das_detect(W)              band = [8 200] Hz (default)
%
%   E(z)   band-limited energy of the recovered elongation dL at each channel (band-pass, then mean square over the window)
%   S      max over channels (edges excluded) of the 5-channel moving mean of E, divided by the median of E (a noise-only window gives
%          S of a few; an event raises it). Threshold: see das_threshold. The band suppresses the broadband receiver noise, because the
%          events are narrow-band (15 to 120 Hz).
%   z_hat  position of the maximum along the fibre window [m]
if nargin < 2, band = [8 200]; end
X = double(W.dL);   fs = W.fs;   nyq = fs / 2;
[b, a] = butter(3, min(band / nyq, [0.02 0.98]));   Xf = filtfilt(b, a, X);
E = mean(Xf.^2, 1);   Es = movmean(E, 5);   ed = 8;   ok = (ed + 1):(numel(E) - ed);
[mx, k] = max(Es(ok));   S = mx / median(E);   z_hat = W.z(ok(k));
end
