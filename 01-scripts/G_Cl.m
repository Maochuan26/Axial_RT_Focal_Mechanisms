%% G_Cl.m
% Hierarchical matching: new events → base catalog top-6 analogs
%
% Stage 1 (hard gate) : 3-D distance ≤ loc_thresh_km  (default 1 km)
% Stage 2 (rank 1)    : polarity agreement across 7 stations  (ascending mismatch)
% Stage 3 (rank 2)    : SP amplitude ratio similarity          (ascending misfit)
% Output              : top K=6 per query event → Po_Clu + Matches

clc; clear; close all;
addpath /Users/mczhang/Documents/GitHub/FM/01-scripts/subcode/

fields = {'AS1','AS2','CC1','EC1','EC2','EC3','ID1'};
K              = 6;      % top matches per new event
loc_thresh_km  = 1.0;    % stage-1 hard gate (km, 3-D)

%% ---- Load base catalog ----
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/A_All.mat')
Po = Felix; clear Felix;

% quality filter
Po = Po([Po.PoALL] > 5 & [Po.SP_All] > 5);
fprintf('Base catalog: %d events\n', numel(Po));

%% ---- Load new events (ML polarity output) ----
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/F_DLpol.mat');
Felixw = Felix; clear Felix;
fprintf('New events  : %d\n', numel(Felixw));

%% ---- Pre-compute base feature matrices ----

% Location in local km (lat/lon → x/y, depth already km)
base_latlon = [[Po.lat]', [Po.lon]'];
[base_xy(:,1), base_xy(:,2)] = latlon2xy(base_latlon(:,1), base_latlon(:,2));
base_depth = [Po.depth]';

% Polarity matrix  [Nbase x 7]  — stored as ±1 or 0 in base catalog Po_<STA>
base_po = zeros(numel(Po), numel(fields));
for k = 1:numel(fields)
    base_po(:,k) = [Po.(['Po_' fields{k}])]';
end

% SP ratio matrix  [Nbase x 7]  — stored directly as SP_<STA> in base catalog
base_spr = zeros(numel(Po), numel(fields));
for k = 1:numel(fields)
    base_spr(:,k) = [Po.(['SP_' fields{k}])]';
end

%% ---- Output containers ----
Matches = struct([]);

%% ---- Main loop: match each new event ----
for i = 1:numel(Felixw)

    q = Felixw(i);

    % --- query location ---
    [qx, qy] = latlon2xy(q.lat, q.lon);

    % --- STAGE 1: 3-D distance gate (km) ---
    dist3d = sqrt((base_xy(:,1)-qx).^2 + ...
                  (base_xy(:,2)-qy).^2 + ...
                  (base_depth - q.depth).^2);

    inGate = find(dist3d <= loc_thresh_km);

    if numel(inGate) < K
        % Not enough neighbors within 1 km — expand to nearest K
        [~, nearest] = mink(dist3d, K);
        inGate = nearest;
        fprintf('  Query %d (ID=%d): only %d within %.1f km, expanded to nearest %d\n', ...
            i, q.ID, sum(dist3d <= loc_thresh_km), loc_thresh_km, K);
    end

    % --- query polarity (1x7): take pred = Po_<STA>(1) ---
    q_po = zeros(1, numel(fields));
    for k = 1:numel(fields)
        v = q.(['Po_' fields{k}]);
        if ~isempty(v); q_po(k) = v(1); end
    end

    % --- query SP ratio (1x7): log(P_amp / noise_amp) from NSP_<STA> ---
    q_spr = zeros(1, numel(fields));
    for k = 1:numel(fields)
        v = q.(['NSP_' fields{k}]);
        if ~isempty(v) && numel(v) >= 3 && v(1) > 0 && mean(v) ~= 1
            q_spr(k) = log(v(3) / v(1));
        end
    end

    % --- STAGE 2: polarity mismatch (vectorized) ---
    sub_po  = base_po(inGate, :);          % [M x 7]
    both_nz = (q_po ~= 0) & (sub_po ~= 0);
    mismatch = (q_po ~= sub_po) & both_nz;
    n_pairs  = sum(both_nz, 2);
    dPo = sum(mismatch, 2) ./ max(n_pairs, 1);   % 0 = perfect, 1 = all wrong

    % --- STAGE 3: SP ratio misfit (vectorized) ---
    sub_spr  = base_spr(inGate, :);        % [M x 7]
    valid    = (q_spr ~= 0) & (sub_spr ~= 0);
    diff_sq  = (q_spr - sub_spr).^2 .* valid;
    n_valid  = max(sum(valid, 2), 1);
    dSpr = sqrt(sum(diff_sq, 2)) ./ n_valid;      % normalized Euclidean

    % --- Sort: primary dPo, secondary dSpr → top K ---
    [~, ord] = sortrows([dPo, dSpr], [1, 2]);
    topOrd   = ord(1:min(K, numel(ord)));
    I        = inGate(topOrd);

    % --- Store ---
    Matches(i).QueryID    = q.ID;
    Matches(i).QueryIndex = i;
    Matches(i).MatchIndex = I(:)';
    Matches(i).MatchID    = [Po(I).ID];
    Matches(i).Dist3D_km  = dist3d(I)';
    Matches(i).PoDist     = dPo(topOrd)';
    Matches(i).SprDist    = dSpr(topOrd)';

    fprintf('Query %d (ID=%d): top match IDs = %s  [%.2f km | dPo=%.2f | dSpr=%.2f]\n', ...
        i, q.ID, mat2str(Matches(i).MatchID), ...
        mean(Matches(i).Dist3D_km), mean(Matches(i).PoDist), mean(Matches(i).SprDist));

end

%% ---- Build Po_Clu: 1 query + top-K base events per cluster ----
ordered_fields = { ...
    'ID','on','lat','lon','depth', ...
    'DDt_AS1','DDSt_AS1','DDt_AS2','DDSt_AS2', ...
    'DDt_CC1','DDSt_CC1','DDt_EC1','DDSt_EC1', ...
    'DDt_EC2','DDSt_EC2','DDt_EC3','DDSt_EC3', ...
    'DDt_ID1','DDSt_ID1', ...
    'Pnum','Snum', ...
    'NSP_AS1','NSP_AS2','NSP_CC1','NSP_EC1','NSP_EC2','NSP_EC3','NSP_ID1', ...
    'Po_AS1','Po_AS2','Po_CC1','Po_EC1','Po_EC2','Po_EC3','Po_ID1', ...
    'PoALL', ...
    'SP_AS1','SP_AS2','SP_CC1','SP_EC1','SP_EC2','SP_EC3','SP_ID1', ...
    'SP_All','Cluster' ...
};

Po_Clu = struct([]);
row = 0;

for i = 1:numel(Matches)

    % --- query event row ---
    row = row + 1;
    for f = ordered_fields
        fn = f{1};
        if strcmp(fn, 'Cluster')
            Po_Clu(row).Cluster = i;
        elseif strncmp(fn, 'SP_', 3) && ~strcmp(fn, 'SP_All') && isfield(Felixw, ['NSP_' fn(4:end)])
            vspr = Felixw(i).(['NSP_' fn(4:end)]);
            if isnumeric(vspr) && numel(vspr) >= 3 && vspr(1) > 0 && ...
               mean(vspr) ~= 1 && all(isfinite(vspr))
                Po_Clu(row).(fn) = log(vspr(3) / vspr(1));
            else
                Po_Clu(row).(fn) = NaN;
            end
        elseif isfield(Felixw, fn)
            Po_Clu(row).(fn) = Felixw(i).(fn);
        else
            Po_Clu(row).(fn) = NaN;
        end
    end

    % --- matched base events ---
    for m = 1:numel(Matches(i).MatchIndex)
        row = row + 1;
        idx = Matches(i).MatchIndex(m);
        for f = ordered_fields
            fn = f{1};
            if strcmp(fn, 'Cluster')
                Po_Clu(row).Cluster = i;
            elseif isfield(Po, fn)
                Po_Clu(row).(fn) = Po(idx).(fn);
            else
                Po_Clu(row).(fn) = NaN;
            end
        end
    end

end

fprintf('\nPo_Clu: %d events in %d clusters (1 query + up to %d base each)\n', ...
    numel(Po_Clu), numel(Matches), K);

save('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/G_Cl.mat', 'Matches', 'Po_Clu', '-v7.3');
disp('Saved: G_Cl.mat');
