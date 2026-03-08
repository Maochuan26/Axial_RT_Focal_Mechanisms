%% Run_Pipeline_Daily.m
% Runs the full A→I pipeline for today's date.
% Run once per day in MATLAB R2023a.
% Usage: run('Run_Pipeline_Daily.m')  (from repo root, after FM_buildpath6.m)
%% =========================================================

clc; clear; close all;

%% ---- 0. Paths & date ----
run('config.m');

outDir     = cfg.dataDir;
inDir      = fullfile(cfg.htdocs, 'ph2dtInputCatalog');
script_dir = cfg.scriptsDir;

tEnd = floor(now) + datenum(0,0,0,23,59,59);   % end of today
dateTag = datestr(tEnd, 'yyyymmdd');
fprintf('\n========================================\n');
fprintf(' Pipeline run: %s\n', datestr(tEnd, 'yyyy-mm-dd'));
fprintf('========================================\n\n');

%% ============================
%% ---- Archive previous day's outputs ----
%% ============================
archiveDir = fullfile(outDir, 'archive', dateTag);
if ~exist(archiveDir, 'dir'); mkdir(archiveDir); end

filesToArchive = {'B_ph2dt.mat', 'C_wave2.mat', 'D_NSP.mat', ...
                  'E_DLpol.mat', 'F_Cl.mat', 'G_FM.mat'};
fprintf('--- Archiving previous outputs to archive/%s/ ---\n', dateTag);
for k = 1:numel(filesToArchive)
    src = fullfile(outDir, filesToArchive{k});
    if isfile(src)
        copyfile(src, fullfile(archiveDir, filesToArchive{k}));
        fprintf('  Archived: %s\n', filesToArchive{k});
    end
end
fprintf('\n');

%% ============================
%% ---- STAGE A: Read catalog ----
%% ============================
fprintf('--- A: Reading past 30 days of catalog ---\n');

d = dir(fullfile(inDir, 'ph2dtInputCatalog_*.dat'));
assert(~isempty(d), 'No ph2dtInputCatalog_*.dat files found in %s', inDir);

fileDates = nan(size(d));
for k = 1:numel(d)
    tok = regexp(d(k).name, 'ph2dtInputCatalog_(\d{8})\.dat', 'tokens', 'once');
    if ~isempty(tok)
        ymd = tok{1};
        fileDates(k) = datenum(str2double(ymd(1:4)), str2double(ymd(5:6)), str2double(ymd(7:8)));
    end
end

mask = ~isnan(fileDates) & (fileDates > (tEnd - 30)) & (fileDates <= tEnd);
d30  = d(mask);
fd30 = fileDates(mask);
[fd30, order] = sort(fd30);
d30 = d30(order);
fprintf('Found %d daily files in past 30 days.\n', numel(d30));

ph2dt  = struct([]);
nTotal = 0;
for k = 1:numel(d30)
    f = fullfile(inDir, d30(k).name);
    if ~isfile(f); warning('Missing: %s', f); continue; end
    info = dir(f);
    if info.bytes == 0; warning('Zero-byte: %s', d30(k).name); continue; end
    tmp = read_ph2dtCatalogTTData_FM(f);
    if isempty(ph2dt); ph2dt = tmp; else; ph2dt = [ph2dt(:); tmp(:)]; end
    nTotal = nTotal + numel(tmp);
    fprintf('  %s -> %d events (total %d)\n', d30(k).name, numel(tmp), nTotal);
end

[~, ix] = sort([ph2dt.datenum]);
ph2dt = ph2dt(ix);

% Stage A output is not used by Stage B (B builds Felix inline from ph2dt in workspace)
A_outfile = fullfile(outDir, sprintf('A_ph2dt_past30days_combined_until_%s.mat', dateTag));
save(A_outfile, 'ph2dt', '-v7.3');
fprintf('A done: %d events -> %s\n\n', numel(ph2dt), A_outfile);

%% ============================
%% ---- STAGE B: Build Felix ----
%% ============================
fprintf('--- B: Building Felix struct ---\n');

staMap = { ...
    'AXAS1','AS1'; 'AXAS2','AS2'; 'AXCC1','CC1'; ...
    'AXEC1','EC1'; 'AXEC2','EC2'; 'AXEC3','EC3'; 'AXID1','ID1' };

nEv   = length(ph2dt);
Felix = struct([]);

for i = 1:nEv
    Felix(i).ID    = ph2dt(i).ID;
    Felix(i).on    = ph2dt(i).datenum;
    Felix(i).lat   = ph2dt(i).lat;
    Felix(i).lon   = ph2dt(i).lon;
    Felix(i).depth = ph2dt(i).depth;
    Felix(i).mag   = ph2dt(i).mag;

    for k = 1:size(staMap,1)
        tag = staMap{k,2};
        Felix(i).(['DDt_'  tag]) = NaN;
        Felix(i).(['DDSt_' tag]) = NaN;
    end

    for j = 1:length(ph2dt(i).obs.tt)
        sta   = ph2dt(i).obs.sta{j};
        phase = ph2dt(i).obs.phase{j};
        tt    = ph2dt(i).obs.tt(j);
        row   = find(strcmp(staMap(:,1), sta), 1);
        if isempty(row); continue; end
        tag = staMap{row,2};
        if     strcmp(phase,'P'); Felix(i).(['DDt_'  tag]) = tt;
        elseif strcmp(phase,'S'); Felix(i).(['DDSt_' tag]) = tt;
        end
    end

    PSpair = 0;
    for k = 1:size(staMap,1)
        tag = staMap{k,2};
        if ~isnan(Felix(i).(['DDt_' tag])) && ~isnan(Felix(i).(['DDSt_' tag]))
            PSpair = PSpair + 1;
        end
    end
    Felix(i).PSpair = PSpair;
end

B_outfile = fullfile(outDir, 'B_ph2dt.mat');
save(B_outfile, 'Felix');
fprintf('B done: %d events -> B_ph2dt.mat\n\n', numel(Felix));

%% ============================
%% ---- STAGE C: Get waveforms ----
%% ============================
fprintf('--- C: Downloading waveforms ---\n');
run(fullfile(script_dir, 'C_getwaveform.m'));
fprintf('C done.\n\n');

%% ============================
%% ---- STAGE D: NSP ratios + snippets ----
%% ============================
fprintf('--- D: Computing NSP ratios and W snippets ---\n');
run(fullfile(script_dir, 'D_SP_wave.m'));
fprintf('D done.\n\n');

%% ============================
%% ---- STAGE E: ML polarity ----
%% ============================
fprintf('--- E: ML polarity prediction ---\n');
run(fullfile(script_dir, 'E_Po.m'));
fprintf('E done.\n\n');

%% ============================
%% ---- STAGE F: Matching ----
%% ============================
fprintf('--- F: Matching to base catalog ---\n');
run(fullfile(script_dir, 'F_Cl.m'));
fprintf('F done.\n\n');

%% ============================
%% ---- STAGE G: HASH focal mechanisms ----
%% ============================
fprintf('--- G: Computing focal mechanisms ---\n');
run(fullfile(script_dir, 'G_FM.m'));
fprintf('G done.\n\n');

%% ============================
%% ---- STAGE H: Plot focal mechanisms ----
%% ============================
fprintf('--- H: Plotting focal mechanisms ---\n');
run(fullfile(script_dir, 'H_Plot_FM.m'));
fprintf('H done.\n\n');

%% ============================
%% ---- STAGE J: 2015 Eruption FM figures ----
%% ============================
fprintf('--- J: Plotting 2015 eruption focal mechanisms ---\n');
run(fullfile(script_dir, 'J_Plot_Eruption2015.m'));
fprintf('J done.\n\n');

%% ============================
%% ---- STAGE K: Histogram figures ----
%% ============================
fprintf('--- K: Plotting activity histograms ---\n');
run(fullfile(script_dir, 'K_Plot_Histograms.m'));
fprintf('K done.\n\n');

%% ============================
%% ---- STAGE L: Full catalog FM histograms (2015-2021, static) ----
%% ============================
fprintf('--- L: Plotting full-catalog FM histograms ---\n');
run(fullfile(script_dir, 'L_Plot_FullCatalog.m'));
fprintf('L done.\n\n');

%% ============================
%% ---- STAGE I: Update FM website (final step) ----
%% ============================
fprintf('--- I: Updating FM website ---\n');
run(fullfile(script_dir, 'I_UpdateFMWebsite.m'));
fprintf('I done (website updated).\n\n');

%% ============================
fprintf('========================================\n');
fprintf(' Pipeline complete: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('========================================\n');
load handel; sound(y, Fs);
