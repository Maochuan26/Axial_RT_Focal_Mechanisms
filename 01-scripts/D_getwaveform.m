clc; clear;
addpath('/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode/');
load('/Users/mczhang/Documents/GitHub/FM6_RealTime/02-data/C_ph2dt.mat')

% Add subcode folder to Python path so get_traceFM.py is found
subcodeDir = '/Users/mczhang/Documents/GitHub/FM6_RealTime/01-scripts/subcode';
if count(py.sys.path, subcodeDir) == 0
    insert(py.sys.path, int32(0), subcodeDir);
end

% Import the module once
gt = py.importlib.import_module('get_traceFM');

% Filter events
Felix([Felix.PSpair] < 6) = [];
tic;
for i = 1:length(Felix)

    dt_on    = datetime(Felix(i).on, 'ConvertFrom','datenum', 'TimeZone','UTC');
    dt_start = dt_on + seconds(-3);
    dt_final = dt_on + seconds(+7);

    t_start_str = [char(dt_start, "yyyy-MM-dd'T'HH:mm:ss.SSS") 'Z'];
    t_final_str = [char(dt_final, "yyyy-MM-dd'T'HH:mm:ss.SSS") 'Z'];

    try
        gt.get_traceFM(t_start_str, t_final_str);
        tmp = load('py_trace.mat');
        Felix(i).trace = tmp.trace;
    catch ME
        warning('Event %d (ID %d): failed — %s', i, Felix(i).ID, ME.message);
        Felix(i).trace = [];
    end
end