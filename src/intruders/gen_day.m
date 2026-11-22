function ev = gen_day(T, TP, G, P, s, day, opts)
% GEN_DAY  One simulated day of events: intrusions (Poisson per zone, spread over cells and entry points) + non-intrusion events.
%
%   ev = gen_day(T, TP, G, P, s, day)                 s = RandStream (reproducible); day = day index
%   ev = gen_day(..., struct('intrusion_only', true)) skip animals / normal vehicles / noise (fast statistics)
%
%   Intrusions : zone rate drawn uniformly from the table range (lambda_* events/day for the WHOLE zone), spread over its cells by
%                risk x length (T.lambda); count per cell ~ Poisson; entry piece ~ weights (wadi / track / urban boosted, ASSUMED);
%                type ~ proportions of the terrain class; random-walk trajectory with drift inward (see walk_path).
%   Others     : animals along the boundary, authorized vehicles at camera sites, background noise windows (PLACEHOLDER rates).
%   Output table ev (one row per event): id, day, t_start (s of day), kind (intrusion|animal|normal_vehicle|noise), type (truth label
%   of the AI: walking, running, vehicle, digging, climbing, animal, no_event), is_intrusion, cell, piece, cls, x, y, speed_mps,
%   das_dur_s (how long the event is visible to the fibre), on_road, path (cell: Kx3 [t x y], intrusions only).
if nargin < 7, opts = struct(); end
io = isfield(opts, 'intrusion_only') && opts.intrusion_only;
c = T.cells;   r = c.ring;   f = P.fd;   zr = T.lambda.zone_range;
% --- intrusions: zone lambda ~ U(range); cell lambda = zone lambda x (cell share of the zone), share = T.lambda.mid / zone mid
lamz = zr(:, 1) + diff(zr, 1, 2) .* rand(s, 3, 1);
lamc = T.lambda.mid(:) ./ mean(zr(c.zoneCode(:), :), 2) .* lamz(c.zoneCode(:));
nI = zeros(c.n, 1);   for i = 1:c.n, nI(i) = poisson(s, lamc(i)); end
N = sum(nI);   cellOf = repelem((1:c.n)', nI);
pAlong = P.fd.p_along;   if isfield(opts, 'p_along'), pAlong = opts.p_along; end
pGroup = P.fd.p_group;   if isfield(opts, 'p_group'), pGroup = opts.p_group; end
isAl = false(N, 1);   parM = zeros(N, 1);   laneM = nan(N, 1);   gsz = ones(N, 1);
piece = zeros(N, 1);   typ = zeros(N, 1);   path = cell(N, 1);   spd = zeros(N, 1);   dur = zeros(N, 1);
t0 = 86400 * rand(s, N, 1);
for k = 1:N
    q = G.cellPieces{cellOf(k)};   piece(k) = q(find(rand(s) <= G.cellCdf{cellOf(k)}, 1));
    cl = TP.cls(piece(k));   typ(k) = find(rand(s) <= cumsum(G.ptype(cl, :)), 1);   gsz(k) = 1;
    if pGroup > 0 && rand(s) < pGroup                              % a GROUP intrusion: 2 to 5 people on foot walking together, 1 to 2 m apart (ASSUMED); one event, one path
        typ(k) = 1 + (rand(s) < 0.3);   gsz(k) = 2 + floor(4 * rand(s));     % walking 70 % / running 30 % of the groups (ASSUMED)
    end
    [p, spd(k), dur(k), al] = walk_path(r, G, P, s, piece(k), typ(k), rand(s) < pAlong);
    p(:, 1) = p(:, 1) + t0(k);   path{k} = p;   isAl(k) = al.is;   parM(k) = al.par_m;   laneM(k) = al.lane_m;
end
ev = mk(N, day, t0, "intrusion", string(G.types(typ))', true(N, 1), cellOf, piece, TP.cls(piece), r, spd, dur, false(N, 1), path);
ev.along = isAl;   ev.par_m = parM;   ev.lane_m = laneM;   ev.group_size = gsz;
if io, return; end
% --- non-intrusion events (no trajectory stored)
nA = poisson(s, f.lam_animal_km_day * G.km);   pa = ceil(G.n * rand(s, nA, 1));
E1 = mk(nA, day, 86400 * rand(s, nA, 1), "animal", repmat("animal", nA, 1), false(nA, 1), r.cell(pa), pa, zeros(nA, 1), r, ones(nA, 1), 20 * ones(nA, 1), false(nA, 1), cell(nA, 1));
nV = poisson(s, f.n_vehicle_site_day * numel(G.sites.x));   pv = G.sitePiece(ceil(numel(G.sites.x) * rand(s, nV, 1)));
E2 = mk(nV, day, 86400 * rand(s, nV, 1), "normal_vehicle", repmat("vehicle", nV, 1), false(nV, 1), r.cell(pv), pv, zeros(nV, 1), r, f.v_vehicle_road * ones(nV, 1), 60 / f.v_vehicle_road * ones(nV, 1), true(nV, 1), cell(nV, 1));
nN = poisson(s, f.lam_noise_km_day * G.km);   pn = ceil(G.n * rand(s, nN, 1));
E3 = mk(nN, day, 86400 * rand(s, nN, 1), "noise", repmat("no_event", nN, 1), false(nN, 1), r.cell(pn), pn, zeros(nN, 1), r, zeros(nN, 1), 10 * ones(nN, 1), false(nN, 1), cell(nN, 1));
E1.along = false(height(E1), 1);   E1.par_m = zeros(height(E1), 1);   E1.lane_m = nan(height(E1), 1);
E2.along = false(height(E2), 1);   E2.par_m = zeros(height(E2), 1);   E2.lane_m = nan(height(E2), 1);
E3.along = false(height(E3), 1);   E3.par_m = zeros(height(E3), 1);   E3.lane_m = nan(height(E3), 1);
E1.group_size = ones(height(E1), 1);   E2.group_size = ones(height(E2), 1);   E3.group_size = ones(height(E3), 1);
ev = [ev; E1; E2; E3];   ev.id = (1:height(ev))';
end

function E = mk(N, day, t0, kind, type, isI, cellv, piece, cls, r, spd, dur, onRoad, path)
% build the event table (N rows)
if N == 0
    cellv = zeros(0, 1);   piece = zeros(0, 1);   cls = zeros(0, 1);   spd = zeros(0, 1);   dur = zeros(0, 1);
end
E = table((1:N)', repmat(day, N, 1), t0(:), repmat(kind, N, 1), type, logical(isI), cellv, piece, cls, r.x(piece), r.y(piece), spd, dur, onRoad, path, ...
    'VariableNames', {'id', 'day', 't_start', 'kind', 'type', 'is_intrusion', 'cell', 'piece', 'cls', 'x', 'y', 'speed_mps', 'das_dur_s', 'on_road', 'path'});
end

function n = poisson(s, lam)
% Poisson count from exponential inter-arrival times with a reproducible stream (no toolbox, works for any lambda)
if lam <= 0, n = 0; return; end
m = ceil(lam + 6 * sqrt(lam) + 10);   t = cumsum(-log(rand(s, m, 1)));
while t(end) < lam, t = [t; t(end) + cumsum(-log(rand(s, m, 1)))]; end %#ok<AGROW>
n = nnz(t < lam);          % unit-rate arrivals in [0, lam): count ~ Poisson(lam)
end
