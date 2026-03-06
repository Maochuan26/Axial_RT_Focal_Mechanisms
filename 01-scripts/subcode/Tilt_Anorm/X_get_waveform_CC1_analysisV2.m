clc; clear; close all;

tmp  = load('py_trace_normal.mat');
X    = double(tmp.data);          % 3 x N
fs   = double(tmp.fs);            % Hz

chan = {'HHZ','HHN','HHE'};
if isfield(tmp,'chan')
    c = tmp.chan;
    if iscell(c), chan = c(:); else, chan = cellstr(c); end
end

% Welch settings (good for day-long noise)
win_sec = 120;                      % 2-min windows (try 60–300)
nwin    = round(win_sec * fs);
nwin    = max(nwin, 4096);
nover   = round(0.5 * nwin);
nfft    = max(8192, 2^nextpow2(nwin));

figure('Color','w'); clf;
for k = 1:3
    x = X(k,:);
    x = x - mean(x);               % remove mean

    [Pxx,f] = pwelch(x, hann(nwin), nover, nfft, fs, 'psd');  % units^2/Hz

    subplot(3,1,k)
    semilogx(f, 10*log10(Pxx + eps), 'k'); grid on
    xlim([0.01, fs/2])
    ylabel([strtrim(chan{k}) ' (dB/Hz)'])
    if k==1, title(sprintf('Whole-day PSD (Welch), win=%gs', win_sec)); end
    if k<3, set(gca,'XTickLabel',[]); end
end
xlabel('Frequency (Hz)')