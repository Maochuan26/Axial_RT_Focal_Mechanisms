%% config.m — Machine-specific paths for FM6_RealTime pipeline
% =========================================================
% EDIT ONLY THESE TWO LINES for a new machine/account:
cfg.projectDir = '/Users/mczhang/Documents/GitHub/FM6_RealTime';
cfg.pythonExe  = '/opt/miniconda3/envs/FM_RT/bin/python';
% =========================================================
% Everything below is derived automatically — do not edit.

cfg.htdocs      = '/Applications/MAMP/htdocs';            % MAMP web root
cfg.siblingsDir = fileparts(cfg.projectDir);               % parent GitHub folder

cfg.dataDir     = fullfile(cfg.projectDir, '02-data');
cfg.scriptsDir  = fullfile(cfg.projectDir, '01-scripts');
cfg.subcodeDir  = fullfile(cfg.projectDir, '01-scripts', 'subcode');
cfg.graphicsDir = fullfile(cfg.projectDir, '03-graphics');
cfg.hashDir     = fullfile(cfg.projectDir, '01-scripts', 'HASH');

%% Add to MATLAB path
addpath(cfg.projectDir);     % so config.m itself is findable after first run
addpath(cfg.scriptsDir);
addpath(cfg.subcodeDir);
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'axial'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'general'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'axial', 'Focal'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'hypomat_2019_unix'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'felix'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'Analysiscode'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'HASH_code'));
addpath(fullfile(cfg.siblingsDir, 'Axial-AutoLocate', 'AxialOutput'));
addpath(fullfile(cfg.siblingsDir, 'AutomaticFM'));
addpath(fullfile(cfg.siblingsDir, 'FM'));
cd(cfg.projectDir);
