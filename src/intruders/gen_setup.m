function G = gen_setup(T, TP, P, A)
% GEN_SETUP  Precompute everything the daily event generator needs (once per run).
%
%   G = gen_setup(T, TP, P, A)     T twin, TP terrain_pieces, P load_params_fd, A existing assets (camera sites)
%
%   G.w         entry weight of every 5 m boundary piece = piece length x w_entry_wadi^wadi x w_entry_track^track x w_entry_urban^urban
%   G.cellPieces{i}, G.cellCdf{i}   pieces of cell i and the cumulative distribution of their weights
%   G.nrm       inward unit normal of every piece (n x 2)
%   G.ptype     5x5 type proportions per class (rows: wadi, track, urban, slope, flat; columns: walking, running, vehicle, digging, climbing)
%   G.sites     camera sites in coverage (position, nearest piece): where authorized vehicles cross
%   All rates / proportions / weights are ASSUMED or PLACEHOLDER table rows (value_type column).
r = T.cells.ring;   f = P.fd;   n = numel(r.x);
G.w = r.len(:) .* (f.w_entry_wadi .^ TP.wadi) .* (f.w_entry_track .^ (TP.d_track < f.d_track_m)) .* (f.w_entry_urban .^ (TP.d_urban < f.d_urban_m));
G.cellPieces = cell(T.cells.n, 1);   G.cellCdf = cell(T.cells.n, 1);
for i = 1:T.cells.n
    q = find(r.cell(:) == i);   G.cellPieces{i} = q;   c = cumsum(G.w(q));   G.cellCdf{i} = c / c(end);
end
% inward normals: tangent from the neighbours, normal chosen so that a point 50 m along it is inside the boundary polygon
tx = r.x([2:n 1]) - r.x([n 1:n-1]);   ty = r.y([2:n 1]) - r.y([n 1:n-1]);   tl = hypot(tx, ty);   tl(tl == 0) = 1;
nx = ty ./ tl;   ny = -tx ./ tl;
sub = 1:10:n;   inside = inpolygon(r.x(:) + 50 * nx, r.y(:) + 50 * ny, r.x(sub), r.y(sub));
nx(~inside) = -nx(~inside);   ny(~inside) = -ny(~inside);   G.nrm = [nx ny];
% type proportions per class
names = {'p_type_wadi', 'p_type_track', 'p_type_urban', 'p_type_slope', 'p_type_flat'};   G.ptype = zeros(5, 5);
for k = 1:5
    p = sscanf(P.fdstr.(names{k}), '%f/%f/%f/%f/%f')';
    assert(numel(p) == 5 && abs(sum(p) - 1) < 1e-9, 'gen_setup:ptype', 'Bad proportions %s', names{k});
    G.ptype(k, :) = p;
end
G.types = {'walking', 'running', 'vehicle', 'digging', 'climbing'};
% slope at an (x, y) point [m]
Fs = griddedInterpolant({T.dem.lat, T.dem.lon}, double(T.dem.slope_deg), 'linear', 'nearest');
G.slopeAt = @(x, y) Fs(r.lat0 + y / r.ky, r.lon0 + x / r.kx);
% camera sites (where authorized traffic crosses): nearest piece of each
cs = A.sites([A.sites.in]);   G.sites = struct('x', [cs.x]', 'y', [cs.y]', 'name', {{cs.name}'});
[~, G.sitePiece] = min((r.x(:)' - G.sites.x).^2 + (r.y(:)' - G.sites.y).^2, [], 2);
G.km = r.L / 1e3;   G.n = n;
end
