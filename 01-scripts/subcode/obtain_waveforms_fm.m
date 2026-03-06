function [traceZ, traceN, traceE] = obtain_waveforms_fm(ph2dt, ind_station, st1, st2, p)
% Obtain waveforms for Z, N, E channels in one call
stations  = {'AXAS1', 'AXAS2', 'AXCC1', 'AXEC1', 'AXEC2', 'AXEC3', 'AXID1'};
channelsZ = {'EHZ',   'EHZ',   'HHZ',   'EHZ',   'HHZ',   'EHZ',   'EHZ'};
channelsN = {'EHN',   'EHN',   'HHN',   'EHN',   'HHN',   'EHN',   'EHN'};
channelsE = {'EHE',   'EHE',   'HHE',   'EHE',   'HHE',   'EHE',   'EHE'};

% Select station and channels
station  = stations{ind_station};
channelZ = channelsZ{ind_station};
channelN = channelsN{ind_station};
channelE = channelsE{ind_station};

trace1 = ph2dt.trace;

% Default outputs
traceZ = []; traceN = []; traceE = [];

% Quick sanity
if isempty(trace1) || ~isfield(trace1,'station') || ~isfield(trace1,'channel') || ~isfield(trace1,'data')
    return;
end

% NOTE: your ph2dt.trace is a "struct of arrays" (23x...),
% so we need to find row indices for the desired station/channel.
stList = cellstr(trace1.station);   % 23x1 cell
chList = cellstr(trace1.channel);   % 23x1 cell

rowZ = find(strcmp(stList, station) & strcmp(chList, channelZ), 1, 'first');
rowN = find(strcmp(stList, station) & strcmp(chList, channelN), 1, 'first');
rowE = find(strcmp(stList, station) & strcmp(chList, channelE), 1, 'first');

% If any component missing, return empty
if isempty(rowZ) || isempty(rowN) || isempty(rowE)
    return;
end

% (Optional) keep your existing timeWindow logic; ph2dt.trace is already cut.
% phaseT = ph2dt.(['DDt_', station(3:end)]);
% tlim = [st1 st2];
% timeWindow = ph2dt.on + (phaseT + tlim) / 86400;

% ---- XX replacements: build trace structs from the selected rows ----
traceZ = build_one_trace(trace1, rowZ);
traceN = build_one_trace(trace1, rowN);
traceE = build_one_trace(trace1, rowE);
% -------------------------------------------------------------------

% Validate traces
if isempty(traceZ) || isempty(traceN) || isempty(traceE) || ...
        length(traceZ.data) < 700 || length(traceN.data) < 700 || length(traceE.data) < 700
    traceZ = []; traceN = []; traceE = [];
    return;
end

% Apply filtering and demeaning
for i = 1:length(traceZ)   % usually 1
    for j = 1
        try
            traceZ(i).dataFilt(:, j) = trace_filter(traceZ(i).data, p.filt(j), traceZ(i).sampleRate);
            traceN(i).dataFilt(:, j) = trace_filter(traceN(i).data, p.filt(j), traceN(i).sampleRate);
            traceE(i).dataFilt(:, j) = trace_filter(traceE(i).data, p.filt(j), traceE(i).sampleRate);

            traceZ(i).dataFilt(:, j) = traceZ(i).dataFilt(:, j) - mean(traceZ(i).dataFilt(:, j));
            traceN(i).dataFilt(:, j) = traceN(i).dataFilt(:, j) - mean(traceN(i).dataFilt(:, j));
            traceE(i).dataFilt(:, j) = traceE(i).dataFilt(:, j) - mean(traceE(i).dataFilt(:, j));
        catch
            traceZ = []; traceN = []; traceE = [];
            return;
        end
    end
end

end

% ---------- helper ----------
function tr = build_one_trace(trace1, row)
    tr = struct();

    % Copy metadata (convert char rows -> strings)
    if isfield(trace1,'network');   tr.network   = strtrim(trace1.network(row,:));   end
    if isfield(trace1,'station');   tr.station   = strtrim(trace1.station(row,:));   end
    if isfield(trace1,'location');  tr.location  = trace1.location;                  end % location is '' in your dump
    if isfield(trace1,'channel');   tr.channel   = strtrim(trace1.channel(row,:));   end

    if isfield(trace1,'sensitivity');            tr.sensitivity = trace1.sensitivity(row); end
    if isfield(trace1,'sensitivityFrequency');   tr.sensitivityFrequency = trace1.sensitivityFrequency(row); end
    if isfield(trace1,'sampleCount');            tr.sampleCount = trace1.sampleCount(row); end
    if isfield(trace1,'sampleRate');             tr.sampleRate  = trace1.sampleRate(row); end
    if isfield(trace1,'startTime');              tr.startTime   = strtrim(trace1.startTime(row,:)); end
    if isfield(trace1,'endTime');                tr.endTime     = strtrim(trace1.endTime(row,:)); end

    % Data: row vector -> column double
    x = double(trace1.data(row,:)).';
    % Your main code assumes 2001 samples (linspace(...,2001)).
    if numel(x) == 2000
        x(end+1,1) = x(end);  % pad to 2001
        if isfield(tr,'sampleCount'); tr.sampleCount = tr.sampleCount + 1; end
    end
    tr.data = x;
end