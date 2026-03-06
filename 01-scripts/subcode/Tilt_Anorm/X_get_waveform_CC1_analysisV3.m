clc; clear; close all;

% =========================
% Load two days
% =========================
A = load('py_trace_normal_20250220-0221.mat');   % normal day
B = load('py_trace_target.mat');   % target day

% Expect variables from your Python: data (3xN) and fs
Xn = double(A.data);
Xt = double(B.data);
fsn = double(A.fs);
fst = double(B.fs);

if abs(fsn - fst) > 1e-6
    error('Sampling rates differ: normal fs=%.6f, target fs=%.6f', fsn, fst);
end
fs = fsn;

chan = {'HHZ','HHN','HHE'};
if isfield(A,'chan')
    c = A.chan;
    if iscell(c), chan = c(:); else, chan = cellstr(c); end
end

% =========================
% Welch PSD settings (whole day)
% =========================
win_sec = 120;                         % same as your plot
nwin    = max(4096, round(win_sec*fs));
nover   = round(0.5*nwin);
nfft    = max(8192, 2^nextpow2(nwin));

% =========================
% Plot: Normal (black) vs Target (blue)
% =========================
figure('Color','w'); clf;

for k = 1:3
    xn = Xn(k,:) - mean(Xn(k,:));
    xt = Xt(k,:) - mean(Xt(k,:));

    [Pnn,f] = pwelch(xn, hann(nwin), nover, nfft, fs, 'psd');
    [Ptt,~] = pwelch(xt, hann(nwin), nover, nfft, fs, 'psd');

    subplot(3,1,k)
    semilogx(f, 10*log10(Pnn+eps), 'k', 'LineWidth', 1); hold on;
    semilogx(f, 10*log10(Ptt+eps), 'b', 'LineWidth', 1);
    grid on
    xlim([0.01, fs/2])
    ylim([-50 120]);
    ylabel([strtrim(chan{k}) ' (dB/Hz)'])

    if k==1
        title(sprintf('Whole-day PSD comparison (Welch), win=%ds', win_sec))
        legend({'Normal','Target'}, 'Location','southwest')
    end
    if k<3
        set(gca,'XTickLabel',[])
    end
end
xlabel('Frequency (Hz)')