%% Match new Felixw events to base catalog Po by similarity, pick top K
clc; clear; close all;

addpath /Users/mczhang/Documents/GitHub/FM/01-scripts/subcode/

fields = {'AS1','AS2','CC1','EC1','EC2','EC3','ID1'};
K = 6;                          % top K similar base events per new event

% weights (tune these)
wLoc = 3;
wSpr = 7;
wPo  = 100;

% thresholds (optional; set [] to disable)
maxPoMismatch = 0;              % fraction of polarity mismatches (0 = perfect match). set [] to disable
maxSprMisfit  = 0.2;            % normalized SP Euclidean misfit. set [] to disable
maxLocMisfit  = 0.2;            % IQR-normalized loc misfit. set [] to disable

%% ---- Load base catalog (big) ----
% Example: base is "Po" from your old files (after quality filters)
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/A_All.mat')  % <-- change to your base catalog file
Po = Felix; clear Felix;

% quality filter (keep your rules)
min_Po_num = 5;
min_SP_num = 5;
Po = Po([Po.PoALL] > min_Po_num & [Po.SP_All] > min_SP_num);

fprintf('Base catalog size: %d\n', numel(Po));

%% ---- Load new catalog (28) with ML results ----
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/F_DLpol.mat'); % <-- change
Felixw = Felix; clear Felix;
fprintf('New catalog size: %d\n', numel(Felixw));

%% ---- Precompute base feature matrices ----
% location (convert lat/lon to local xy)
base_loc = [[Po.lat]', [Po.lon]', [Po.depth]'];
[base_loc(:,1), base_loc(:,2)] = latlon2xy(base_loc(:,1), base_loc(:,2));

% polarities & SP ratios for base (Nbase x 7)
base_po  = zeros(numel(Po), numel(fields));
base_spr = zeros(numel(Po), numel(fields));

for k = 1:numel(fields)
    fk = fields{k};
    % polarity fields assumed Po_<STA> in base
    base_po(:,k)  = [Po.(['Po_' fk])]';
    % S/P fields assumed SP_<STA> in base
    base_spr(:,k) = [Po.(['SP_' fk])]';
end

% normalize location scale (so loc distance ~ 0-1)
% use robust ranges (avoid outliers)
loc_scale = iqr(base_loc,1);
loc_scale(loc_scale==0) = 1;
base_locN = base_loc ./ loc_scale;

%% ---- Output containers ----
Matches = struct([]);

%% ---- Loop new events: find top K similar base events ----
for i = 1:numel(Felixw)

    q = Felixw(i);

    % query location
    q_loc = [q.lat, q.lon, q.depth];
    [q_loc(1), q_loc(2)] = latlon2xy(q_loc(1), q_loc(2));
    q_locN = q_loc ./ loc_scale;

    % query polarity & SP (1x7)
    q_po  = zeros(1,numel(fields));
    q_spr = zeros(1,numel(fields));

    for k = 1:numel(fields)
        fk = fields{k};

        % Your new file sometimes stores Po_<STA> as scalar or [pred conf ent]
        % Handle both:
        vpo = q.(['Po_' fk]);
        if isempty(vpo)
            q_po(k) = 0;
        elseif numel(vpo) >= 1
            q_po(k) = vpo(1);   % take pred
        else
            q_po(k) = 0;
        end

        vspr = q.(['NSP_' fk]);
        if isempty(vspr) || mean(vspr)==1, q_spr(k) = 0; 
        
        else
            q_spr(k) = log(vspr(3)/vspr(1));
        end
        
        
    end

    % ----- compute distance to every base event -----
    % 1) loc distance (IQR-normalized Euclidean, then scaled 0..1)
    dLoc = sqrt(sum((base_locN - q_locN).^2, 2));
    dLoc = dLoc ./ max(dLoc + eps);  % 0..1

    % 2) polarity misfit: fraction of mismatches among non-zero pairs [0..1]
    dPo = custom_distance_Po(q_po, base_po);

    % 3) SP ratio misfit: normalized Euclidean on non-zero pairs [0..1]
    dSpr = custom_distance_SPr(q_spr, base_spr);

    % total distance
    D = wLoc*dLoc + wSpr*dSpr + wPo*dPo;

    % apply optional hard filters (recommended)
    keep = true(size(D));

    if ~isempty(maxPoMismatch)
        keep = keep & (dPo <= maxPoMismatch);
    end
    if ~isempty(maxSprMisfit)
        keep = keep & (dSpr <= maxSprMisfit);
    end
    if ~isempty(maxLocMisfit)
        keep = keep & (sqrt(sum((base_locN - q_locN).^2, 2)) <= maxLocMisfit);
    end

    idxKeep = find(keep);
    if isempty(idxKeep)
        % fallback: no one passed filters -> just take top K by D
        [~, I] = mink(D, K);
    else
        [~, ord] = sort(D(idxKeep), 'ascend');
        I = idxKeep(ord(1:min(K, numel(ord))));
    end

    % store matches
    Matches(i).QueryID     = q.ID;
    Matches(i).QueryIndex  = i;
    Matches(i).MatchIndex  = I(:)';
    Matches(i).MatchID     = [Po(I).ID];
    Matches(i).Distance    = D(I)';
    Matches(i).LocDist     = dLoc(I)';
    Matches(i).PoDist      = dPo(I)';
    Matches(i).SprDist     = dSpr(I)';

    fprintf('Query %d (ID=%d): top match IDs = %s\n', ...
        i, q.ID, mat2str(Matches(i).MatchID));

end

%% ---- Build Po_Clu: 1 new event + top-K base events per cluster ----
% Each cluster i = [Felixw(i), Po(top-K matches)] with Cluster = i
% Field order matches F_Cl_All_ML_polish.mat; missing fields filled with NaN

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

    % ---- first entry: new query event ----
    row = row + 1;
    for f = ordered_fields
        fn = f{1};
        nsp_fn = ['NSP_' fn(4:end)];
        if strcmp(fn, 'Cluster')
            Po_Clu(row).Cluster = i;
        elseif strncmp(fn, 'SP_', 3) && ~strcmp(fn, 'SP_All') && isfield(Felixw, nsp_fn)
            vspr = Felixw(i).(nsp_fn);
            if isnumeric(vspr); vspr = double(vspr(:)); else; vspr = []; end
            if isempty(vspr) || numel(vspr) < 3 || mean(vspr) == 1 || vspr(1) == 0 || ~all(isfinite(vspr))
                Po_Clu(row).(fn) = NaN;
            else
                Po_Clu(row).(fn) = log(vspr(3) / vspr(1));
            end
        elseif isfield(Felixw, fn)
            Po_Clu(row).(fn) = Felixw(i).(fn);
        else
            Po_Clu(row).(fn) = NaN;
        end
    end

    % ---- next entries: matched base catalog events ----
    idx = Matches(i).MatchIndex;
    for m = 1:numel(idx)
        row = row + 1;
        for f = ordered_fields
            fn = f{1};
            if strcmp(fn, 'Cluster')
                Po_Clu(row).Cluster = i;
            elseif isfield(Po, fn)
                Po_Clu(row).(fn) = Po(idx(m)).(fn);
            else
                Po_Clu(row).(fn) = NaN;
            end
        end
    end

end

fprintf('Po_Clu: %d events in %d clusters (1 new + %d base each)\n', ...
    numel(Po_Clu), numel(Matches), K);

save('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/G_Cl.mat', 'Matches', 'Po_Clu', '-v7.3');
disp('Saved: G_cl.mat');

% custom_distance_Po and custom_distance_SPr are loaded via:
% addpath /Users/mczhang/Documents/GitHub/FM/01-scripts/subcode/