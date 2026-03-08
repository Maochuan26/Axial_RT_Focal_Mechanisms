%% C_getwaveform.m
% Downloads waveforms for all Felix events via IRIS FDSN.
%
% Optimizations vs original:
%   1. Incremental cache: events already in C_wave2.mat are skipped.
%   2. Batch concurrent download: all new events are downloaded in parallel
%      via get_traces_batch.py (ThreadPoolExecutor), one IRIS bulk request
%      per event, --workers concurrent threads.
%   3. Single subprocess call: no per-event file I/O (old py_trace.mat).
%
% Input:  02-data/B_ph2dt.mat  (Felix struct)
% Output: 02-data/C_wave2.mat  (Felix struct with .trace field added)

clc; clear;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);

load(fullfile(cfg.dataDir, 'B_ph2dt.mat'));

% Filter: require at least 6 P-S pairs
Felix([Felix.PSpair] < 6) = [];
nCurrent = numel(Felix);
fprintf('Events after PSpair filter: %d\n', nCurrent);

%% ---- Incremental cache: skip already-downloaded events ----
cache_file  = fullfile(cfg.dataDir, 'C_wave2.mat');
Felix_cache = struct([]);
cached_IDs  = [];

if isfile(cache_file)
    tmp = load(cache_file, 'Felix');
    Felix_cache = tmp.Felix;
    cached_IDs  = [Felix_cache.ID];
    fprintf('Cache: %d events already have waveforms.\n', numel(Felix_cache));
end

all_IDs = [Felix.ID];
is_new  = ~ismember(all_IDs, cached_IDs);
Felix_new = Felix(is_new);
fprintf('New events to download: %d / %d\n', numel(Felix_new), nCurrent);

%% ---- Batch concurrent download for new events ----
if numel(Felix_new) > 0
    tmp_in  = fullfile(cfg.dataDir, 'C_batch_in.mat');
    tmp_out = fullfile(cfg.dataDir, 'C_batch_out.mat');

    % Save new events for Python (variable name 'Felix' expected by script)
    F = Felix_new; %#ok<NASGU>
    save(tmp_in, 'F');

    py_script = fullfile(cfg.subcodeDir, 'get_traces_batch.py');
    cmd = sprintf('"%s" "%s" "%s" "%s" --workers 10', ...
        cfg.pythonExe, py_script, tmp_in, tmp_out);
    fprintf('Running batch downloader (%d events, 10 threads)...\n', numel(Felix_new));
    [status, output] = system(cmd);
    disp(output);
    if status ~= 0
        warning('Batch download returned status %d — continuing with empty traces.', status);
    end

    % Load results and assign traces
    if isfile(tmp_out)
        res = load(tmp_out, 'traces');
        traces_cell = res.traces;
        for i = 1:numel(Felix_new)
            if iscell(traces_cell)
                tr = traces_cell{i};
            else
                % Loaded as struct array (edge case)
                tr = traces_cell(i);
            end
            if isstruct(tr) && ~isempty(fieldnames(tr))
                Felix_new(i).trace = tr;
            else
                Felix_new(i).trace = [];
            end
        end
    else
        warning('Batch output not found: %s — all new traces set to empty.', tmp_out);
        for i = 1:numel(Felix_new)
            Felix_new(i).trace = [];
        end
    end

    % Clean up temp files
    if isfile(tmp_in);  delete(tmp_in);  end
    if isfile(tmp_out); delete(tmp_out); end
else
    fprintf('No new events to download.\n');
end

%% ---- Merge cache + new, keep only current events, sort by origin time ----
% Cached events that are still in the current 30-day window
still_current = ismember(cached_IDs, all_IDs);
Felix_from_cache = Felix_cache(still_current);

if ~isempty(Felix_from_cache) && ~isempty(Felix_new)
    Felix = [Felix_from_cache(:); Felix_new(:)];
elseif ~isempty(Felix_from_cache)
    Felix = Felix_from_cache;
else
    Felix = Felix_new;
end

[~, ix] = sort([Felix.on]);
Felix = Felix(ix);

%% ---- Save ----
save(fullfile(cfg.dataDir, 'C_wave2.mat'), 'Felix');
fprintf('C done: %d events -> C_wave2.mat\n', numel(Felix));
