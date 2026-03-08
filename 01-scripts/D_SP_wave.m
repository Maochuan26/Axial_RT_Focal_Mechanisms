%% D_SP_wave.m
% Computes NSP amplitude ratios and 64-sample W snippets for each event/station.
%
% Optimization: inner event loop uses parfor (Parallel Computing Toolbox).
% Results are collected in cell arrays then assigned back to Felix after each
% station iteration, avoiding parfor broadcast/classification issues.
%
% Input:  02-data/C_wave2.mat
% Output: 02-data/D_NSP.mat

clear; close all;
if ~exist('cfg','var'); run('config.m'); end
addpath(cfg.subcodeDir);
fields = {'AS1','AS2','CC1','EC1','EC2','EC3','ID1'};
load(fullfile(cfg.dataDir, 'C_wave2.mat'))
Felix([Felix.mag] < 1) = [];
run(fullfile(cfg.subcodeDir, 'parameter_script_realtimeVer1_MC_focal.m'));

%% Settings (P.a.* used below; p loaded by parameter_script)
P.a.sttime = -3;
P.a.edtime =  7;
P.filt     =  1;

fs_out = 100;
nKeep  = 64;
t_keep = (-32:31).' / fs_out;

nEv = length(Felix);
tic;

for kz = 1:length(fields)
    tag = fields{kz};

    % Pre-allocate per-event outputs
    NSP_out = repmat({[1 1 1]}, nEv, 1);   % default: no signal
    W_out   = cell(nEv, 1);                 % default: empty

    % Snapshot for parfor broadcast (avoids classifying Felix as a sliced var
    % while it's being modified in the outer kz loop)
    Felix_snap = Felix;
    p_snap     = p;       %#ok<NODEF>
    P_snap     = P;

    parfor i = 1:nEv
        ev  = Felix_snap(i);
        P0  = ev.(['DDt_'  tag]);
        S0  = ev.(['DDSt_' tag]);

        % Skip if picks missing
        if isempty(P0) || isempty(S0) || any(isnan([P0 S0])) || any(~isfinite([P0 S0]))
            continue;
        end
        S_pick = S0 - P0;
        if ~isfinite(S_pick) || S_pick <= 0
            continue;
        end

        % Obtain 3C waveforms
        [trace_Z, trace_N, trace_E] = obtain_waveforms_fm(ev, kz, P_snap.a.sttime, P_snap.a.edtime, p_snap);
        if isempty(trace_Z) || isempty(trace_N) || isempty(trace_E) || ...
                ~isfield(trace_Z,'dataFilt') || ~isfield(trace_N,'dataFilt') || ~isfield(trace_E,'dataFilt')
            continue;
        end

        % Build time axis relative to P
        nSamp    = size(trace_Z.dataFilt, 1);
        t_origin = linspace(P_snap.a.sttime, P_snap.a.edtime, nSamp).';
        t_trace  = t_origin - P0;

        % --- W snippet: 64 samples at 100 Hz centred on P ---
        dt_out   = 1 / fs_out;
        t_out    = (P_snap.a.sttime : dt_out : P_snap.a.edtime).';
        z_in     = double(trace_Z.dataFilt(:,1));
        z_out    = interp1(double(t_trace), z_in, t_out, 'pchip', 'extrap');
        idx_keep = round((t_keep - P_snap.a.sttime) * fs_out) + 1;
        W = nan(nKeep, 1);
        ok = idx_keep >= 1 & idx_keep <= numel(z_out);
        W(ok) = z_out(idx_keep(ok));
        W_out{i} = single(W);

        % --- Amplitude windows ---
        noise_win = [-0.7, -0.1];
        P_win     = [-0.05, 0.25];
        S_win     = [-0.1,  0.6];

        if abs(S_pick) < 0.35
            shift = (0.35 - abs(S_pick)) / 2;
            P_win = P_win - shift;
            S_win = S_win + shift;
        end

        noise_idx = find(t_trace >= noise_win(1) & t_trace <= noise_win(2));
        P_idx     = find(t_trace >= P_win(1)     & t_trace <= P_win(2));
        S_idx     = find(t_trace >= (S_pick + S_win(1)) & t_trace <= (S_pick + S_win(2)));

        if isempty(noise_idx) || isempty(P_idx) || isempty(S_idx)
            continue;
        end

        Z_noise = trace_Z.dataFilt(noise_idx, 1);
        N_noise = trace_N.dataFilt(noise_idx, 1);
        E_noise = trace_E.dataFilt(noise_idx, 1);
        Z_P     = trace_Z.dataFilt(P_idx,    1);
        N_S     = trace_N.dataFilt(S_idx,    1);
        E_S     = trace_E.dataFilt(S_idx,    1);

        if isempty(Z_noise) || isempty(N_noise) || isempty(E_noise) || ...
                isempty(Z_P)  || isempty(N_S)   || isempty(E_S)
            continue;
        end

        amp_noise_Z = range(Z_noise);
        amp_noise_N = range(N_noise);
        amp_noise_E = range(E_noise);
        amp_P_Z     = range(Z_P);
        amp_S_N     = range(N_S);
        amp_S_E     = range(E_S);

        noise_amp = sqrt((amp_noise_Z^2 + amp_noise_N^2 + amp_noise_E^2) / 3);
        P_amp     = amp_P_Z;
        S_amp     = sqrt((amp_S_N^2 + amp_S_E^2) / 2);

        NSP_out{i} = [noise_amp, S_amp, P_amp];
    end  % parfor i

    % Assign results back to Felix
    for i = 1:nEv
        Felix(i).(['NSP_' tag]) = NSP_out{i};
        if ~isempty(W_out{i})
            Felix(i).(['W_' tag]) = W_out{i};
        end
    end

    fprintf('Elapsed after station %s: %.2f s\n', tag, toc);
end  % for kz

save(fullfile(cfg.dataDir, 'D_NSP.mat'), 'Felix');
fprintf('D done: %d events -> D_NSP.mat\n', numel(Felix));
