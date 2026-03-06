clc; clear; close all;

data_mat   = '/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/E_NSP.mat';
model_path = '/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/PolarPicker_unified_TMSF_001.keras';
out_mat    = '/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/F_DLpol.mat';
py_script  = '/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/predict_polarity.py';

python_exe = '/opt/miniconda3/envs/FM_RT/bin/python';  % ← FM_RT env

cmd = sprintf('"%s" "%s" "%s" "%s" "%s"', ...
    python_exe, py_script, data_mat, model_path, out_mat);

fprintf('Running prediction...\n');
[status, output] = system(cmd);
disp(output)

if status ~= 0
    error('Python script failed with status %d', status);
end

load(out_mat, 'Felix');
Felix = [Felix{:}];   % now Felix is 1×28 struct array
fprintf('Done. Loaded Felixw with %d events.\n', numel(Felix));
save(out_mat, 'Felix');