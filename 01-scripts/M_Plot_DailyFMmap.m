%% M_Plot_DailyFMmap.m
% Generates daily focal mechanism maps from the historical catalog
% (Event1D_3D_Final.mat), saving one JPG per day to htdocs/FMmap/.
%
% File naming: dailyFMmap_YYYYMMDD.jpg  (matches FMmap.html links)
%
% Usage: set dStart/dEnd below, then run.

clc; clear; close all;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);

%% ---- Date range (edit here) ----
dStart = datenum(2021,  9,  1);
dEnd   = datenum(2021, 10,  3);

%% ---- Load historical FM catalog ----
load(fullfile(cfg.dataDir, 'Event1D_3D_Final.mat'));  % event3D (has .time already)

%% ---- Remove events with no time; keep all quality grades (A/B/C/D) ----
event3D(isnan([event3D.time])) = [];
for i = 1:length(event3D)
    event3D(i).color3 = event3D(i).color2;   % full color for all grades
end

%% ---- Map / visual parameters (same as H_Plot_FM.m) ----
lonLim      = [-130.031 -129.97];
latLim      = [45.92    45.970];
radius      = 0.0005;
scale_event = 1.3;
faultTypes  = {'N','R','S','U'};
faultLabels = {'N - Normal', 'R - Reverse', 'S - Strike-slip', 'U - Unclassified'};
defaultC    = struct('N',[0,0,1],'R',[1,0,0],'S',[0,1,0],'U',[0,0,0]);

%% ---- Output directory ----
outDir = fullfile(cfg.htdocs, 'FMmap');
if ~exist(outDir, 'dir'); mkdir(outDir); end

%% ---- Loop over days ----
for dNum = dStart:dEnd

    tNext = dNum + 1;
    indEv = find([event3D.time] >= dNum & [event3D.time] < tNext);
    eventsPeriod = event3D(indEv);
    nmec = length(eventsPeriod);

    dateTag  = datestr(dNum, 'yyyymmdd');
    dateDisp = datestr(dNum, 'dd-mmm-yyyy');

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

    %% ---- Plot beach balls ----
    for i = 1:nmec
        if ~isempty(eventsPeriod(i).avfnorm)
            plot_balloon(eventsPeriod(i).avfnorm, eventsPeriod(i).avslip, ...
                eventsPeriod(i).lon, eventsPeriod(i).lat, ...
                radius, scale_event, eventsPeriod(i).color3);
            hold(ax, 'on');
        end
    end

    %% ---- Shallow East region outline ----
    axes(ax);
    plot([-130.00 -129.975 -129.975 -130.00 -130.00], ...
         [45.93   45.93    45.96   45.96   45.93], 'r--', 'LineWidth', 3);

    %% ---- Labels ----
    title(ax, sprintf('%d FMs  —  %s', nmec, dateDisp), 'FontSize', 42);
    xlabel(ax, 'Longitude (°)', 'FontSize', 36);
    ylabel(ax, 'Latitude (°)',  'FontSize', 36);
    grid(ax, 'on');

    %% ---- Legend ----
    legendX  = lonLim(1) + 0.008;
    legendYs = linspace(latLim(2)-0.002, latLim(2)-0.010, 4);

    for k = 1:length(faultTypes)
        idx = find(strcmp({eventsPeriod.faultType}, faultTypes{k}), 3, 'first');
        if numel(idx) >= 2
            repEvent = eventsPeriod(idx(2));
            plot_balloon(repEvent.avfnorm, repEvent.avslip, ...
                legendX, legendYs(k), radius, scale_event, repEvent.color2);
        elseif numel(idx) == 1
            repEvent = eventsPeriod(idx(1));
            plot_balloon(repEvent.avfnorm, repEvent.avslip, ...
                legendX, legendYs(k), radius, scale_event, repEvent.color2);
        else
            plot(ax, legendX, legendYs(k), 'o', ...
                'MarkerFaceColor', defaultC.(faultTypes{k}), ...
                'MarkerEdgeColor', 'k', 'MarkerSize', 8);
        end
        text(legendX + 0.003, legendYs(k), faultLabels{k}, ...
            'HorizontalAlignment', 'left', 'FontSize', 30, 'Parent', ax);
    end

    % Legend box
    legendLeft   = legendX - 0.002;
    legendRight  = legendX + 0.020;
    legendBottom = min(legendYs) - 0.002;
    legendTop    = max(legendYs) + 0.001;
    rectangle(ax, 'Position', [legendLeft, legendBottom, ...
        legendRight-legendLeft, legendTop-legendBottom], ...
        'EdgeColor', 'k', 'LineWidth', 0.5);

    %% ---- Save ----
    fname = fullfile(outDir, sprintf('dailyFMmap_%s.jpg', dateTag));
    exportgraphics(fig, fname, 'Resolution', 150, 'BackgroundColor', 'white');
    close(fig);
    fprintf('Saved: dailyFMmap_%s.jpg  (%d events)\n', dateTag, nmec);

end

fprintf('Done — %d daily maps saved to %s\n', dEnd-dStart+1, outDir);
