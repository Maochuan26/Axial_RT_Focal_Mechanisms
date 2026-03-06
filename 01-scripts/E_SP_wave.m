clear; close all;

addpath('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/');
fields = {'AS1','AS2','CC1','EC1','EC2','EC3','ID1'};
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/D_wave2.mat')
Felix([Felix.mag]<1)=[];
run('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/parameter_script_realtimeVer1_MC_focal.m'); % loads p into workspace

%% Settings
P.a.sttime  = -3;
P.a.edtime  =  7;
P.a.window  = [-0.25 1];    % (not used below, kept for your pipeline)
P.filt      = 1;            % (not used below, you use p.filt inside obtain_waveforms_fm)

tic;
for kz = 1:length(fields)
    tag = fields{kz};  % e.g., 'AS2'

    for i = 1:length(Felix)

        %% ---- A) Get picks robustly (treat empty OR NaN as missing) ----
        P0 = Felix(i).(['DDt_'  tag]);     % P pick time (sec)
        S0 = Felix(i).(['DDSt_' tag]);     % S pick time (sec)

        if isempty(P0) || isempty(S0) || any(isnan([P0 S0])) || any(~isfinite([P0 S0]))
            Felix(i).(['NSP_' tag]) = [1 1 1];
            continue;
        end

        S_pick = S0 - P0;  % S relative to P, in seconds

        if ~isfinite(S_pick) || S_pick <= 0
            Felix(i).(['NSP_' tag]) = [1 1 1];
            continue;
        end

        %% ---- B) Obtain 3C waveforms for this station ----
        [trace_Z, trace_N, trace_E] = obtain_waveforms_fm(Felix(i), kz, P.a.sttime, P.a.edtime, p);

        if isempty(trace_Z) || isempty(trace_N) || isempty(trace_E) || ...
                ~isfield(trace_Z,'dataFilt') || ~isfield(trace_N,'dataFilt') || ~isfield(trace_E,'dataFilt')
            Felix(i).(['NSP_' tag]) = [1 1 1];
            continue;
        end

        %% ---- C) Define windows (relative to P=0 and S=S_pick) ----
        noise_win = [-0.7, -0.1];   % relative to P
        P_win     = [-0.05, 0.25];  % relative to P
        S_win     = [-0.1, 0.6];    % relative to S

        % if picks too close, push windows apart
        if abs(S_pick) < 0.35
            shift = (0.35 - abs(S_pick)) / 2;
            P_win = P_win - shift;     % earlier
            S_win = S_win + shift;     % later
        end

        % Build time axis consistent with your trace padding to 2001 samples
        nSamp = size(trace_Z.dataFilt, 1);
        %t_trace = linspace(P.a.sttime, P.a.edtime, nSamp).';
        % trace is currently [on-3, on+7] so its time axis is origin-relative.
        % Shift it so that P is at 0:
        t_origin = linspace(P.a.sttime, P.a.edtime, nSamp).';  % relative to origin
        t_trace  = t_origin - P0;                               % relative to P
        %% ---- (NEW) G) Save 64-sample Z snippet at 100 Hz around P ----
        fs_out = 100;                 % target sampling rate (Hz)
        nKeep  = 64;                  % 32 before + (0) + 31 after = 64
        t_keep = (-32:31).' / fs_out; % time vector relative to P (sec), length 64

        % --- original time axis for filtered Z (already consistent with your window) ---
        % t_trace is nSamp x 1, from sttime to edtime
        z_in   = double(trace_Z.dataFilt(:,1));
        t_in   = double(t_trace);

        % --- resample to exactly 100 Hz on a uniform grid that spans your whole trace ---
        dt_out = 1/fs_out;
        t_out  = (P.a.sttime:dt_out:P.a.edtime).';  % uniform time vector

        % Interpolate (robust and dependency-free). 'pchip' preserves shape better than linear.
        z_out = interp1(t_in, z_in, t_out, 'pchip', 'extrap');

        % --- find indices corresponding to P-32 ... P+31 samples (i.e., -0.32 to +0.31 s) ---
        idx_keep = round((t_keep - P.a.sttime) * fs_out) + 1;  % map times -> indices in t_out

        % Safety check: if any index is out of range, pad with NaN (shouldn't happen with your st/ed times)
        W = nan(nKeep,1);
        ok = idx_keep >= 1 & idx_keep <= numel(z_out);
        W(ok) = z_out(idx_keep(ok));

        % Save to Felix with name W_<station>, e.g., W_AS1
        Felix(i).(['W_' tag]) = single(W);    % single saves space; change to double if you prefer

        noise_idx = find(t_trace >= noise_win(1)             & t_trace <= noise_win(2));
        P_idx     = find(t_trace >= P_win(1)                 & t_trace <= P_win(2));
        S_idx     = find(t_trace >= (S_pick + S_win(1))      & t_trace <= (S_pick + S_win(2)));

        if isempty(noise_idx) || isempty(P_idx) || isempty(S_idx)
            Felix(i).(['NSP_' tag]) = [1 1 1];
            continue;
        end

        %% ---- D) Extract and force vectors ----
        Z_noise = trace_Z.dataFilt(noise_idx, 1);  Z_noise = Z_noise(:);
        N_noise = trace_N.dataFilt(noise_idx, 1);  N_noise = N_noise(:);
        E_noise = trace_E.dataFilt(noise_idx, 1);  E_noise = E_noise(:);

        Z_P     = trace_Z.dataFilt(P_idx, 1);      Z_P     = Z_P(:);

        N_S     = trace_N.dataFilt(S_idx, 1);      N_S     = N_S(:);
        E_S     = trace_E.dataFilt(S_idx, 1);      E_S     = E_S(:);

        if isempty(Z_noise) || isempty(N_noise) || isempty(E_noise) || isempty(Z_P) || isempty(N_S) || isempty(E_S)
            Felix(i).(['NSP_' tag]) = [1 1 1];
            continue;
        end

        %% ---- E) Amplitudes (peak-to-peak) ----
        amp_noise_Z = range(Z_noise);
        amp_noise_N = range(N_noise);
        amp_noise_E = range(E_noise);

        amp_P_Z = range(Z_P);

        amp_S_N = range(N_S);
        amp_S_E = range(E_S);

        noise_amp = sqrt((amp_noise_Z.^2 + amp_noise_N.^2 + amp_noise_E.^2) / 3); % RMS 3C
        P_amp     = amp_P_Z;                                                      % vertical P
        S_amp     = sqrt((amp_S_N.^2 + amp_S_E.^2) / 2);                           % RMS NE

        %% ---- F) Store ----
        Felix(i).(['NSP_' tag]) = [noise_amp, S_amp, P_amp];

        % % % i == 1 && kz == 1 % Plot only for the first event and AS1 channel
        %     figure('Position', [100, 100, 800, 600]);
        % 
        %     % Define colors for the waveforms
        %     colors = {'b', 'r', 'g'}; % Z: blue, N: red, E: green
        % 
        %     % Create subplots for Z, N, E channels
        %     for ch = 1:3
        %         subplot(3, 1, ch);
        %         hold on;
        % 
        %         % Select the appropriate trace
        %         if ch == 1
        %             trace = trace_Z.dataFilt(:, 1); % Z channel
        %             ch_label = 'Z (Vertical)';
        %         elseif ch == 2
        %             trace = trace_N.dataFilt(:, 1); % N channel
        %             ch_label = 'N (North-South)';
        %         else
        %             trace = trace_E.dataFilt(:, 1); % E channel
        %             ch_label = 'E (East-West)';
        %         end
        % 
        %         % Plot the waveform
        %         plot(t_trace, trace, colors{ch}, 'LineWidth', 1.5, 'DisplayName', ch_label);
        % 
        %         % Highlight windows with shaded regions
        %         % Noise window
        %         patch([noise_win(1), noise_win(2), noise_win(2), noise_win(1)], ...
        %             [min(trace)*1.2, min(trace)*1.2, max(trace)*1.2, max(trace)*1.2], ...
        %             'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'DisplayName', 'Noise Window');
        % 
        %         % P window
        %         patch([P_win(1), P_win(2), P_win(2), P_win(1)], ...
        %             [min(trace)*1.2, min(trace)*1.2, max(trace)*1.2, max(trace)*1.2], ...
        %             'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'DisplayName', 'P Window');
        % 
        %         % S window
        %         patch([S_pick + S_win(1), S_pick + S_win(2), S_pick + S_win(2), S_pick + S_win(1)], ...
        %             [min(trace)*1.2, min(trace)*1.2, max(trace)*1.2, max(trace)*1.2], ...
        %             'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'DisplayName', 'S Window');
        % 
        %         % Add P and S pick lines
        %         xline(0, 'k--', 'P Pick', 'LineWidth', 1, 'HandleVisibility', 'off');
        %         xline(S_pick, 'm--', 'S Pick', 'LineWidth', 1, 'HandleVisibility', 'off');
        % 
        %         % Customize plot
        %         xlabel('Time relative to P pick (s)');
        %         ylabel('Amplitude');
        %         title(sprintf('Waveform for Event %d, Channel %s (%s)', i, fields{kz}, ch_label));
        %         grid on;
        %         legend('show', 'Location', 'northeast');
        %         xlim([-1 3]);
        %         hold off;
        %     end
        clear trace_Z trace_N trace_E
    end

    fprintf('Elapsed time after processing field %s: %.2f seconds\n', tag, toc);
end

save('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/E_NSP.mat', 'Felix');