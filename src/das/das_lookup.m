function sig = das_lookup(lib, type, dist_m, s, coupling_scale)
% DAS_LOOKUP  Draw one simulated DAS window for an event of a given type at a given distance from its interrogator (bootstrap from the library).
%
%   sig = das_lookup(lib, type, dist_m, s)       s = RandStream
%   sig.dL (window time x channel, the AI input), sig.S, sig.detected (S > lib.thr), sig.z_err [m], sig.snr_db, sig.fs, sig.t, sig.z
%   Distance bin = nearest library distance; one of the lib.n_per_bin simulations of that (type, distance) cell, chosen at random.
%   Type 'normal_vehicle' is looked up as 'vehicle'.
if strcmp(type, 'normal_vehicle'), type = 'vehicle'; end
ti = find(strcmp(lib.types, type), 1);   assert(~isempty(ti), 'das_lookup:type', 'No library entries for %s', type);
[~, di] = min(abs(lib.dist_m - dist_m));
idx = find(lib.type_idx == ti & lib.dist_idx == di);   k = idx(ceil(numel(idx) * rand(s)));
sig = struct('S', lib.S(k), 'detected', lib.S(k) > lib.thr, 'z_err', lib.z_err(k), 'snr_db', lib.snr_db(k), 'dL', lib.dL{k}, 'fs', lib.fs, 't', lib.t, 'z', lib.z, ...
    'lib_index', k, 'type', type, 'dist_m', lib.dist_m(di));
end
