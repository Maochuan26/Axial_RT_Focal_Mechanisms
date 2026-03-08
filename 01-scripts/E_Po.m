clc; clear; close all;
if ~exist('cfg','var'); run('config.m'); end

data_mat   = fullfile(cfg.dataDir, 'D_NSP.mat');
model_path = fullfile(cfg.dataDir, 'PolarPicker_unified_TMSF_001.keras');
out_mat    = fullfile(cfg.dataDir, 'E_DLpol.mat');
py_script  = fullfile(cfg.subcodeDir, 'predict_polarity.py');

python_exe = cfg.pythonExe;

% Pass --cache so the script skips events already predicted in a previous run
cmd = sprintf('"%s" "%s" "%s" "%s" "%s" --cache "%s"', ...
    python_exe, py_script, data_mat, model_path, out_mat, out_mat);

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