function el = height_eligibility(ev, obs, P)
% HEIGHT_ELIGIBILITY  Which intruders meet the conditions of the height-from-gait method (Yomna, Engyom/DAS- v2.2-sim), WITHOUT calling it.
%
%   el = height_eligibility(ev, obs, P)     ev from gen_day, obs from das_observe, P from load_params_fd
%   Conditions (all must hold): walking; the fibre detected it; local SNR >= SNR_min_prof (12 dB; the SNR here is the engine's local SNR, to be replaced by
%   her detection_snr_db on the profiling window); the walk is parallel to the fibre (along-boundary walk) within d_lane_max (3 m); at least n_steps_min (8)
%   footsteps on the parallel part (length / step_len_m). A person crossing the fibre fails (her QC) and gets no height: the camera is used.
%   el.ok (logical), el.reason (string: ok | not_walking | not_detected | low_snr | crossing | too_far | too_few_steps)
f = P.fd;   n = height(ev);   reason = repmat("ok", n, 1);
steps = floor(ev.par_m / f.step_len_m);
reason(steps < f.n_steps_min) = "too_few_steps";
reason(ev.lane_m > f.d_lane_max) = "too_far";
reason(~ev.along) = "crossing";
reason(obs.snr_db < f.SNR_min_prof) = "low_snr";
reason(~obs.detected) = "not_detected";
reason(ev.type ~= "walking") = "not_walking";
reason(~ev.is_intrusion) = "not_intrusion";
el = struct('ok', reason == "ok", 'reason', reason, 'n_steps', steps);
end
