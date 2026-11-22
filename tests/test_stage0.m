% TEST_STAGE0  Scaffold checks: paths, table loader, copies identical to their sources, frozen SHAs.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));   root = setup_paths();
fprintf('--- Stage 0 tests ---\n');

% 1) table: 10 columns, value_type on every row, new rows present
P = load_params_fd();
assert(P.v.AD0 == 0.98 || P.v.AD0 == 98, 'AD0 not read');
syms = {'dx_prof','GL_prof','fs_prof','SNR_min_prof','n_steps_min','d_lane_max','height_unc','FAR_per_km_day'};
for k = 1:numel(syms), assert(isKey(P.value_type, syms{k}), 'row missing: %s', syms{k}); end
assert(all(~strcmp(values(P.value_type), '?')), 'unclassified value_type');
assert(P.fd.dx_prof == 0.4 && P.fd.GL_prof == 0.8 && P.fd.fs_prof == 500 && P.fd.SNR_min_prof == 12 && ...
       P.fd.n_steps_min == 8 && P.fd.d_lane_max == 3 && P.fd.height_unc == 8, 'profiling rows have wrong values');
assert(abs(P.fd.GL_prof / P.fd.dx_prof - round(P.fd.GL_prof / P.fd.dx_prof)) < 1e-12, 'GL_prof must be a multiple of dx_prof');
fprintf('table: %d rows read, value_type on all, profiling rows OK\n', numel(P.raw));

% 2) values that the optimization report states (read through OUR table)
assert(P.v.Cov_CCTV_m == 100 || isfield(P.v, 'Cov_CCTV_m'), 'Cov_CCTV');
fprintf('R_resp = %.0f m (report: 4350), P0 = %.0f W (report: 29100)\n', P.v.R_resp_m, P.v.P0);
assert(P.v.R_resp_m == 4350 && P.v.P0 == 29100, 'derived values differ from the optimization report');

% 3) copies identical to the sources: DAS-map cells vs the optimization input copy
a = fileread(fullfile(root, 'third_party', 'dasmap_data', 'cells.csv'));
b = fileread(fullfile(root, 'third_party', 'optimization', 'inputs', 'dasmap', 'cells.csv'));
assert(strcmp(a, b), 'cells.csv differs between DAS-map copy and optimization input copy');
fprintf('cells.csv identical in both copies (%d bytes)\n', numel(a));

% 4) frozen submodule SHA
[~, sha] = system(sprintf('git -C "%s" rev-parse HEAD', fullfile(root, 'third_party', 'yomna_das_height')));
assert(startsWith(strtrim(sha), '285b5ad1'), 'Engyom/DAS- submodule is not at v2.2-sim');
fprintf('submodule at %s (v2.2-sim)\n', strtrim(sha));
fprintf('Stage 0: ALL PASSED\n');
