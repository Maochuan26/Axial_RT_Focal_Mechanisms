%% Run_Pipeline_Daily.m
% Runs the full B→H pipeline for today's date.
% Run once per day in MATLAB R2023a.
% Usage: run('Run_Pipeline_Daily.m')  (from repo root, after FM_buildpath6.m)
%% =========================================================

clc; clear; close all;

%% ---- 0. Paths & date ----
run('FM_buildpath6.m');
addpath /Users/mczhang/Documents/GitHub/FM/01-scripts/subcode/

outDir   = '/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data';
inDir    = '/Applications/MAMP/htdocs/ph2dtInputCatalog';
script_dir = '/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts';

tEnd = floor(now) + datenum(0,0,0,23,59,59);   % end of today
dateTag = datestr(tEnd, 'yyyymmdd');
fprintf('\n========================================\n');
fprintf(' Pipeline run: %s\n', datestr(tEnd, 'yyyy-mm-dd'));
fprintf('========================================\n\n');

%% ============================
%% ---- STAGE B: Read catalog ----
%% ============================
fprintf('--- B: Reading past 30 days of catalog ---\n');

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

B_outfile = fullfile(outDir, sprintf('B_ph2dt_past30days_combined_until_%s.mat', dateTag));
save(B_outfile, 'ph2dt', '-v7.3');
fprintf('B done: %d events -> %s\n\n', numel(ph2dt), B_outfile);

%% ============================
%% ---- STAGE C: Build Felix ----
%% ============================
fprintf('--- C: Building Felix struct ---\n');

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

C_outfile = fullfile(outDir, 'C_ph2dt.mat');
save(C_outfile, 'Felix');
fprintf('C done: %d events -> C_ph2dt.mat\n\n', numel(Felix));

%% ============================
%% ---- STAGE D: Get waveforms ----
%% ============================
fprintf('--- D: Downloading waveforms ---\n');
run(fullfile(script_dir, 'D_getwaveform.m'));
fprintf('D done.\n\n');

%% ============================
%% ---- STAGE E: NSP ratios + snippets ----
%% ============================
fprintf('--- E: Computing NSP ratios and W snippets ---\n');
run(fullfile(script_dir, 'E_SP_wave.m'));
fprintf('E done.\n\n');

%% ============================
%% ---- STAGE F: ML polarity ----
%% ============================
fprintf('--- F: ML polarity prediction ---\n');
run(fullfile(script_dir, 'F_Po.m'));
fprintf('F done.\n\n');

%% ============================
%% ---- STAGE G: Matching ----
%% ============================
fprintf('--- G: Matching to base catalog ---\n');
run(fullfile(script_dir, 'G_Cl.m'));
fprintf('G done.\n\n');

%% ============================
%% ---- STAGE H: HASH focal mechanisms ----
%% ============================
fprintf('--- H: Computing focal mechanisms ---\n');
run(fullfile(script_dir, 'H_FM.m'));
fprintf('H done.\n\n');

%% ============================
%% ---- STAGE I: Plot FMs + update website ----
%% ============================
fprintf('--- I: Plotting focal mechanisms and updating website ---\n');
run(fullfile(script_dir, 'I_Plot_FM.m'));
fprintf('I done (website updated).\n\n');

%% ============================
fprintf('========================================\n');
fprintf(' Pipeline complete: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf('========================================\n');
load handel; sound(y, Fs);
