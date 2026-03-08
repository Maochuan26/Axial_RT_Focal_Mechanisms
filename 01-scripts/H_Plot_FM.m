%% H_Plot_FM.m
% Plot focal mechanisms from G_FM.mat for past 24 h, 7 days, and 30 days.
% Run after the full A→G pipeline.
clc; clear; close all;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);

%% ---- Load data ----
load(fullfile(cfg.dataDir, 'G_FM.mat'));   % event1, event2, event3
load(fullfile(cfg.dataDir, 'F_Cl.mat'));   % Po_Clu

%% ---- Add time field to event1 from Po_Clu query events ----
% event1(i).id = cluster index + 99  (see G_FM.m line 29)
for i = 1:length(event1)
    clust = event1(i).id - 99;
    qidx  = find([Po_Clu.Cluster] == clust, 1, 'first');
    if ~isempty(qidx)
        event1(i).time = Po_Clu(qidx).on;   % MATLAB datenum of query event
    else
        event1(i).time = NaN;
    end
end

%% ---- color3: full color for A/B quality, lightened for others ----
for i = 1:length(event1)
    if isfield(event1,'mechqual') && ...
            (event1(i).mechqual == 'A' || event1(i).mechqual == 'B')
        event1(i).color3 = event1(i).color2;
    else
        event1(i).color3 = event1(i).color2 + 0.5 * (1 - event1(i).color2);
    end
end

% Remove events with no valid time or location
event1(isnan([event1.time]))  = [];
event1([event1.lat] > 45.970) = [];
event1([event1.lon] < -130.031) = [];

%% ---- Time windows ----
tNow     = now;
windows  = [1, 7, 30];                      % days back
labels   = {'(a)', '(b)', '(c)'};
winLabels = {'Past 24 h', 'Past 7 days', 'Past 30 days'};

%% ---- Map limits (Axial Seamount) ----
lonLim = [-130.031 -129.97];
latLim = [45.92    45.970 ];

%% ---- Output paths ----
graphicsDir   = cfg.graphicsDir;
graphicsFmDir = fullfile(graphicsDir, 'focalmechanismsdaily');
htdocs        = cfg.htdocs;
htdocsFmDir   = fullfile(htdocs, 'focalmechanismsdaily');
if ~exist(graphicsDir,   'dir'); mkdir(graphicsDir);   end
if ~exist(graphicsFmDir, 'dir'); mkdir(graphicsFmDir); end
if ~exist(htdocsFmDir,   'dir'); mkdir(htdocsFmDir);   end
dateStr = datestr(tNow, 'yyyymmdd');

radius      = 0.0005;
scale_event = 1.3;

faultTypes  = {'N','R','S','U'};
faultLabels = {'N - Normal', 'R - Reverse', 'S - Strike-slip', 'U - Unclassified'};
defaultC    = struct('N',[0,0,1],'R',[1,0,0],'S',[0,1,0],'U',[0,0,0]);

%%
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

    %% ---- Filter events for this time window ----
    tCut = tNow - windows(kp);
    indEv = find([event1.time] >= tCut & [event1.time] <= tNow);
    eventsPeriod = event1(indEv);
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

    %% ---- Shallow East region outline ----
    seLatLim = [45.93 45.96];
    seLonLim = [-130.00 -129.975];
    axes(ax);
    plot(seLonLim([1 2 2 1 1]), seLatLim([1 1 2 2 1]), 'r--', 'LineWidth', 3);

    %% ---- Labels ----
    title(ax, sprintf('%d FMs  —  %s\nUpdated %s UTC', ...
        nmec, winLabels{kp}, datestr(tNow, 'yyyy-mm-dd HH:MM')), 'FontSize', 42);
    xlabel(ax, 'Longitude (°)', 'FontSize', 36);
    ylabel(ax, 'Latitude (°)', 'FontSize', 36);
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
            plot(legendX, legendYs(k), 'o', 'MarkerFaceColor', defaultC.(faultTypes{k}), ...
                'MarkerEdgeColor','k', 'MarkerSize', 8);
        end
        text(legendX + 0.003, legendYs(k), faultLabels{k}, ...
            'HorizontalAlignment','left', 'FontSize', 30);
    end

    % Legend box
    legendLeft   = legendX - 0.002;
    legendRight  = legendX + 0.020;
    legendBottom = min(legendYs) - 0.002;
    legendTop    = max(legendYs) + 0.001;
    rectangle(ax, 'Position', [legendLeft, legendBottom, ...
        legendRight-legendLeft, legendTop-legendBottom], ...
        'EdgeColor','k', 'LineWidth', 0.5);

    %% ---- Save ----
    tag           = sprintf('%dday', windows(kp));
    fname_current = fullfile(graphicsDir,   sprintf('FocalMechanism%s.jpg', tag));
    fname_archive = fullfile(graphicsFmDir, sprintf('FM%s_%s.jpg', tag, dateStr));
    exportgraphics(fig, fname_current, 'Resolution', 150, 'BackgroundColor', 'white');
    copyfile(fname_current, fname_archive);
    copyfile(fname_current, fullfile(htdocs,      sprintf('FocalMechanism%s.jpg', tag)));
    copyfile(fname_archive,  fullfile(htdocsFmDir, sprintf('FM%s_%s.jpg', tag, dateStr)));
    close(fig);

end

%% ---- Accumulated FM plots for Shallow East ----
latLimE = [45.93 45.97];
lonLimE = [-130.00 -129.975];
depLimE = 0.8;

accumWindows   = [7,       30,         365];
accumWinLabels = {'Past 7 Days', 'Past 30 Days', 'Past 1 Year'};
accumTags      = {'7day',  '30day',    '1year'};
dateFmt        = {'mmm dd','mmm dd',   'mmm yy'};

for kp = 1:3
    tCut = tNow - accumWindows(kp);

    ind = find([event1.time] >= tCut & [event1.time] <= tNow & ...
               [event1.lat]  >= latLimE(1) & [event1.lat]  <= latLimE(2) & ...
               [event1.lon]  >= lonLimE(1) & [event1.lon]  <= lonLimE(2) & ...
               [event1.depth] <= depLimE);
    ev = event1(ind);
    ev(strcmp({ev.faultType}, 'U')) = [];
    if isfield(ev, 'mechqual') && ~isempty(ev)
        ev(ismember([ev.mechqual], 'CD')) = [];
    end

    fig = figure('Color','w','Position',[100 100 950 900], 'InvertHardcopy','off');
    set(fig, 'PaperUnits','inches','PaperSize',[9.5 9.0],'PaperPosition',[0 0 9.5 9.0]);
    ax2 = axes('Parent', fig, 'Position', [0.13 0.18 0.76 0.65]);
    hold(ax2, 'on'); box(ax2, 'on'); grid(ax2, 'on');

    if ~isempty(ev)
        [~, sidx] = sort([ev.time]);
        ev = ev(sidx);

        isN = strcmp({ev.faultType}, 'N');
        isS = strcmp({ev.faultType}, 'S');
        isR = strcmp({ev.faultType}, 'R');
        timeN = [ev(isN).time];
        timeS = [ev(isS).time];
        timeR = [ev(isR).time];
        t_unique = unique([ev.time]);

        legHandles = gobjects(0);
        legLabels  = {};
        if ~isempty(timeN)
            h = plot(ax2, t_unique, arrayfun(@(t) sum(timeN<=t), t_unique), '-b', 'LineWidth', 3);
            legHandles(end+1) = h; legLabels{end+1} = 'Normal';
        end
        if ~isempty(timeS)
            h = plot(ax2, t_unique, arrayfun(@(t) sum(timeS<=t), t_unique), '-g', 'LineWidth', 3);
            legHandles(end+1) = h; legLabels{end+1} = 'Strike-slip';
        end
        if ~isempty(timeR)
            h = plot(ax2, t_unique, arrayfun(@(t) sum(timeR<=t), t_unique), '-r', 'LineWidth', 3);
            legHandles(end+1) = h; legLabels{end+1} = 'Reverse';
        end
        if ~isempty(legHandles)
            legend(ax2, legHandles, legLabels, 'Location', 'northwest', 'FontSize', 38);
        end
        datetick(ax2, 'x', dateFmt{kp}, 'keepticks');
    else
        text(0.5, 0.5, 'No events in this period', ...
            'HorizontalAlignment','center','Units','normalized','FontSize',42,'Parent',ax2);
    end

    ylabel(ax2, 'Accumulated Number', 'FontSize', 44);
    xlabel(ax2, accumWinLabels{kp}, 'FontSize', 44);
    title(ax2, sprintf('Accumulated FM — Shallow East  (%s)', accumWinLabels{kp}), 'FontSize', 50);
    set(ax2, 'FontSize', 40);

    tag           = accumTags{kp};
    fname_current = fullfile(graphicsDir,   sprintf('accumFM%s.jpg', tag));
    fname_archive = fullfile(graphicsFmDir, sprintf('accumFM%s_%s.jpg', tag, dateStr));
    exportgraphics(fig, fname_current, 'Resolution', 150, 'BackgroundColor', 'white');
    copyfile(fname_current, fname_archive);
    copyfile(fname_current, fullfile(htdocs, sprintf('accumFM%s.jpg', tag)));
    close(fig);
end

% Website update is handled separately by I_UpdateFMWebsite.m (final pipeline stage)
