%% K_Plot_Histograms.m
% Six accumulated focal mechanism figures (one per region), 2015–2021.
%
% Replaces "Histograms of Recent Activity" on the FM website.
% Each figure shows accumulated counts of N / S / R focal mechanisms.
% Dashed/dotted vertical lines mark the 2015 eruption onset and end.
%
% Regions:
%   1. East Shallow      — lat [45.93,45.97], lon [-130.00,-129.975], depth [0,0.8]
%   2. West North        — lat [45.9443,45.95], lon [-130.029,-130.008]
%   3. West South        — lat [45.930,45.9443], lon [-130.029,-130.008]
%   4. East Deep North   — lat [45.950,45.97], lon [-130.0015,-129.992], depth [0.8,3]
%   5. East Deep South   — lat [45.940,45.97], lon [-129.992,-129.975], depth [0.8,3]
%   6. Inflated/Deflated — lat [45.921,45.929], lon [-130.004,-129.975]
%
% Requires: Event1D_3D_Final.mat in 02-data/.

clc; clear; close all;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);

%% ---- Eruption dates ----
date_eruption_on  = datenum(2015, 4, 24, 6, 0, 0);
date_eruption_off = datenum(2015, 5, 19);

%% ---- Output directories ----
graphicsDir = cfg.graphicsDir;
htdocs      = cfg.htdocs;
if ~exist(graphicsDir, 'dir'); mkdir(graphicsDir); end

%% ---- Load FM catalog ----
load(fullfile(cfg.dataDir, 'Event1D_3D_Final.mat'));   % event3D, Po_Clu

% Quality filter (A/B only)
if isfield(event3D, 'mechqual')
    event3D([event3D.mechqual] == 'C') = [];
    event3D([event3D.mechqual] == 'D') = [];
end

% Remove unclassified
event3D(strcmp({event3D.faultType}, 'U')) = [];

fprintf('After A/B filter, removing U: %d events\n', numel(event3D));

% Build time lookup from Po_Clu
clust_vec = [Po_Clu.Cluster];
on_vec    = [Po_Clu.on];

% Resolve time and collect spatial fields
nEv      = numel(event3D);
ev_on    = nan(1, nEv);
ev_lat   = nan(1, nEv);
ev_lon   = nan(1, nEv);
ev_depth = nan(1, nEv);
ev_type  = {event3D.faultType};

for i = 1:nEv
    idx = find(clust_vec == event3D(i).id, 1, 'first');
    if ~isempty(idx)
        ev_on(i) = on_vec(idx);
    end
    ev_lat(i)   = event3D(i).lat;
    ev_lon(i)   = event3D(i).lon;
    ev_depth(i) = event3D(i).depth;
end

% Remove unresolved times
valid    = ~isnan(ev_on);
ev_on    = ev_on(valid);
ev_lat   = ev_lat(valid);
ev_lon   = ev_lon(valid);
ev_depth = ev_depth(valid);
ev_type  = ev_type(valid);
fprintf('Time-resolved: %d events\n', numel(ev_on));

%% ---- Define 6 regions ----
% { label, latLim, lonLim, depthLim }
regionDefs = { ...
    'East Shallow',        [45.930, 45.97 ],  [-130.00,   -129.975], [0,    0.8  ]; ...
    'West North',          [45.9443, 45.95],  [-130.029,  -130.008], [-Inf, Inf  ]; ...
    'West South',          [45.930, 45.9443], [-130.029,  -130.008], [-Inf, Inf  ]; ...
    'East Deep North',     [45.950, 45.97 ],  [-130.0015, -129.992], [0.8,  3    ]; ...
    'East Deep South',     [45.940, 45.97 ],  [-129.992,  -129.975], [0.8,  3    ]; ...
    'Inflated/Deflated',   [45.921, 45.929],  [-130.004,  -129.975], [-Inf, Inf  ]; ...
};

outNames = { ...
    'regionFM_EastShallow', 'regionFM_WestNorth', 'regionFM_WestSouth', ...
    'regionFM_EastDeepNorth', 'regionFM_EastDeepSouth', 'regionFM_ID' };

updStr  = datestr(datetime('now','TimeZone','UTC'), 'dd-mmm-yyyy HH:MM');
figSz   = [100 100 700 420];
paperSz = [7 4.2];

%% ---- One figure per region ----
for kr = 1:size(regionDefs, 1)

    label    = regionDefs{kr, 1};
    latBnd   = regionDefs{kr, 2};
    lonBnd   = regionDefs{kr, 3};
    depBnd   = regionDefs{kr, 4};

    % Filter events to this region
    inReg = ev_lat   >= latBnd(1) & ev_lat   <= latBnd(2) & ...
            ev_lon   >= lonBnd(1) & ev_lon   <= lonBnd(2) & ...
            ev_depth >= depBnd(1) & ev_depth <= depBnd(2);

    reg_on   = ev_on(inReg);
    reg_type = ev_type(inReg);

    [reg_on, si] = sort(reg_on);
    reg_type = reg_type(si);

    isN = strcmp(reg_type, 'N');
    isS = strcmp(reg_type, 'S');
    isR = strcmp(reg_type, 'R');

    t_unique = unique(reg_on);

    if ~isempty(t_unique)
        cumN = arrayfun(@(t) sum(reg_on(isN) <= t), t_unique);
        cumS = arrayfun(@(t) sum(reg_on(isS) <= t), t_unique);
        cumR = arrayfun(@(t) sum(reg_on(isR) <= t), t_unique);
    else
        cumN = []; cumS = []; cumR = [];
    end

    fprintf('Region %-22s: %d events (N=%d, S=%d, R=%d)\n', ...
        label, numel(reg_on), sum(isN), sum(isS), sum(isR));

    %% ---- Figure ----
    fig = figure('Color','white', 'Position',figSz, 'InvertHardcopy','off');
    set(fig,'PaperUnits','inches','PaperSize',paperSz,'PaperPosition',[0 0 paperSz]);
    ax = axes('Parent', fig);
    hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');

    if ~isempty(t_unique)
        hN = plot(ax, t_unique, cumN, '-b', 'LineWidth', 2);
        hS = plot(ax, t_unique, cumS, '-g', 'LineWidth', 2);
        hR = plot(ax, t_unique, cumR, '-r', 'LineWidth', 2);
    else
        hN = plot(ax, NaN, NaN, '-b', 'LineWidth', 2);
        hS = plot(ax, NaN, NaN, '-g', 'LineWidth', 2);
        hR = plot(ax, NaN, NaN, '-r', 'LineWidth', 2);
    end

    % Eruption onset/end vertical lines
    ymax_val = max([cumN, cumS, cumR, 1]);
    plot(ax, [date_eruption_on  date_eruption_on ], [0, ymax_val*1.15], ...
        'k--', 'LineWidth', 1.5, 'HandleVisibility','off');
    plot(ax, [date_eruption_off date_eruption_off], [0, ymax_val*1.15], ...
        'k:',  'LineWidth', 1.5, 'HandleVisibility','off');

    legend(ax, [hN, hS, hR], {'Normal','Strike-slip','Reverse'}, ...
        'Location','northwest', 'FontSize', 12);

    ylabel(ax, 'Accumulated Count', 'FontSize', 14);
    xlabel(ax, 'Time', 'FontSize', 14);
    xlim(ax, [datenum(2015,1,1), datenum(2022,1,1)]);
    datetick(ax, 'x', 'yyyy', 'keeplimits');
    set(ax, 'FontSize', 12, 'GridLineStyle', '-');

    title(ax, sprintf('%s — Accumulated FMs 2015–2021\nUpdated %s UTC', label, updStr), ...
        'FontSize', 14);

    %% ---- Save ----
    fname = fullfile(graphicsDir, [outNames{kr} '.jpg']);
    exportgraphics(fig, fname, 'Resolution', 150, 'BackgroundColor', 'white');
    copyfile(fname, fullfile(htdocs, [outNames{kr} '.jpg']));
    close(fig);
    fprintf('Saved: %s.jpg\n', outNames{kr});

end

fprintf('Done — 6 region FM figures saved.\n');

%% ---- Regenerate website HTML ----
% Website update handled by I_UpdateFMWebsite.m (final pipeline stage)
