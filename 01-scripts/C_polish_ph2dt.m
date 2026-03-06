clc;clear;
addpath('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/');
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/B_ph2dt_past30days_combined_until_20260225.mat')
% Station name to field name mapping
staMap = { ...
    'AXAS1', 'AS1'; ...
    'AXAS2', 'AS2'; ...
    'AXCC1', 'CC1'; ...
    'AXEC1', 'EC1'; ...
    'AXEC2', 'EC2'; ...
    'AXEC3', 'EC3'; ...
    'AXID1', 'ID1'  ...
};

nEv = length(ph2dt);
Felix = struct([]);

for i = 1:nEv

    Felix(i).ID    = ph2dt(i).ID;
    Felix(i).on    = ph2dt(i).datenum;
    Felix(i).lat   = ph2dt(i).lat;
    Felix(i).lon   = ph2dt(i).lon;
    Felix(i).depth = ph2dt(i).depth;
    Felix(i).mag = ph2dt(i).mag;

    % Initialize all station fields as NaN
    for k = 1:size(staMap,1)
        tag = staMap{k,2};
        Felix(i).(['DDt_'  tag]) = NaN;
        Felix(i).(['DDSt_' tag]) = NaN;
    end

    % Fill travel times by station and phase
    for j = 1:length(ph2dt(i).obs.tt)
        sta   = ph2dt(i).obs.sta{j};
        phase = ph2dt(i).obs.phase{j};
        tt    = ph2dt(i).obs.tt(j);

        row = find(strcmp(staMap(:,1), sta), 1);
        if isempty(row); continue; end

        tag = staMap{row, 2};
        if strcmp(phase, 'P')
            Felix(i).(['DDt_'  tag]) = tt;
        elseif strcmp(phase, 'S')
            Felix(i).(['DDSt_' tag]) = tt;
        end
    end

    % Count stations with both P and S picks
    PSpair = 0;
    for k = 1:size(staMap,1)
        tag = staMap{k,2};
        if ~isnan(Felix(i).(['DDt_'  tag])) && ...
           ~isnan(Felix(i).(['DDSt_' tag]))
            PSpair = PSpair + 1;
        end
    end
    Felix(i).PSpair = PSpair;

    %Felix(i).Pnum = ph2dt(i).Psum;
    %Felix(i).Snum = ph2dt(i).Ssum;

end
save('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/C_ph2dt.mat', 'Felix');