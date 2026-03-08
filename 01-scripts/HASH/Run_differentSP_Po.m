% Define parameters
clc;clear;close all;
addpath '/Users/mczhang/Documents/GitHub/FM/01-scripts/matlab_ww'
path_FM= '/Users/mczhang/Documents/GitHub/FM/01-scripts/HASH_Manual_5test';
cd /Users/mczhang/Documents/GitHub/FM/01-scripts/HASH_Manual_5test/


% Define the static content of the hash.input file
static_content = {
    'station.dat'
    'reverse.dat'
    'Acor.dat'
    'amp.dat'
    'phase.dat'
    'hashout1.dat'
    'hashout2.dat'
    'hashout3.dat'
    'hashout4.dat'
    '360'
    '180'
    '5'
    '30'
    '300'
    '1'
    '' % Placeholder for expanded range 0:0.05:0.5
    '0'
    '0'
    '' % Placeholder for expanded range 0:0.1:0.9
    '25'
    '45'
    '0.50000'
    '2'
    'velmod1.dat'
    'velmod2.dat'
    };

% Define the ranges
range1 = 0:0.05:0.5;
range2 = 0:0.1:0.9;

% Convert the ranges to strings
range1_str = num2str(range1, '%.4f ');
range2_str = num2str(range2, '%.4f ');

% Trim the trailing space
range1_str = strtrim(range1_str);
range2_str = strtrim(range2_str);

% Iterate over all combinations of range1 and range2 values
for i = 1:length(range1)
    for j = 1:length(range2)
        % Update the static content with the current values
        static_content{16} = num2str(range1(i), '%.4f ');
        static_content{19} = num2str(range2(j), '%.4f ');
        clear hash.input
        % Generate a unique filename for each combination
        filename = 'hash.input';
        outputname=sprintf('G_FM_%d_%d.mat', range1(i)*100, range2(j)*10);
        % Write the modified content to the hash.input file
        fileID = fopen(filename, 'w');
        for k = 1:length(static_content)
            fprintf(fileID, '%s\n', static_content{k});
        end
        fclose(fileID);
        !./hash_driver3 < hash.input
        filename1=[path_FM,'/hashout1.dat'];
        filename2=[path_FM,'/hashout2.dat'];
        filename3=[path_FM,'/hashout3.dat'];
        [event1] = read_hd3_output1(filename1);
        nevent = length(event1);
        [event2] = read_hd3_output2(filename2);
        nevent2 = length(event2);
        [event3] = read_hd3_output3(filename3);
        nevent3 = length(event3);
        save(outputname, 'event1', 'event2','event3');
        clear hash.input
    end
end


