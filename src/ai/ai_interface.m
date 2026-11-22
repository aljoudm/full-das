function out = ai_interface(op, varargin)
% AI_INTERFACE  THE ONE PLACE where the AI contract lives (it may change when Yomna replies). Everything else calls this function.
%
%   cfg = ai_interface('config')                              settings from config/ai_config.json (use_real_ai, stub mode, Pc, confusion file)
%   r   = ai_interface('classify_event', window)              r.class, r.confidence    window = struct with .dL (time x channel) and, for the STUB only, .truth
%   r   = ai_interface('classify_batch', truth, s)            vectorised stub for the Monte Carlo: truth = cellstr / string of true classes, s = RandStream
%   (stage 7: 'reidentify')
%
%   Classes (contract): walking, running, vehicle, digging, climbing, animal, no_event  (+ 'other' when the confusion file has it: a non-threat class).
%   use_real_ai = false -> TEMPORARY STUB below (marked PLACEHOLDER everywhere it is reported).
%   use_real_ai = true  -> py.ai_real.classify_event(window) through pyenv(Version="3.13", ExecutionMode="OutOfProcess"); the file is ai/ai_real.py
%                          (same signature). Not connected yet: it errors on purpose instead of silently falling back.
switch op
    case 'config',          out = read_cfg();
    case 'classify_event',  out = classify_one(varargin{1}, read_cfg());
    case 'classify_batch',  out = classify_batch(varargin{1}, varargin{2}, read_cfg());
    otherwise, error('ai_interface:op', 'Unknown operation %s', op);
end
end

function cfg = read_cfg()
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
cfg = jsondecode(fileread(fullfile(root, 'config', 'ai_config.json')));   cfg.root = root;
end

function r = classify_one(win, cfg)
if cfg.use_real_ai
    error('ai_interface:real', 'use_real_ai = true but ai/ai_real.py is not connected yet (waiting for the real AI).');
end
rr = classify_batch(string(win.truth), RandStream('Threefry', 'Seed', 1), cfg);   r = struct('class', rr.class(1), 'confidence', rr.confidence(1), 'stub', true);
end

function r = classify_batch(truth, s, cfg)
% TEMPORARY STUB. Output class drawn from the confusion row of the true class (mode 'confusion') or 'uniform' errors.
truth = string(truth(:));   n = numel(truth);
spec = ["walking" "running" "vehicle" "digging" "climbing" "animal" "no_event"];
cls = truth;   conf = zeros(n, 1);
if cfg.classifier.mode == "confusion"
    J = jsondecode(fileread(fullfile(cfg.root, char(cfg.classifier.confusion_file))));   names = string(J.classes);   M = J.row_normalised;
    for k = 1:n
        i = find(names == truth(k), 1);
        if isempty(i) || sum(M(i, :)) == 0, cls(k) = uniform_one(truth(k), spec, cfg.classifier.Pc, s);   % class without data (animal): PLACEHOLDER
        else, cls(k) = names(find(rand(s) <= cumsum(M(i, :) / sum(M(i, :))), 1));
        end
    end
else
    for k = 1:n, cls(k) = uniform_one(truth(k), spec, cfg.classifier.Pc, s); end
end
ok = cls == truth;   conf(ok) = 0.6 + 0.4 * rand(s, nnz(ok), 1);   conf(~ok) = 0.4 + 0.4 * rand(s, nnz(~ok), 1);   % PLACEHOLDER confidence
r = struct('class', cls, 'confidence', conf, 'stub', true);
end

function c = uniform_one(t, spec, Pc, s)
if rand(s) <= Pc, c = t; else, o = spec(spec ~= t);   c = o(ceil(numel(o) * rand(s))); end
end
