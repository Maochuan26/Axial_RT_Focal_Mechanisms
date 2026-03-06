function ph2dt = read_ph2dtCatalogTTData_FM(filePh2dtCatalogTTData)
% Read a hypoDD ph2dt catalog and travel time input file
%
% Usage:
%   ph2dt = read_ph2dtCatalogTTData_FM(filePh2dtCatalogTTData)
%
% Input:
%   filePh2dtCatalogTTData - ASCII ph2dt input file containing hypocenters
%                            and travel times
%
% Output:
%   ph2dt - Struct array (one element per event) with fields:
%     yr      - Year (4 digits)
%     mo      - Month
%     da      - Day
%     hr      - Hour
%     mn      - Minute
%     sc      - Second
%     lat     - Latitude (decimal degrees north)
%     lon     - Longitude (decimal degrees east)
%     depth   - Depth (km)
%     mag     - Magnitude
%     erh     - Horizontal error
%     erz     - Vertical error
%     rms     - RMS travel time residual
%     ID      - Event ID
%     datenum - MATLAB serial date number
%     obs     - Struct with per-event observations:
%                 sta   - Station name (cell array)
%                 tt    - Travel time (s)
%                 wght  - Pick weight
%                 phase - Phase type ('P' or 'S')
%     Psum    - Number of P picks
%     Ssum    - Number of S picks

ph2dt = struct([]);

% Open file
if exist(filePh2dtCatalogTTData, 'file')
    fid = fopen(filePh2dtCatalogTTData, 'rt');
else
    error('read_ph2dtCatalogTTData_FM: cannot open file %s', filePh2dtCatalogTTData);
end

% Read all whitespace-delimited tokens
a = textscan(fid, '%s');
a = a{1};
fclose(fid);

% Locate event header lines (marked by '#')
i0 = find(strcmp(a, '#'));
i1 = [i0(2:end) - 1; length(a)];

% Parse each event
for i = length(i0):-1:1

    % --- Header fields ---
    ph2dt(i).yr    = sscanf(a{i0(i)+1},  '%f');
    ph2dt(i).mo    = sscanf(a{i0(i)+2},  '%f');
    ph2dt(i).da    = sscanf(a{i0(i)+3},  '%f');
    ph2dt(i).hr    = sscanf(a{i0(i)+4},  '%f');
    ph2dt(i).mn    = sscanf(a{i0(i)+5},  '%f');
    ph2dt(i).sc    = sscanf(a{i0(i)+6},  '%f');
    ph2dt(i).lat   = sscanf(a{i0(i)+7},  '%f');
    ph2dt(i).lon   = sscanf(a{i0(i)+8},  '%f');
    ph2dt(i).depth = sscanf(a{i0(i)+9},  '%f');
    ph2dt(i).mag   = sscanf(a{i0(i)+10}, '%f');
    ph2dt(i).erh   = sscanf(a{i0(i)+11}, '%f');
    ph2dt(i).erz   = sscanf(a{i0(i)+12}, '%f');
    ph2dt(i).rms   = sscanf(a{i0(i)+13}, '%f');
    ph2dt(i).ID    = sscanf(a{i0(i)+14}, '%f');

    ph2dt(i).datenum = datenum(ph2dt(i).yr, ph2dt(i).mo, ph2dt(i).da, ...
                               ph2dt(i).hr, ph2dt(i).mn, ph2dt(i).sc);

    % --- Observations (each obs = 4 tokens: sta tt wght phase) ---
    nObs = (i1(i) - i0(i) - 14) / 4;
    for j = nObs:-1:1
        base = i0(i) + 14 + (j-1)*4;
        ph2dt(i).obs.sta{j}   = a{base+1};
        ph2dt(i).obs.tt(j)    = sscanf(a{base+2}, '%f');
        ph2dt(i).obs.wght(j)  = sscanf(a{base+3}, '%f');
        ph2dt(i).obs.phase{j} = a{base+4};
    end

    % --- Phase counts ---
    ph2dt(i).Psum = sum(strcmp(ph2dt(i).obs.phase, 'P'));
    ph2dt(i).Ssum = sum(strcmp(ph2dt(i).obs.phase, 'S'));

end