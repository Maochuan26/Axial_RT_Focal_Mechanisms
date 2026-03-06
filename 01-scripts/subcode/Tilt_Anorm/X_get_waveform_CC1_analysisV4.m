clc; clear; close all;

% =========================
% Load 3 datasets
% =========================
A = load('py_trace_normal.mat');              % Normal (black)
B = load('py_trace_target.mat');              % Target (blue)
C = load('py_trace_normal0213-0215.mat');     % Normal 0213–0215 (red)

Xn = double(A.data);   Xt = double(B.data);   Xc = double(C.data);
fsn = double(A.fs);    fst = double(B.fs);    fsc = double(C.fs);

if max(abs([fsn-fst, fsn-fsc])) > 1e-6
    error('Sampling rates differ: normal=%.6f, target=%.6f, normal0213-0215=%.6f', fsn, fst, fsc);
end
fs = fsn;

chan = {'HHZ','HHN','HHE'};
if isfield(A,'chan')
    cc = A.chan;
    if iscell(cc), chan = cc(:); else, chan = cellstr(cc); end
end

% =========================
% Welch PSD settings
% =========================
win_sec = 120;
nwin    = max(4096, round(win_sec*fs));
nover   = round(0.5*nwin);
nfft    = max(8192, 2^nextpow2(nwin));

% =========================
% Plot: 3 subplots, each has 3 curves
% =========================
figure('Color','w'); clf;

for k = 1:3
    xn = Xn(k,:) - mean(Xn(k,:));
    xt = Xt(k,:) - mean(Xt(k,:));
    xc = Xc(k,:) - mean(Xc(k,:));

    [Pnn,f] = pwelch(xn, hann(nwin), nover, nfft, fs, 'psd');
    [Ptt,~] = pwelch(xt, hann(nwin), nover, nfft, fs, 'psd');
    [Pcc,~] = pwelch(xc, hann(nwin), nover, nfft, fs, 'psd');

    subplot(3,1,k)
    semilogx(f, 10*log10(Pnn+eps), 'k', 'LineWidth', 1); hold on
    semilogx(f, 10*log10(Ptt+eps), 'b', 'LineWidth', 1);
    semilogx(f, 10*log10(Pcc+eps), 'r', 'LineWidth', 1);
    grid on

    xlim([0.01, fs/2]);
    ylim([-50 120]);
    ylabel([strtrim(chan{k}) ' (dB/Hz)'])

    if k == 1
        title(sprintf('Whole-day PSD comparison (Welch), win=%ds', win_sec))
        legend({'Normal','Target',['2026yea' ...
            '0213–0215']}, 'Location','southwest')
    end
    if k < 3
        set(gca,'XTickLabel',[])
    end
end
xlabel('Frequency (Hz)')