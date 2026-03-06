% Parameters for data processing in realtime mode 
% This version for June 23, 2017
%
% Redoing triggering & association with lower thresholds

%% Data loading
p.tryLocalDataFirst = true;       %MZ      % Look first for data locally before going to IRIS DMC
p.tryRemoteData = true;                  % Look for data in IRIS DMC 
p.saveLocalData = true;         %MZ        % Save data locally if obtained from IRIS DMC
p.retryTimes = 3;                        % Retry this many times if dan nnnnnn n ta not found in IRIS DMC (real time mode)
p.retryWait = 300;                       % Wait this long before retrying data load (real time mode)
p.fileGot = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/get_localDataAxial.mat';    % File with a structure of got (what data has been saved, processed)
%p.fileGot = [];    % mc changed File with a structure of got (what data has been saved, processed)

%% Looping through data
p.loop.incDate = 1/24;                   % Increment for date number in days when looping through data
p.loop.realtimeDateDelay = 1/24/60;      % Wait this long in days after the end of an interval to load data (real time mode)
p.loop.overlap = 15;                     % Overlap in seconds between data files
p.loop.minTraceLen = 15;                 % Ignore data records less than this long
p.loop.checkBack = false;     %MZ            % Logical to indicate code is checking back for diverted data 
p.loop.checkBackDelay = [4 7 10];        % Time to wait in days before checking back

%% Network
p.network.network= 'OO';
p.network.location = '*';
p.network.station = {'AXCC1','AXCC1','AXCC1','AXCC1', ...
                     'AXEC1','AXEC1','AXEC1', ...
                     'AXEC2','AXEC2','AXEC2','AXEC2', ...
                     'AXEC3','AXEC3','AXEC3', ...
                     'AXAS1','AXAS1','AXAS1', ...
                     'AXAS2','AXAS2','AXAS2', ...
                     'AXID1','AXID1','AXID1', ...
                     'AXBA1','AXBA1','AXBA1','AXBA1'};
p.network.stationID = [1 1 1 1 2 2 2 3 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8 8];
p.network.channel = {'HHE','HHN','HHZ','HDH', ...
                     'EHE','EHN','EHZ', ...
                     'HHE','HHN','HHZ','HDH', ...
                     'EHE','EHN','EHZ', ...
                     'EHE','EHN','EHZ', ...
                     'EHE','EHN','EHZ', ...
                     'EHE','EHN','EHZ', ...
                     'HHE','HHN','HHZ','HDH' };
p.network.channelID = [1 2 3 4 1 2 3 1 2 3 4 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 4];
                           
%% Script to create structure for Axial Stations (indicies match p.network.id)
p.stationScript = 'axial_stationsNewOrder';

%% Unique IDs for events, picks and locations (Needs ".mat" extension in file name)
p.fileUniqueID = [];

%% Bad Data (Needs to be fully implemented)
p.bad.station = {'AXCC1' 'AXCC1' 'AXID1'};                 % 'AXEC2'};
p.bad.channel = {'HHN' 'HHE' 'EHE' };                      % 'HHE'};
p.bad.on = datenum('April 1, 2015')-1 + [1 24 24];         % 24];
p.bad.off = datenum('April 1, 2015')-1 + [29 29 31];       % 30];

%% Output directories
p.dir.data = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate';
p.dir.input = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutput/';
p.dir.output = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutput/';
p.dir.plotChunkRS = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutputImages/HourlyRSPlot';
p.dir.plotEventRS = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutputImages/EventRSPlot';
p.dir.plotEventPickRS = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutputImages/PickRSPlot'; 
p.dir.plotEventLocationRS = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutputImages/LocationRSPlot'; 
p.dir.plotEventMomentRS = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutputImages/MomentRSPlot';
p.dir.plotLocationMap = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/AxialOutputImages/LocationMapPlot';
         
% %% Plotting
% % Hourly plots of triggers
% p.plot.trigger = 0;   %[0 0];%MC changed from 0
% % Record section for the interval of data being processed
% p.plot.chunkRS = 0; % [2 2]; %1 on screen, 2 save jpeg %%MC changed from 2
% % Event (associated) record section
% p.plot.eventRS = 0; %1 on screen, 2 save jpeg %%MC changed from 2
% % Pick record section
% p.plot.eventPickRS = 0; %1 on screen, 2 save jpeg; negative for odd events %MC changed from 0
% % Location record sectin
% p.plot.eventLocationRS = 0; % 1; %1 on screen, 2 save jpeg %MC changed from 0
% % Map of epicenters
% p.plot.locationMap = 0; %1 on screen, 2 save jpeg %MC changed from 2 %MZ 2 is for save
% % Moment calulation record section
% p.plot.eventMomentRS = 0; %2; % 1; %1 on screen, 2 save jpeg %MC changed from 0
% % Index of data filtering for record sections
% p.plot.iFilt = 1;
% p.plot.kPick = 1; %1 - single plot, %2 all the details
% p.plot.polPick = 1; %1 plot;
%% Plotting
% Hourly plots of triggers
p.plot.trigger = 0;   %[0 0];%MC changed from 0
% Record section for the interval of data being processed
p.plot.chunkRS = 0; % [2 2]; %1 on screen, 2 save jpeg %%MC changed from 2
% Event (associated) record section 
p.plot.eventRS = 0; %1 on screen, 2 save jpeg %%MC changed from 2 Figure 301
% Pick record section
p.plot.eventPickRS = 0; %1 on screen, 2 save jpeg; negative for odd events %MC changed from 0
% Location record sectin
p.plot.eventLocationRS = 0; % 1; %1 on screen, 2 save jpeg %MC changed from 0
% Map of epicenters
p.plot.locationMap = 0; %1 on screen, 2 save jpeg %MC changed from 2
% Moment calulation record section
p.plot.eventMomentRS = 0; %2; % 1; %1 on screen, 2 save jpeg %MC changed from 0 Figure 601
% Index of data filtering for record sections
p.plot.iFilt = 1; % 1- plot the trace_panelPlot in the first cloumn with a bandpass of [4 30]. %MZ added 
p.plot.kPick = 2; %1 - single plot, %2 all the details
p.plot.polPick = 1; %1 plot;
p.plot.eventFocalRS=0;% MZ plot for focal mechanism Figure 710 and 810
%% Trace Filtering for SP ratio
p.filt(1).type = 'bandpass';
p.filt(1).cut = [3 20];% for ML
p.filt(1).order = 4;
p.filt(1).phase = 'min';

p.filt(2).type = 'bandpass';
p.filt(2).cut = [4 50];
p.filt(2).order = 4;
p.filt(2).phase = 'min';


p.filt(3).type = 'bandpass';
p.filt(3).cut = [3 30];
p.filt(3).order = 4;
p.filt(3).phase = 'min';
% For S/P amp ratio 
p.filt(4).type = 'bandpass';
p.filt(4).cut = [3 20];
p.filt(4).order = 4;
p.filt(4).phase = 'min';
% 
% for get the orignal data
% p.filt(5).type  = 'bandpass';
% p.filt(5).cut   = [];   % ← means no filtering
% p.filt(5).order = [];
% p.filt(5).phase = [];

% % for Sp converted wave
p.filt(5).type = 'bandpass';
p.filt(5).cut = [0 100];
p.filt(5).order = 4;
p.filt(5).phase = 'min';

% %for EC3 east test
% p.filt(6).type = 'bandpass';
% p.filt(6).cut = [2 15];
% p.filt(6).order = 4;
% p.filt(6).phase = 'min';

%for ML Earthquakes P wave is from [1 20]
p.filt(5).type = 'bandpass';
p.filt(5).cut = [1 20];
p.filt(5).order = 4;
p.filt(5).phase = 'min';

%% Trace tiggering (all channels)
% Local earthquakes on 
p.trigger(1).stLen = 0.3;
p.trigger(1).ltLen = 3;  %3
p.trigger(1).ABLen = 0.3; 
p.trigger(1).ltKeep = false;  %% - NOT USED I THINK
p.trigger(1).stltOn = 2; % 2
p.trigger(1).stltOff = 1;
p.trigger(1).iFilt = 1;

%% Associate and Categorize Events
p.event(1).station = {'AXCC1' 'AXEC1' 'AXEC2' 'AXEC3' 'AXAS1' 'AXAS2'  'AXID1'};
p.event(1).iNet = [1:23];    % index of stations/channels in network to use for event association
p.event(1).tlim = [-2 8];
p.event(1).tlen = 1.5;
p.event(1).tgap = 0; 
p.event(1).tslop = 0.5;
p.event(1).ratio = [4 3 2];
p.event(1).nStation = [1 2 3];    
p.event(1).nChannel = [2 2 6];
p.category.station = {'AXCC1' 'AXEC1' 'AXEC2' 'AXEC3' 'AXAS1' 'AXAS2'  'AXID1'};
p.category.iNet = [1:23];
p.category.iFilt = 1;
p.category.tLim1 = [-0.5 1.5];
p.category.fLim = [4 50];
p.category.fLimHigh = [17 25];
p.category.fLimLow = [5 13];
p.category.tLim2 = [-0.3 0.3];

%% Picking
p.pick.station = {'AXCC1' 'AXEC1' 'AXEC2' 'AXEC3' 'AXAS1' 'AXAS2'  'AXID1'};
p.pick.scratchPrevious = true;
p.pick.iTrig = 1;
p.pick.type = 'localquake';
p.pick.minStation = 4;   
p.pick.minRatioABMed = 2.5; % Was 4 but clearly can go at least as low as 3.  Should explore lower
p.pick.tlimEvent = [-1 5]; 
p.pick.iFilt = 1;
p.pick.TtraceSNR = 0.5;   %A value of 0.3 does not seem as good at identifying stationary traces.
p.pick.Pab = [0.15 0.15];
p.pick.Sab = [0.2 0.2];
p.pick.minClipLevelSNR = 7;
p.pick.minPeakSNR=5;
p.pick.minGapEnergyPeak = 0.5;
p.pick.minValleyEnergyPeak = 2;
p.pick.zeroWeightTraceSNR = 2.5;
p.pick.halfWeightTraceSNR = 3.5;
p.pick.maxPminusEventOn = 1;
p.pick.minPdB = 7; 
p.pick.minPdB2 = [5 10];
p.pick.minSdB = 5; 
p.pick.minSdB2 = [4 10]; 
p.pick.deltaWindowOrigin = 0.5;
p.pick.minPSpair = 3;
p.pick.vpvs = 1.7;
p.pick.maxOTerror = [0.3 0.2];    % [0.3 0.15] later
p.pick.minSPgap = 0.25;
p.pick.maxdS = 1.6;
p.pick.maxdP = 0.8;
p.pick.AXECdP = 0.4;
p.pick.AXECdS = 0.6;
p.pick.kurt.iFilt = [1 2];
p.pick.kurt.TLimP = [-0.3 0.2];  % Previously [-1 1]
p.pick.kurt.TLimS = [-0.5 0.5];  % Previously [-0.5 2]
p.pick.kurt.TLimSifP = [-0.15 0.15]; 
p.pick.kurt.minSPforTLimS = 3.333;
p.pick.kurt.ts3 = [41 61 81]/200;
p.pick.kurt.ts4max = 0.05;
p.pick.kurt.tP = 0.1;   %0.2; %Length of P wave used to get S/N 
p.pick.kurt.tS = 0.2;   %0.4; % Length of S wave used to get S/N and for smoothing to get maximum amplitude of record
p.pick.kurt.nkpick = 3;
p.pick.kurt.SbeforeMaxRMS = true;
p.pick.pol.iFilt = 1;
p.pick.pol.alpha = 1.3;
p.pick.pol.npol = 41;
p.pick.pol.Tp = 0.4;
p.pick.pol.Ts = -0.4;
p.pick.tryForMultiple = false;
p.pick.mindTdouble = 1.5;
p.pick.minSdouble = 4;
p.pick.minPdouble = 3;
p.pick.maxRepeatSdOT = 0.5;
p.pick.maxRepeatPdOT = 0.5;

%% Location
p.location.station = {'AXCC1' 'AXEC1' 'AXEC2' 'AXEC3' 'AXAS1' 'AXAS2'  'AXID1'};
p.location.velmodScript = 'axial_velocityScience';
p.location.useTime1 = false;
p.location.weightInconsistent = 0.5;
p.location.tablePdB = [15 10 -inf]; 
p.location.tablePwt = [0.25 0.25 0.5];
p.location.tableSdB = [15 10 -inf]; 
p.location.tableSwt = [0.25 0.25 0.5];
p.location.maxPres = 0.15;
p.location.control.iprloc = 0;
p.location.control.iprlast = 0;
p.location.control.itrlim = 20;
p.location.control.minsta = 4;  % Maybe no effect since is using number of phases and not stations
p.location.control.minphs = 5;
p.location.control.ztrdflt = 1;
p.location.control.rderr = 0.05;
p.location.control.swt = 0.333;         %0.333;
p.location.control.dquit = 0.001;
p.location.control.drqt = 0.0005;
p.location.control.dxfix = 0.5;
p.location.control.dzmax = 1.0;
p.location.control.rmscut = 0.3;
p.location.control.rmsw1 = 1;
p.location.control.rmsw2 = 3;

%% Moments
p.moment.responseMatFile = '/Users/mczhang/Documents/GitHub/Axial-AutoLocate/axial/axial_response2020.mat';
p.moment.tlimEvent = [-4 8];  % Three seconds wider than for picking to allow noise ratios
p.moment.iFilt = 3;   % Filtered data best for moments to avoid big DC and low frequency leakage - March 25 2016
% p.moment.tP = 0.2;
% p.moment.tS = 0.4; % MC you should turn biger, talk with william how much it is
% p.moment.tP = 0.3; %MZ 2022.2.1
% p.moment.tS = 1;
p.moment.tP = [0.2 0.5 1]; % Changed to be range-dependent by MZ 02/06
p.moment.tS = [0.5 1 2]; % Changed to be range-dependent by MZ 02/06
p.moment.fracEdge = 0.25;
% p.moment.Vp = 5;
% p.moment.Vs = 5/1.72;
p.moment.Vp = 5.4429; % MZ 02/10 changed the velocity in 1.5 km
p.moment.Vs = 3.1909; % MZ 02/10 changed the velocity in 1.5 km
p.moment.Qp = 100;
p.moment.Qs = 100; %MZ 2022.2.1
%p.moment.Qs = 50;
p.moment.fLimP = [5 15]; 
p.moment.fLimS = [5 15];
p.moment.rho = 2800;
p.moment.Kp = 1.5;
%p.moment.Ks = 0.7;
p.moment.Ks = 2.0; %MZ 2022.2.1
p.moment.Rp = 0.42;
p.moment.Rs = 0.59;
p.moment.minSWeight = 0.1; 
p.moment.minPWeight = 0.3; 

%% Focal mechanism
%p.focal.tlimEvent=[-1 4];%Plot the event 1s second before and 4 second after to pick polarity
p.focal.tlimEvent=[-3 7];
p.focal.network = 'OO';
p.focal.location = '*';
% p.focal.station = {'D','d','AXCC1', 'u','U', 'D','d'...
%                      'AXEC1', 'u','U', 'D','d'...
%                      'AXEC2','u','U' , 'D','d'...
%                      'AXEC3','u','U' , 'D','d'...
%                      'AXAS1','u','U' , 'D','d'...
%                      'AXAS2', 'u','U', 'D','d'...
%                      'AXID1','u','U'};
p.focal.station = {' ',' ','AXCC1', ' ',' ', ' ',' '...
                     'AXEC1', ' ',' ', ' ',' '...
                     'AXEC2',' ',' ' , ' ',' '...
                     'AXEC3',' ',' ' , ' ',' '...
                     'AXAS1',' ',' ' , ' ',' '...
                     'AXAS2', ' ',' ', ' ',' '...
                     'AXID1',' ',' '};
p.focal.stationID = [0 0 1 0 0 0 0 2 0 0 0 0 3 0 0 0 0 4 0 0 0 0 5 0 0 0 0 6 0 0 0 0 7 0 0];
% p.focal.channel = {'-2','-1','HHZ','1','2', '-2','-1'...
%                      'EHZ', '1','2', '-2','-1'...
%                      'HHZ','1','2', '-2','-1' ...
%                      'EHZ', '1','2', '-2','-1'...
%                      'EHZ','1','2' , '-2','-1'...
%                      'EHZ', '1','2', '-2','-1'...
%                      'EHZ','1','2'};
p.focal.channel = {' ',' ','HHZ',' ',' ', ' ',' '...
                     'EHZ', ' ',' ', ' ',' '...
                     'HHZ',' ',' ', ' ',' ' ...
                     'EHZ', ' ',' ', ' ',' '...
                     'EHZ',' ',' ' , ' ',' '...
                     'EHZ', ' ',' ', ' ',' '...
                     'EHZ',' ',' '};
p.focal.channelID = [0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0];
p.focal.scale     = 10; % this is for zoom in the scale the Z channel.
% Focal mechanism with SP
p.focal_SP.network= 'OO';
p.focal_SP.location = '*';
p.focal_SP.station = {'AXCC1','AXCC1','AXCC1', ...
                     'AXEC1','AXEC1','AXEC1', ...
                     'AXEC2','AXEC2','AXEC2', ...
                     'AXEC3','AXEC3','AXEC3', ...
                     'AXAS1','AXAS1','AXAS1', ...
                     'AXAS2','AXAS2','AXAS2', ...
                     'AXID1','AXID1','AXID1'};
p.focal_SP.stationID = [1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7];
p.focal_SP.channel = {'HHE','HHN','HHZ', ...
                     'EHE','EHN','EHZ', ...
                     'HHE','HHN','HHZ',...
                     'EHE','EHN','EHZ', ...
                     'EHE','EHN','EHZ', ...
                     'EHE','EHN','EHZ', ...
                     'EHE','EHN','EHZ'};
p.focal_SP.channelID = [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3];
p.focal_SP.iFilt= 4;  %plot the forth cloumn which is [3 20] bandpass %MZ added
%p.focal_SP.tlimEvent=[-1 4]; %10 s for determin the s/p ratio
p.focal_SP.tlimEvent=[-3 7];
p.focal_SP.tlimNoise=[-0.7 -0.1]; % Determine the time window of Nosie based on P arrival time. I shorted this after learn Levy.
p.focal_SP.tlimSamp=[-0.1 0.6]; % S amplitude
p.focal_SP.tlimPamp=[-0.05 0.25]; % P amplitude MZ changed for Ploting
%p.focal_SP.tlimPamp=[-0.25 0.25]; % P amplitude for cut
%% Web Parameters
p.web.startDateEvent = datenum('November 16, 2014');
p.web.startDateLocate = datenum('January 22, 2015');  % Timing was fixed sometime on the 1/21/15
p.web.fileHypo71 = '/applications/MAMP/htdocs/hypo71/hypo71.dat';
p.web.filePh2dt = '/applications/MAMP/htdocs/ph2dtInputCatalog/ph2dtInputCatalog.dat';
p.web.fileHypo71Full = '/applications/MAMP/htdocs/hypo71.dat';
p.web.filePh2dtFull = '/applications/MAMP/htdocs/ph2dtInputCatalog.dat';
p.web.filePlotMap1 = '/applications/MAMP/htdocs/mapCaldera/dailyCalderaMap.jpg';
p.web.filePlotMap2 = '/applications/MAMP/htdocs/mapRegional/dailyRegionalMap.jpg';
p.web.fileMap1_1day = '/applications/MAMP/htdocs/MapCaldera1day.jpg';
p.web.fileMap1_7day = '/applications/MAMP/htdocs/MapCaldera7day.jpg';
p.web.fileMap1_30day = '/applications/MAMP/htdocs/MapCaldera30day.jpg';
p.web.fileMap2_1day = '/applications/MAMP/htdocs/MapRegional1day.jpg';
p.web.fileMap2_7day = '/applications/MAMP/htdocs/MapRegional7day.jpg';
p.web.fileMap2_30day = '/applications/MAMP/htdocs/MapRegional30day.jpg';
p.web.fileHistAll1 = '/applications/MAMP/htdocs/histogramAll1.jpg';
p.web.fileHistAll2 = '/applications/MAMP/htdocs/histogramAll2.jpg';
p.web.fileHistAll3 = '/applications/MAMP/htdocs/histogramAll3.jpg';
p.web.fileHistAll4 = '/applications/MAMP/htdocs/histogramAll4.jpg';
p.web.fileHistSpecial1 = '/applications/MAMP/htdocs/histogramEruption2015.jpg';
p.web.fileHistSpecial2 = '/applications/MAMP/htdocs/histogramEruption60day.jpg';
p.web.fileHistSpecial3 = '/applications/MAMP/htdocs/histogramEruption15day.jpg';
p.web.fileHist1year = '/applications/MAMP/htdocs/histogram1Year.jpg';
p.web.fileHist7day = '/applications/MAMP/htdocs/histogram7day.jpg';
p.web.fileHist30day = '/applications/MAMP/htdocs/histogram30day.jpg';
p.web.fileBinCount = '/applications/MAMP/htdocs/binCount.mat';
p.web.fileWeb = '/applications/MAMP/htdocs/index.html';
p.web.fileHypo71Web = '/applications/MAMP/htdocs/hypo71.html';
p.web.filePh2dtWeb = '/applications/MAMP/htdocs/ph2dt.html';
p.web.fileMap1Web = '/applications/MAMP/htdocs/map1.html';
p.web.fileMap2Web = '/applications/MAMP/htdocs/map2.html';
p.web.fileNewPh2dt = '/applications/MAMP/htdocs/felix/newID.dat';
p.web.fileDeleteID = '/applications/MAMP/htdocs/felix/deleteID.dat';
p.web.zmax = 2.5;
