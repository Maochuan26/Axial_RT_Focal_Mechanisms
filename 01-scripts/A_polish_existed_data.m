clc;clear;close all;
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/E_All.mat');
% Remove DDt_* fields
fieldsToRemove = {'DDt_AS1', 'DDt_AS2', 'DDt_CC1', 'DDt_EC1', 'DDt_EC2', 'DDt_EC3', 'DDt_ID1'};
Felix = rmfield(Felix, fieldsToRemove);

% Process W_* fields
wFields = {'W_AS1', 'W_AS2', 'W_CC1', 'W_EC1', 'W_EC2', 'W_EC3', 'W_ID1'};

% Original time vector: -0.25 to 1 s at 200 Hz (250 samples)
t_original = linspace(-0.25, 1, 250);

% New time vector: -0.32 to 0.32 s at 100 Hz (64 samples)
% Time step at 100 Hz = 0.01 s, so 64 samples cover 0.63 s
t_new = -0.32:0.01:0.31;  % This gives 64 points: -0.32, -0.31, ..., 0.30, 0.31

for i = 1:length(Felix)
    for j = 1:length(wFields)
        fieldName = wFields{j};
        waveform = Felix(i).(fieldName);
        
        % Skip if the field is empty
        if isempty(waveform)
            continue;
        end
        
        % Ensure waveform is a column vector
        waveform = waveform(:);
        
        % Downsample original waveform to 100 Hz
        t_downsampled = linspace(-0.25, 1, 125);
        waveform_downsampled = interp1(t_original, waveform, t_downsampled, 'linear');
        
        % Extract -0.25 to 0.31 portion (at 100 Hz) - this gives 57 samples
        idx_valid = t_downsampled >= -0.25 & t_downsampled <= 0.31;
        waveform_extracted = waveform_downsampled(idx_valid);
        t_extracted = t_downsampled(idx_valid);
        
        % Ensure waveform_extracted is a column vector
        waveform_extracted = waveform_extracted(:);
        
        % Calculate average of -0.25 to -0.18
        idx_avg = t_extracted >= -0.25 & t_extracted <= -0.18;
        avg_value = mean(waveform_extracted(idx_avg));
        
        % Create padding for -0.32 to -0.26 (7 samples: -0.32, -0.31, -0.30, -0.29, -0.28, -0.27, -0.26)
        n_pad = 8;
        padded_values = repmat(avg_value, n_pad, 1);
        
        % Combine padding with extracted waveform (7 + 57 = 64 samples)
        Felix(i).(fieldName) = [padded_values; waveform_extracted];
    end
end

% Verify the result
disp(['New waveform length: ' num2str(length(Felix(1).W_AS1))]);
disp(['Time vector length: ' num2str(length(t_new))]);