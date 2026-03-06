clc; clear; close all;

% Load what Python saved
tmp = load('py_trace.mat');

% Expect my format: data (3xN), fs, t0, chan
X   = double(tmp.data);      % 3 x N
fs  = double(tmp.fs);        % Hz
t0  = tmp.t0;  if iscell(t0), t0 = t0{1}; end
chan = tmp.chan; if ~iscell(chan), chan = cellstr(chan); end

N = size(X,2);

% ---- Downsample only for plotting ----
maxPoints = 2e6;                 % adjust if you want (1e6~3e6 is usually OK)
step = max(1, ceil(N / maxPoints));
idx = 1:step:N;

t_hours = (idx-1) / fs / 3600;   % hours since start

figure('Color','w'); clf;
for k = 1:3
    subplot(3,1,k)
    plot(t_hours, X(k,idx), 'k');
    grid on
    ylabel(strtrim(chan{k}))
    if k == 1
        title(sprintf('AXCC1 3-Component | start: %s | fs=%.1f Hz | plotted every %d samples', ...
            t0, fs, step));
    end
    if k < 3, set(gca,'XTickLabel',[]); end
end
xlabel('Time since start (hours)')