clc; clear;
% Build time window: origin time -3s / +7s
t_start_dn = datenum(2026,2,22,00,00,00);
t_final_dn = datenum(2026,2,23,00,00,00);

t_start_str = [datestr(t_start_dn, 'yyyy-mm-ddTHH:MM:SS') ...
    sprintf('.%03d', round(mod(t_start_dn*86400, 1)*1000)) 'Z'];
t_final_str = [datestr(t_final_dn, 'yyyy-mm-ddTHH:MM:SS') ...
    sprintf('.%03d', round(mod(t_final_dn*86400, 1)*1000)) 'Z'];

%fprintf('Event %d / %d | ID %d | %s  to  %s\n', ...
%   i, length(Felix), Felix(i).ID, t_start_str, t_final_str);
% Add the folder containing get_trace.py to Python path
if count(py.sys.path, '') == 0
    insert(py.sys.path, int32(0), '');
end
% Import the module once
gt = py.importlib.import_module('get_trace_CC1');

try
    % Call Python — it fetches data and saves py_trace.mat internally
    gt.get_trace_CC1(t_start_str, t_final_str);

    % Load the .mat file Python just wrote — fast, no type conversion needed
    tmp = load('py_trace.mat');


    %Trace = tmp.trace;


catch ME
    warning('Event failed — %s', ME.message);

    % If it's a Python exception, print the Python stack too
    if strcmp(ME.identifier,'MATLAB:Python:PyException') && isprop(ME,'ExceptionObject')
        try
            disp("----- Python exception (full) -----")
            disp(ME.ExceptionObject)
        catch
        end
    end

    disp("----- MATLAB stack -----")
    disp(getReport(ME,'extended','hyperlinks','off'));
end
