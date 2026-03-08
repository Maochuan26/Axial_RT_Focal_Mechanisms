%% J_Plot_Eruption2015.m
% Plot focal mechanisms Before / During / After the 2015 Axial eruption.
% Produces 3 separate figures with the same font conventions as H_Plot_FM.m.
% Requires Event1D_3D.mat copied into 02-data/.  Run before I_UpdateFMWebsite.m.

clc; clear; close all;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);

%% ---- Eruption cutoff dates ----
date_BF = datenum(2015, 4, 24, 8, 0, 0);   % eruption onset
date_DR = datenum(2015, 5, 19);             % end of co-eruptive period

%% ---- Map limits ----
lonLim = [-130.031 -129.97];
latLim = [45.92    45.970];

%% ---- Period definitions ----
projects  = {'Before', 'During', 'After'};
winLabels = {'Before Eruption (pre Apr 24, 2015)', ...
             'During Eruption (Apr 24 – May 19, 2015)', ...
             'After Eruption (post May 19, 2015)'};
labels    = {'(a)', '(b)', '(c)'};

%% ---- Visual parameters (same as H_Plot_FM.m) ----
radius      = 0.0005;
scale_event = 1.3;
faultTypes  = {'N','R','S','U'};
faultLabels = {'N - Normal', 'R - Reverse', 'S - Strike-slip', 'U - Undefined'};
defaultC    = struct('N',[0,0,1],'R',[1,0,0],'S',[0,1,0],'U',[0,0,0]);

%% ---- Region outlines ----
regions = struct( ...
    'West', struct('Lat', [45.930, 45.950], 'Lon', [-130.029, -130.008]), ...
    'East', struct('Lat', [45.970, 45.930], 'Lon', [-130.0015, -129.975]), ...
    'ID',   struct('Lat', [45.921, 45.929], 'Lon', [-130.004, -129.975]));

%% ---- Output directories ----
graphicsDir    = cfg.graphicsDir;
graphicsErupDir = fullfile(graphicsDir, 'eruption2015daily');
htdocs         = cfg.htdocs;
htdocsErupDir  = fullfile(htdocs, 'eruption2015daily');
if ~exist(graphicsDir,      'dir'); mkdir(graphicsDir);      end
if ~exist(graphicsErupDir,  'dir'); mkdir(graphicsErupDir);  end
if ~exist(htdocsErupDir,    'dir'); mkdir(htdocsErupDir);    end
dateStr = datestr(now, 'yyyymmdd');

%% ---- Load & prepare data ----
load(fullfile(cfg.dataDir, 'Event1D_3D.mat'));   % → event1D, event3D

% Quality and location filters on event1D (used to compute color3)
event1D([event1D.lat]  > 45.969) = [];
event1D([event1D.lon]  < -130.03) = [];
event1D([event1D.mechqual] == 'C') = [];
event1D([event1D.mechqual] == 'D') = [];

for i = 1:length(event1D)
    if event1D(i).mechqual == 'A' || event1D(i).mechqual == 'B'
        event1D(i).color3 = event1D(i).color2;
    else
        event1D(i).color3 = event1D(i).color2 + 0.5*(1 - event1D(i).color2);
    end
end

for i = 1:length(event3D)
    if event3D(i).mechqual == 'A' || event3D(i).mechqual == 'B'
        event3D(i).color3 = event3D(i).color2;
    else
        event3D(i).color3 = event3D(i).color2 + 0.5*(1 - event3D(i).color2);
    end
end

event1D = event3D;   % use 3-D relocated catalog for plotting

%% ---- One figure per period ----
for kp = 1:3

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

    %% ---- Filter events for this period ----
    if kp == 1
        indEv = find([event1D.time] < date_BF);
    elseif kp == 2
        indEv = find([event1D.time] >= date_BF & [event1D.time] < date_DR);
    else
        indEv = find([event1D.time] >= date_DR);
    end
    eventsPeriod = event1D(indEv);
    eventsPeriod([eventsPeriod.lat] > 45.97)  = [];
    eventsPeriod([eventsPeriod.lon] < -130.03) = [];
    nmec = length(eventsPeriod);

    %% ---- Plot beach balls ----
    for i = 1:nmec
        if ~isempty(eventsPeriod(i).avfnorm)
            plot_balloon(eventsPeriod(i).avfnorm, eventsPeriod(i).avslip, ...
                eventsPeriod(i).lon, eventsPeriod(i).lat, ...
                radius, scale_event, eventsPeriod(i).color3);
            hold(ax, 'on');
        end
    end

    %% ---- Region outlines ----
    regionNames = fieldnames(regions);
    for i = 1:length(regionNames)
        r = regions.(regionNames{i});
        lats = [r.Lat(1), r.Lat(1), r.Lat(2), r.Lat(2), r.Lat(1)];
        lons = [r.Lon(1), r.Lon(2), r.Lon(2), r.Lon(1), r.Lon(1)];
        plot(ax, lons, lats, 'k--', 'LineWidth', 1.5);
    end

    %% ---- Labels ----
    title(ax, sprintf('%d FMs  —  %s\nUpdated %s UTC', ...
        nmec, winLabels{kp}, datestr(now, 'yyyy-mm-dd HH:MM')), 'FontSize', 42);
    xlabel(ax, 'Longitude (°)', 'FontSize', 36);
    ylabel(ax, 'Latitude (°)',  'FontSize', 36);
    text(lonLim(1)+0.001, latLim(2)-0.001, labels{kp}, ...
        'FontSize', 32, 'FontWeight', 'bold', 'Parent', ax);
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
    tag           = projects{kp};
    fname_current = fullfile(graphicsDir,     sprintf('EruptionFM_%s.jpg', tag));
    fname_archive = fullfile(graphicsErupDir, sprintf('EruptionFM_%s_%s.jpg', tag, dateStr));
    exportgraphics(fig, fname_current, 'Resolution', 150, 'BackgroundColor', 'white');
    copyfile(fname_current, fname_archive);
    copyfile(fname_current, fullfile(htdocs,        sprintf('EruptionFM_%s.jpg', tag)));
    copyfile(fname_archive, fullfile(htdocsErupDir, sprintf('EruptionFM_%s_%s.jpg', tag, dateStr)));
    close(fig);
    fprintf('Saved: EruptionFM_%s.jpg\n', tag);

end

fprintf('Done — 3 eruption FM figures saved and copied to htdocs.\n');

%% ---- Regenerate website HTML ----
% Website update handled by I_UpdateFMWebsite.m (final pipeline stage)
