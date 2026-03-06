function [h, hStation] = basemap_2015v2(lonLim, latLim, scale, LLCorner, alpha, doColor, hAx)
% BASMAP_2015 Creates a basemap for plotting earthquakes
%
% Usage:
%   [h, hStation] = basemap_2015(lonLim, latLim, scale, LLCorner, alpha, doColor)
%
%   [h, hStation] = basemap_2015(..., hAx)
%      If hAx is provided, the plotting is done on the axes hAx.
%
% Inputs
%   lonLim   - Two-element vector for longitude limits.
%   latLim   - Two-element vector for latitude limits.
%   scale    - Scale in inches per degree.
%   LLCorner - Lower left corner [x y] for axes (only used if hAx not provided).
%   alpha    - Transparency for lava flows.
%   doColor  - Logical flag; true for color lava flows.
%   hAx      - (Optional) Handle to an axes object.
%
% Outputs
%   h        - Handle to the axes used.
%   hStation - Handle to the plotted station markers.
%
% Lava is 2015 eruption

% Set default values if needed
if nargin < 1 || isempty(lonLim)
    lonLim = [-130.05 -129.95];
end
if nargin < 2 || isempty(latLim)
    latLim = [45.90 46.00];
end
if nargin < 3 || isempty(scale)
    scale = 100;
end
if nargin < 4 || isempty(LLCorner)
    LLCorner = [1 1];
end
if nargin < 5 || isempty(alpha)
    alpha = 1;
end
if nargin < 6 || isempty(doColor)
    doColor = false;
end

% Use the provided axes handle if available; otherwise, create new axes.
if nargin < 7 || isempty(hAx) || ~ishandle(hAx)
    h = axes('units','inches', ...
        'position',[LLCorner diff(lonLim)*scale*cosd(mean(latLim)) diff(latLim)*scale], ...
        'xlim',lonLim,'ylim',latLim,'box','on');
else
    h = hAx;
    set(h, 'xlim', lonLim, 'ylim', latLim, 'box', 'on');
end
hold(h, 'on');

% --- Plot 2011 lava flows (if alpha>=0) ---
if alpha >= 0
    axial_lava2011;
    for i = 1:length(lava)
        if doColor
            fill(h, lava(i).xy(:,1), lava(i).xy(:,2), [.6 .9 .9], 'edgecolor', 'none', 'facealpha', alpha);
        else
            fill(h, lava(i).xy(:,1), lava(i).xy(:,2), [.95 .95 .95], 'edgecolor', 'none', 'facealpha', alpha);
        end
    end
    for i = 1:length(hole)
        fill(h, hole(i).xy(:,1), hole(i).xy(:,2), [1 1 1], 'edgecolor', 'none', 'facealpha', alpha);
    end
end

% --- Plot 2015 lava flows ---
axial_lava2015;
for i = 1:length(flow2015)
    if doColor
        fill(h, flow2015(i).lon, flow2015(i).lat, [.9 .6 .9], 'edgecolor', 'none', 'facealpha', abs(alpha));
    else
        fill(h, flow2015(i).lon, flow2015(i).lat, [.8 .8 .8], 'edgecolor', 'none', 'facealpha', abs(alpha));
    end
end

% --- Plot caldera rim ---
axial_calderaRim;
plot(h, calderaRim(:,1), calderaRim(:,2), '-k', 'linewidth', 3);

% --- Plot sills ---
axial_sills;
% (Optional plotting of sills if needed)

% --- Plot stations ---
station = axial_stationsNewOrder;
hStation = plot(h, [station.lon], [station.lat], 'sk', ...
    'markerfacecolor', 'k', 'markersize', max(6, min(14, 6*scale/40)));

%xlabel(h, 'Longitude, \circ','FontSize',20);
%ylabel(h, 'Latitude, \circ','FontSize',20);
xlabel(h,'Longitude (°)','FontSize',20);
ylabel(h,'Latitude (°)','FontSize',20);

% Optionally adjust xticks if there are many
a = get(h, 'xtick');
if length(a) > 4
    set(h, 'xtick', a(1:2:end));
end

hold on;

hold on;
fiss=importdata('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/data/Axial-2015-fissures-points-geo-v2.txt');
fiss=[fiss.data];
ind=unique(fiss(:,1));
for i=1:length(ind)
    ind_p=find(fiss(:,1)==ind(i));
    fiss_p=fiss(ind_p,:);
    plot(fiss_p(:,2),fiss_p(:,3),'k-',LineWidth=1);
    hold on;
end
hold on;
% lava=importdata(['/Users/mczhang/Documents/GitHub/FM/02-data/Alldata/' ...
%     'Fissures2015/JdF:Axial_Clague/Axial-2015-lava-points-geo-v2.txt']);
% hold on;
% lava=[lava.data];
% ind=unique(lava(:,2));
% for i=1:length(ind)
%     ind_p=find(lava(:,2)==ind(i));
%     lava_p=lava(ind_p,:);
%     plot(lava_p(:,3),lava_p(:,4),'g',LineWidth=2);
%     hold on;
% end

fiss=importdata('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/data/Axial-2011-fissures-points-geo-v2.txt');
fiss=[fiss.data];
ind=unique(fiss(:,1));
for i=1:length(ind)
    ind_p=find(fiss(:,1)==ind(i));
    fiss_p=fiss(ind_p,:);
    plot(fiss_p(:,2),fiss_p(:,3),'k-',LineWidth=1);
    hold on;
end
hold on;
%clear;

fiss=load('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/data/Axial-1998-Fissures.txt');
ind=unique(fiss(:,1));
for i=1:length(ind)
    ind_p=find(fiss(:,1)==ind(i));
    fiss_p=fiss(ind_p,:);
    plot(fiss_p(:,2),fiss_p(:,3),'k-',LineWidth=1);
    hold on;
end
hold on;
end
