clc; clear; close all;

% =========================
% Load 3 datasets
% =========================
A = load('py_trace_normal.mat');              % Normal (black)
B = load('py_trace_target.mat');              % Target (blue)
C = load('py_trace_normal0213-0215.mat');     % Normal 0213–0215 (red)

Xall   = {double(A.data), double(B.data), double(C.data)};
labels = {'Normal','Target','Normal 0213–0215'};
cols   = {'k','b','r'};

fsA = double(A.fs); fsB = double(B.fs); fsC = double(C.fs);
if max(abs([fsA-fsB, fsA-fsC])) > 1e-6
    error('Sampling rates differ: normal=%.6f, target=%.6f, normal0213-0215=%.6f', fsA, fsB, fsC);
end
fs = fsA;

% Channel labels
chan = {'HHZ','HHN','HHE'};
if isfield(A,'chan')
    c = A.chan;
    if iscell(c), chan = c(:); else, chan = cellstr(c); end
end

% =========================
% Median-PSD settings
% =========================
win_sec = 120;
Lwin    = round(win_sec*fs);                  % samples per window
nfft    = max(8192, 2^nextpow2(Lwin));
w       = hann(Lwin);

% =========================
% Plot: 3 subplots, each has 3 curves (median over windows)
% x-axis LOG, with DC removed (f>0)
% =========================
figure('Color','w'); clf;

for kch = 1:3
    subplot(3,1,kch); hold on; grid on

    for d = 1:3
        X = Xall{d};
        x = X(kch,:) - mean(X(kch,:));

        nwin = floor(length(x)/Lwin);
        if nwin < 2
            error('Not enough data for %ds windows in dataset %s', win_sec, labels{d});
        end

        Pmat = [];
        f_keep = [];   %#ok<NASGU>

        for i = 1:nwin
            ii = (i-1)*Lwin + (1:Lwin);
            xseg = x(ii);
            xseg = xseg - mean(xseg);

            [Pxx,f] = pwelch(xseg, w, 0, nfft, fs, 'psd');

            % ---- remove DC so log-x works ----
            Pxx = Pxx(2:end);
            f2  = f(2:end);

            % store
            if isempty(Pmat)
                Pmat = zeros(length(Pxx), nwin);
                f_keep = f2; %#ok<NASGU>
            end
            Pmat(:,i) = Pxx;
        end

        Pmed = median(Pmat, 2);

        % plot
        semilogx(f2, 10*log10(Pmed+eps), cols{d}, 'LineWidth', 1);
    end

    set(gca,'XScale','log')   % force log scale
    xlim([0.01, fs/2])
    ylim([-50 120]);
    ylabel([strtrim(chan{kch}) ' (dB/Hz)'])

    if kch == 1
        title(sprintf('Whole-day PSD (median over %ds windows) — earthquakes suppressed', win_sec))
        legend(labels, 'Location','southwest')
    end
    if kch < 3
        set(gca,'XTickLabel',[])
    end
end

xlabel('Frequency (Hz)')