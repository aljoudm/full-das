function [path, v_mean, das_dur] = walk_path(r, G, P, s, piece, typ)
% WALK_PATH  Trajectory of one intruder from the boundary piece inward: random walk with drift, terrain-dependent speed.
%
%   [path, v_mean, das_dur] = walk_path(r, G, P, s, piece, typ)    typ 1 walking, 2 running, 3 vehicle, 4 digging, 5 climbing
%   path = [t x y] at 1 s steps (t from 0 at the fibre). Digging / climbing first stay at the boundary (dur_dig_s / dur_climb_s,
%   uniform 0.5x to 2x) and then walk. Speed = nominal x slope factor (1 - 0.5 min(slope/30 deg, 1), floor 0.4) x (1 + 10 % noise).
%   das_dur = how long the event is visible to the fibre: the stay for digging / climbing, otherwise the time within 30 m of it.
f = P.fd;   n0 = G.nrm(piece, :);   p0 = [r.x(piece) r.y(piece)];   h_in = atan2(n0(2), n0(1));
switch typ
    case 1, v0 = f.v_walk + 0.2 * randn(s);
    case 2, v0 = f.v_run + 0.5 * randn(s);
    case 3, v0 = f.v_vehicle_off + 2 * randn(s);
    otherwise, v0 = f.v_walk + 0.2 * randn(s);
end
v0 = max(v0, 0.3);   stay = 0;
if typ == 4, stay = f.dur_dig_s * (0.5 + 1.5 * rand(s)); elseif typ == 5, stay = f.dur_climb_s * (0.5 + 1.5 * rand(s)); end
nst = ceil(stay);   tmax = nst + f.t_traj_max_s;   buf = zeros(tmax + 2, 3);   pos = p0;   h = h_in + 0.5 * randn(s);
buf(1, :) = [0 pos];   k = 1;
for t = 1:nst, k = k + 1; buf(k, :) = [t pos]; end                         % stationary phase (digging / climbing)
t = nst;
while t < tmax
    t = t + 1;
    h = h + f.heading_sigma * randn(s) + f.heading_pull * sin(h_in - h);
    sl = G.slopeAt(pos(1), pos(2));   sp = v0 * max(0.4, 1 - 0.5 * min(sl / 30, 1)) * (1 + 0.1 * randn(s));
    pos = pos + max(sp, 0.1) * [cos(h) sin(h)];
    k = k + 1;   buf(k, :) = [t pos];
    if (pos - p0) * n0' >= f.d_inward_end_m, break; end
end
path = buf(1:k, :);   v_mean = v0;
if stay > 0, das_dur = stay; else, das_dur = 60 / v0; end
end
