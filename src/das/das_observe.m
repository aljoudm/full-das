function obs = das_observe(ev, T, alloc, lib, s)
% DAS_OBSERVE  What the DAS sees for every event: distance to the interrogator, a simulated window (library), detection and localization.
%
%   obs = das_observe(ev, T, alloc, lib, s)       ev = table from gen_day; alloc from get_allocation; lib from build_das_library; s RandStream
%
%   obs (table, one row per event): dist_m (along the fibre to the nearest interrogator, every cell has DAS in the base case), detected (S > threshold),
%   S, z_err_m, x_hat / y_hat (estimated position on the boundary = piece at the arc position + z_err), snr_db, lib_index (window for the AI).
%   Only events whose fibre run carries DAS can be seen: alloc.cells.DAS is 1 for the cell of the event.
r = T.cells.ring;   L = r.L;   arc = alloc.interrogators.arc_m(:)';   n = height(ev);
sp = r.s(ev.piece);   sp = sp(:);
d = abs(sp - arc);   d = min(d, L - d);   dist = min(d, [], 2);
hasDAS = logical(alloc.cells.DAS(ev.cell));
S = nan(n, 1);   det = false(n, 1);   ze = nan(n, 1);   snr = nan(n, 1);   li = nan(n, 1);   xh = nan(n, 1);   yh = nan(n, 1);
for k = 1:n
    if ~hasDAS(k), continue; end
    sg = das_lookup(lib, char(ev.type(k)), min(dist(k), max(lib.dist_m)), s);
    S(k) = sg.S;   det(k) = sg.detected;   ze(k) = sg.z_err;   snr(k) = sg.snr_db;   li(k) = sg.lib_index;
    % estimated position: shift the true piece along the boundary by the localization error (arc distance, sign random)
    q = find(r.s >= sp(k) + sign(randn(s)) * ze(k), 1);   if isempty(q), q = ev.piece(k); end
    xh(k) = r.x(q);   yh(k) = r.y(q);
end
obs = table(dist, det, S, ze, xh, yh, snr, li, 'VariableNames', {'dist_m', 'detected', 'S', 'z_err_m', 'x_hat', 'y_hat', 'snr_db', 'lib_index'});
end
