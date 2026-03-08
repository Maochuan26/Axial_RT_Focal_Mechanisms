%% N_Plot_MonthlyFMmap.m
% Generates monthly focal mechanism maps from the historical catalog
% (Event1D_3D_Final.mat), saving one JPG per month to htdocs/FMmap_monthly/.
% Beach ball size is scaled by earthquake magnitude.
% Month range is determined automatically from the data.
% Also regenerates FMmap_monthly.html listing all available monthly maps.
%
% File naming: monthlyFMmap_YYYYMM.jpg
%
% Run after the full pipeline.

clc; clear; close all;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);

%% ---- Load 2015-2021 FM catalog ----
load(fullfile(cfg.dataDir, 'Event1D_3D_Final.mat'));   % loads Po_Clu

%% ---- Remove events with no time or no focal mechanism ----
Po_Clu(isnan([Po_Clu.on])) = [];
hasFM = ~cellfun(@isempty, {Po_Clu.avfnorm});
Po_Clu = Po_Clu(hasFM);

%% ---- Alias for clarity ----
event3D = Po_Clu;

%% ---- Reference event for the magnitude scale bar ----
refEv  = event3D(1);
hasRef = true;

%% ---- Auto-determine month range from data ----
allTimes = [event3D.on];
v0 = datevec(min(allTimes));  yStart = v0(1);  mStart = v0(2);
v1 = datevec(max(allTimes));  yEnd   = v1(1);  mEnd   = v1(2);
fprintf('Data spans %04d-%02d to %04d-%02d\n', yStart, mStart, yEnd, mEnd);

%% ---- Map / visual parameters ----
lonLim      = [-130.031 -129.97];
latLim      = [45.92    45.970 ];
radius_base = 0.0004;    % linear scale: r = Mw * radius_base
scale_event = 1.35;
faultTypes  = {'N','R','S','U'};
faultLabels = {'N - Normal', 'R - Reverse', 'S - Strike-slip', 'U - Unclassified'};
defaultC    = struct('N',[0,0,1],'R',[1,0,0],'S',[0,1,0],'U',[0,0,0]);

%% ---- Output directory ----
outDir = fullfile(cfg.htdocs, 'monthlyFMmap');
if ~exist(outDir, 'dir'); mkdir(outDir); end

%% ---- Enumerate months in range ----
dCur  = datenum(yStart, mStart, 1);
dStop = datenum(yEnd,   mEnd,   1);
months = [];
while dCur <= dStop
    months(end+1) = dCur;  %#ok<AGROW>
    v = datevec(dCur);
    if v(2) == 12
        dCur = datenum(v(1)+1, 1, 1);
    else
        dCur = datenum(v(1), v(2)+1, 1);
    end
end

%% ---- Loop over months ----
for mi = 1:length(months)
    mStart_d = months(mi);
    v  = datevec(mStart_d);
    yr = v(1); mo = v(2);
    if mo == 12
        mEnd_d = datenum(yr+1, 1, 1);
    else
        mEnd_d = datenum(yr, mo+1, 1);
    end

    indEv        = find([event3D.on] >= mStart_d & [event3D.on] < mEnd_d);
    eventsPeriod = event3D(indEv);
    nmec         = length(eventsPeriod);

    dateTag  = sprintf('%04d%02d', yr, mo);
    dateDisp = datestr(mStart_d, 'mmm yyyy');

    %% ---- Figure setup ----
    fig = figure('Position', [100, 100, 950, 900], ...
        'InvertHardcopy', 'off', 'Color', 'white');
    set(fig, 'PaperUnits', 'inches', ...
             'PaperSize',     [9.5 9.0], ...
             'PaperPosition', [0   0   9.5 9.0]);
    ax = axes('Parent', fig, 'Position', [0.13 0.18 0.76 0.65]);

    basemap_2015v2(lonLim, latLim, 100, [0 0], 1, false, ax);
    pbaspect(ax, [diff(lonLim)*cosd(mean(latLim)) diff(latLim) 1]);
    hold(ax, 'on');
    set(ax, 'XTick', -130.03:0.01:-129.97, ...
            'GridLineStyle', '-', 'LineWidth', 0.5, 'GridColor', [0.5 0.5 0.5], ...
            'FontSize', 32);
    grid(ax, 'on');

    %% ---- Plot beach balls — size scaled by magnitude ----
    for i = 1:nmec
        if ~isempty(eventsPeriod(i).avfnorm)
            mag_i = eventsPeriod(i).Mw;
            if isempty(mag_i) || isnan(mag_i); mag_i = 1.0; end
            r = max(0.5, mag_i) * radius_base;
            plot_balloon(eventsPeriod(i).avfnorm, eventsPeriod(i).avslip, ...
                eventsPeriod(i).lon, eventsPeriod(i).lat, ...
                r, scale_event, eventsPeriod(i).color2);
            hold(ax, 'on');
        end
    end

    %% ---- Shallow East region outline ----
    axes(ax);
    plot([-130.00 -129.975 -129.975 -130.00 -130.00], ...
         [45.93   45.93    45.96   45.96   45.93], 'r--', 'LineWidth', 3);

    %% ---- Title and axis labels ----
    title(ax, sprintf('%d FMs  —  %s', nmec, dateDisp), 'FontSize', 42);
    xlabel(ax, 'Longitude (°)', 'FontSize', 36);
    ylabel(ax, 'Latitude (°)',  'FontSize', 36);
    grid(ax, 'on');

    %% ---- Fault-type legend (top-left corner) ----
    legendX  = lonLim(1) + 0.008;
    legendYs = linspace(latLim(2)-0.002, latLim(2)-0.010, 4);
    r_legend = 1.5 * radius_base;   % fixed Mw1.5 size for legend icons

    for k = 1:length(faultTypes)
        idx = find(strcmp({eventsPeriod.faultType}, faultTypes{k}), 1, 'first');
        if ~isempty(idx)
            repEvent = eventsPeriod(idx);
            plot_balloon(repEvent.avfnorm, repEvent.avslip, ...
                legendX, legendYs(k), r_legend, scale_event, repEvent.color2);
        else
            plot(ax, legendX, legendYs(k), 'o', ...
                'MarkerFaceColor', defaultC.(faultTypes{k}), ...
                'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        end
        text(legendX + 0.003, legendYs(k), faultLabels{k}, ...
            'HorizontalAlignment', 'left', 'FontSize', 30, 'Parent', ax);
    end

    legendLeft   = legendX - 0.002;
    legendRight  = legendX + 0.020;
    legendBottom = min(legendYs) - 0.002;
    legendTop    = max(legendYs) + 0.001;
    rectangle(ax, 'Position', [legendLeft, legendBottom, ...
        legendRight-legendLeft, legendTop-legendBottom], ...
        'EdgeColor', 'k', 'LineWidth', 0.5);

    %% ---- Magnitude scale bar (top-right corner) ----
    % Mw 2.0, 1.0, 0.5 top-to-bottom, matching Figure06_West_FM.m style
    magScales = [2.0, 1.0, 0.5];
    scaleX    = lonLim(2) - 0.018;
    scaleYs   = linspace(latLim(2)-0.003, latLim(2)-0.012, 3);
    r_max     = 2.0 * radius_base;   % largest balloon (Mw=2)
    textX     = scaleX + r_max + 0.001;          % fixed text x for all labels

    for k = 1:3
        r_sc = magScales(k) * radius_base;
        plot_balloon(refEv.avfnorm, refEv.avslip, ...
            scaleX, scaleYs(k), r_sc, scale_event, [0.6 0.6 0.6]);
        text(textX, scaleYs(k), sprintf('Mw=%.1f', magScales(k)), ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
            'FontSize', 26, 'Parent', ax);
    end
    text(scaleX, scaleYs(1) + 0.0025, 'Magnitude', ...
        'HorizontalAlignment', 'center', 'FontSize', 26, ...
        'FontWeight', 'bold', 'Parent', ax);

    scaleLeft   = scaleX - r_max - 0.001;
    scaleRight  = textX  + 0.012;
    scaleBottom = min(scaleYs) - 0.002;
    scaleTop    = scaleYs(1) + 0.004;
    rectangle(ax, 'Position', [scaleLeft, scaleBottom, ...
        scaleRight-scaleLeft, scaleTop-scaleBottom], ...
        'EdgeColor', 'k', 'LineWidth', 0.5);

    %% ---- Save ----
    fname = fullfile(outDir, sprintf('monthlyFMmap_%s.jpg', dateTag));
    exportgraphics(fig, fname, 'Resolution', 150, 'BackgroundColor', 'white');
    close(fig);
    fprintf('Saved: monthlyFMmap_%s.jpg  (%d events)\n', dateTag, nmec);
end

%% ---- Rebuild FMmap_monthly.html from all files in outDir ----
allFiles = dir(fullfile(outDir, 'monthlyFMmap_*.jpg'));   % outDir = htdocs/monthlyFMmap/
[~, si]  = sort({allFiles.name}, 'descend');   % most recent first
allFiles = allFiles(si);

htmlFile = fullfile(cfg.htdocs, 'monthlyFMmap.html');
fid = fopen(htmlFile, 'wt');
fprintf(fid, '<!DOCTYPE html>\n<html>\n<head>\n');
fprintf(fid, '<title>Monthly Caldera Focal Mechanism Maps</title>\n');
fprintf(fid, '</head>\n<body>\n\n');
fprintf(fid, '<h2>Monthly Caldera Focal Mechanism Maps</h2>\n');
fprintf(fid, ['<p>Beach ball size is scaled by earthquake magnitude. ' ...
    'Color coding: blue&nbsp;=&nbsp;Normal, red&nbsp;=&nbsp;Reverse, ' ...
    'green&nbsp;=&nbsp;Strike-slip, black&nbsp;=&nbsp;Unclassified.</p>\n\n']);

for fi = 1:length(allFiles)
    fname_only = allFiles(fi).name;
    tok = regexp(fname_only, 'monthlyFMmap_(\d{6})\.jpg', 'tokens');
    if ~isempty(tok)
        ym      = tok{1}{1};
        dispStr = datestr(datenum(str2double(ym(1:4)), str2double(ym(5:6)), 1), 'mmm yyyy');
    else
        dispStr = fname_only;
    end
    fname_rel = sprintf('monthlyFMmap/%s', fname_only);
    fprintf(fid, '%s &mdash; <a href="%s">%s</a>\n<br>\n', ...
        dispStr, fname_rel, fname_only);
end

fprintf(fid, '\n</body>\n</html>\n');
fclose(fid);
fprintf('Updated FMmap_monthly.html (%d monthly maps listed)\n', length(allFiles));
fprintf('Done.\n');
