function P = load_params_fd(tsvFile)
% LOAD_PARAMS_FD  Read the full-das parameter table (10 columns, last = value_type) with the FROZEN optimization loader.
%
%   P = load_params_fd()           uses config/parameters_reviewed.tsv
%   P = load_params_fd(tsvFile)
%
% The frozen load_params.m expects exactly 9 columns. This wrapper writes a temporary 9-column copy (drops value_type) and calls
% it, so the third-party file stays byte-for-byte unchanged. P.value_type is added as a containers.Map symbol -> value_type.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(tsvFile), tsvFile = fullfile(root, 'config', 'parameters_reviewed.tsv'); end
assert(isfile(tsvFile), 'load_params_fd:noFile', 'Parameter table not found: %s', tsvFile);
lines = splitlines(string(fileread(tsvFile, 'Encoding', 'UTF-8')));
lines = lines(strlength(strtrim(lines)) > 0);
vt = containers.Map('KeyType', 'char', 'ValueType', 'char');
out = strings(numel(lines), 1);
for r = 1:numel(lines)
    c = split(lines(r), char(9));
    assert(numel(c) == 10, 'load_params_fd:badRow', 'Row %d has %d columns (expected 10).', r, numel(c));
    if r > 1, vt(char(strtrim(c(1)))) = char(strtrim(c(10))); end
    out(r) = strjoin(c(1:9), char(9));
end
tmp = [tempname '.tsv'];
fid = fopen(tmp, 'w', 'n', 'UTF-8');   fprintf(fid, '%s\n', out);   fclose(fid);
cleanup = onCleanup(@() delete(tmp));
P = load_params(tmp);
P.tsvFile = string(tsvFile);   P.value_type = vt;
% rows added by full-das that the frozen loader does not know: read them here (numeric value of the table row)
P.fd = struct();   P.fdstr = struct();
for r = 2:numel(lines)
    c = split(lines(r), char(9));   sym = matlab.lang.makeValidName(char(strtrim(c(1))));
    x = str2double(strtrim(c(4)));   if ~isnan(x), P.fd.(sym) = x; end
    P.fdstr.(sym) = char(strtrim(c(4)));          % raw text of the value (ranges, slash-separated proportions)
end
end
