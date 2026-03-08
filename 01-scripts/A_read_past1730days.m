%% =========================================================
% Combine past 30 days of daily ph2dtInputCatalog_YYYYMMDD.dat
% into one ph2dt struct array and save
% "today" fixed to Feb 25, 2026
%% =========================================================
clc; clear;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);
inDir = fullfile(cfg.htdocs, 'ph2dtInputCatalog');

% Define "today" (end-of-day)
tEnd = datenum(2026, 3, 1, 23, 59, 59);

% Find all daily files
d = dir(fullfile(inDir, 'ph2dtInputCatalog_*.dat'));
assert(~isempty(d), 'No ph2dtInputCatalog_*.dat files found in %s', inDir);

% Extract YYYYMMDD from filename
fileDates = nan(size(d));
for k = 1:numel(d)
    tok = regexp(d(k).name, 'ph2dtInputCatalog_(\d{8})\.dat', 'tokens', 'once');
    if ~isempty(tok)
        ymd = tok{1}; % string like '20240815'
        y = str2double(ymd(1:4));
        m = str2double(ymd(5:6));
        dd = str2double(ymd(7:8));
        fileDates(k) = datenum(y, m, dd);
    end
end

% Keep only files within past 30 days (inclusive of today)
mask = ~isnan(fileDates) & (fileDates > (tEnd - 30)) & (fileDates <= tEnd);
d30 = d(mask);
fd30 = fileDates(mask);

% Sort by day (oldest -> newest)
[fd30, order] = sort(fd30);
d30 = d30(order);

fprintf('Found %d daily files in past 30 days.\n', numel(d30));

% Read + concatenate
ph2dt = struct([]);
nTotal = 0;

for k = 1:numel(d30)
    f = fullfile(inDir, d30(k).name);
    
    % Robust existence check
    if ~isfile(f)   % (R2017b+). If old MATLAB, use: if exist(f,'file')~=2
        warning('Missing file, skipped: %s', f);
        continue
    end
    % Skip zero-byte files
    info = dir(f);
    if info.bytes == 0
        warning('Zero-byte file, skipped: %s', d30(k).name);
        continue
    end
    tmp = read_ph2dtCatalogTTData_FM(f);
    % Append
    if isempty(ph2dt)
        ph2dt = tmp;
    else
        ph2dt = [ph2dt(:); tmp(:)]; %#ok<AGROW>
    end

    nTotal = nTotal + numel(tmp);
    fprintf('%s  -> %d events (running total %d)\n', d30(k).name, numel(tmp), nTotal);
end

% Optional: sort combined events by origin time
[~,ix] = sort([ph2dt.datenum]);
ph2dt = ph2dt(ix);
outDir = cfg.dataDir;
% Save combined output
outFile = fullfile(outDir, sprintf('A_ph2dt_past30days_combined_until_%s.mat', datestr(tEnd,'yyyymmdd')));
save(outFile, 'ph2dt', '-v7.3');

%fprintf('DONE. Combined events: %d\nSaved: %s\n', numel(ph2dt), outFile);