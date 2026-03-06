function station = axial_stationsNewOrder
% Creates structure of network OO stations at Axial (reorderd in early 2017)
% 
% Usage
%   station = axial_stations
%
% Inputs
% 
% Outputs
%   STATION - Vector structure with fields
%               name - Station name
%               lat  - Latitude in decimal degrees
%               lon  - Longitude in decimal degrees
%               elev - Elevation in meters
%               id   - Station id used internally (1 to number of stations)
%               order- MC added
% Reordered on jan 10, 2017

station(1).name='AXCC1'; % Checked
station(1).lat  = 45.95468;
station(1).lon  = -130.0089;
station(1).elev = -1528;
station(1).id = 1;
station(1).order = 3;
station(1).BPR = 'MJ03F';

station(2).name='AXEC1';% Checked
station(2).lat  = 45.94958;
station(2).lon  = -129.9797;
station(2).elev = -1512;
station(2).id = 2;
station(2).order = 4;

station(3).name='AXEC2';% Checked
station(3).lat  = 45.93967;
station(3).lon  = -129.9738;
station(3).elev = -1519;
station(3).id = 3;
station(3).order = 5;
station(3).BPR = 'MJ03E';

station(4).name='AXEC3';% Checked
station(4).lat  = 45.93607;
station(4).lon  = -129.9785;
station(4).elev = -1516;
station(4).id = 4;
station(4).order = 6;

station(5).name ='AXAS1';% Checked
station(5).lat  = 45.93356;
station(5).lon  = -129.9992;
station(5).elev = -1529;
station(5).id = 5;
station(5).order = 1;

station(6).name='AXAS2';% Checked
station(6).lat  = 45.93377;
station(6).lon  = -130.0141;
station(6).elev = -1544.4;
station(6).id = 6;
station(6).order = 2;
station(6).BPR = 'MJ03B';

station(7).name= 'AXID1';% Checked
station(7).lat  = 45.92573;
station(7).lon  = -129.978;
station(7).elev = -1527.5;
station(7).id = 7;
station(7).order = 7;
station(7).BPR = 'MJ03D';

station(8).name = 'AXBA1';% Checked
station(8).lat  = 45.82018;
station(8).lon  = -129.7367;
station(8).elev  = -2607.2;
station(8).id = 8;
station(8).order = 8;