%% J_UpdateFMWebsite.m
% Rewrites Focal Mechanisms.html with the current summary images and a
% full dated archive of every pipeline run.  Call after I_Plot_FM.m.

htdocs  = '/Applications/MAMP/htdocs';
fmDir   = fullfile(htdocs, 'focalmechanismsdaily');
outFile = fullfile(htdocs, 'Focal Mechanisms.html');

%% Collect run dates from archived 1-day images (newest first)
files = dir(fullfile(fmDir, 'FM1day_????????.jpg'));
[~, idx] = sort({files.name});
idx = fliplr(idx);
files = files(idx);

runDates = {};
for i = 1:length(files)
    tok = regexp(files(i).name, 'FM1day_(\d{8})\.jpg', 'tokens');
    if ~isempty(tok)
        runDates{end+1} = tok{1}{1}; %#ok<AGROW>
    end
end

%% Write HTML
fid = fopen(outFile, 'wt');

fprintf(fid, '<!DOCTYPE html>\n<html>\n<head>\n');
fprintf(fid, '<title>Axial Seamount Focal Mechanisms</title>\n');
fprintf(fid, '</head>\n<body>\n\n');

fprintf(fid, '<h2>Axial Seamount Focal Mechanisms</h2>\n');
fprintf(fid, '<p>by\n');
fprintf(fid, '<a href="https://www.ocean.washington.edu/home/Maochuan_Zhang">Maochuan Zhang</a>\n');
fprintf(fid, '</p>\n\n');

fprintf(fid, ['<p>This page provides near-real-time focal mechanism estimates for earthquakes at ' ...
    'Axial Seamount recorded by the Ocean Observatories Initiative (OOI) cabled array. ' ...
    'For each recent event, the pipeline identifies the 6 most similar historical earthquakes ' ...
    'from a base catalog of events with known focal mechanisms. Similarity is measured using a ' ...
    'composite distance combining hypocenter location, P-wave first-motion polarities predicted ' ...
    'by a deep learning model, and S/P amplitude ratios across seven OOI broadband stations ' ...
    '(AS1, AS2, CC1, EC1, EC2, EC3, ID1). Focal mechanisms are inferred by analogy from the ' ...
    'matched historical events using the HASH algorithm. Color coding: ' ...
    'blue&nbsp;=&nbsp;Normal, red&nbsp;=&nbsp;Reverse, green&nbsp;=&nbsp;Strike-slip, ' ...
    'black&nbsp;=&nbsp;Unclassified.\n</p>\n\n']);

fprintf(fid, '<p>Maps are updated each pipeline run (approximately daily). Last updated: %s UTC\n</p>\n\n', ...
    datestr(datetime('now','TimeZone','UTC'), 'dd-mmm-yyyy HH:MM:SS'));

%% Contents
fprintf(fid, '<h3>Contents</h3>\n\n');
fprintf(fid, '<a href="#name1">Recent Focal Mechanism Maps</a>\n<br>\n');
fprintf(fid, '<a href="#name2">Daily Focal Mechanism Archive</a>\n<br>\n');
fprintf(fid, '<a href="#name3">Histograms of Recent Activity</a>\n<br>\n');
fprintf(fid, '<a href="#name4">Histograms of 2015 Eruption</a>\n<br>\n');
fprintf(fid, '<a href="#name5">Histograms of Full Catalog</a>\n<br>\n');
fprintf(fid, '<a href="#name6">Daily Catalogs and Maps</a>\n<br>\n');
fprintf(fid, '<a href="#name7">Full Catalog</a>\n<br>\n\n');

%% Recent maps
fprintf(fid, '<a name="name1"></a>\n');
fprintf(fid, '<h3>Recent Focal Mechanism Maps</h3>\n\n');
fprintf(fid, '<a href="FocalMechanism1day.jpg"><img src="FocalMechanism1day.jpg" alt="Past 24 hours" width="300"/></a>\n');
fprintf(fid, '<a href="FocalMechanism7day.jpg"><img src="FocalMechanism7day.jpg" alt="Past 7 days" width="300"/></a>\n');
fprintf(fid, '<a href="FocalMechanism30day.jpg"><img src="FocalMechanism30day.jpg" alt="Past 30 days" width="300"/></a>\n');
fprintf(fid, '<br>\n');
fprintf(fid, '<p>Left: past 24 hours &nbsp;&nbsp; Center: past 7 days &nbsp;&nbsp; Right: past 30 days</p>\n\n');

%% Daily archive
fprintf(fid, '<a name="name2"></a>\n');
fprintf(fid, '<h3>Daily Focal Mechanism Archive</h3>\n\n');

for i = 1:length(runDates)
    d = runDates{i};
    dispDate = [d(1:4) '-' d(5:6) '-' d(7:8)];
    fprintf(fid, '%s &mdash; ', dispDate);
    fprintf(fid, '<a href="focalmechanismsdaily/FM1day_%s.jpg">24 h</a> | ', d);
    fprintf(fid, '<a href="focalmechanismsdaily/FM7day_%s.jpg">7 days</a> | ', d);
    fprintf(fid, '<a href="focalmechanismsdaily/FM30day_%s.jpg">30 days</a>', d);
    fprintf(fid, '<br>\n');
end

%% Histograms of Recent Activity
fprintf(fid, '<a name="name3"></a>\n');
fprintf(fid, '<h3>Histograms of Recent Activity</h3>\n\n');
fprintf(fid, '<a href="histogram7day.jpg"><img src="histogram7day.jpg" alt="7 day" width="300"/></a>\n');
fprintf(fid, '<a href="histogram30day.jpg"><img src="histogram30day.jpg" alt="30 day" width="300"/></a>\n');
fprintf(fid, '<a href="histogram1Year.jpg"><img src="histogram1Year.jpg" alt="1 Year" width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Histograms of 2015 Eruption
fprintf(fid, '<a name="name4"></a>\n');
fprintf(fid, '<h3>Histograms of 2015 Eruption</h3>\n\n');
fprintf(fid, '<a href="histogramEruption2015.jpg"><img src="histogramEruption2015.jpg" alt="2015 Eruption" width="300"/></a>\n');
fprintf(fid, '<a href="histogramEruption60day.jpg"><img src="histogramEruption60day.jpg" alt="Eruption 60 day" width="300"/></a>\n');
fprintf(fid, '<a href="histogramEruption15day.jpg"><img src="histogramEruption15day.jpg" alt="Eruption 15 day" width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Histograms of Full Catalog
fprintf(fid, '<a name="name5"></a>\n');
fprintf(fid, '<h3>Histograms of Full Catalog</h3>\n\n');
fprintf(fid, '<a href="histogramAll1.jpg"><img src="histogramAll1.jpg" alt="Full Catalog 1" width="300"/></a>\n');
fprintf(fid, '<a href="histogramAll2.jpg"><img src="histogramAll2.jpg" alt="Full Catalog 2" width="300"/></a>\n');
fprintf(fid, '<br>\n');
fprintf(fid, '<a href="histogramAll3.jpg"><img src="histogramAll3.jpg" alt="Full Catalog 3" width="300"/></a>\n');
fprintf(fid, '<a href="histogramAll4.jpg"><img src="histogramAll4.jpg" alt="Full Catalog 4" width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Daily Catalogs and Maps
fprintf(fid, '<a name="name6"></a>\n');
fprintf(fid, '<h3>Daily Catalogs and Maps</h3>\n\n');
fprintf(fid, '<p>Caldera Maps &nbsp; <a href="map1.html">map1.html</a></p>\n');
fprintf(fid, '<p>Regional Maps &nbsp; <a href="map2.html">map2.html</a></p>\n');
fprintf(fid, '<p>Daily HYPO71 files &nbsp; <a href="hypo71.html">hypo71.html</a></p>\n');
fprintf(fid, '<p>Daily ph2dt input files &nbsp; <a href="ph2dt.html">ph2dt.html</a></p>\n\n');

%% Full Catalog
fprintf(fid, '<a name="name7"></a>\n');
fprintf(fid, '<h3>Full Catalog (Big Files)</h3>\n\n');
fprintf(fid, '<p>HYPO71 style catalog &mdash; <a href="hypo71.dat">hypo71.dat</a></p>\n');
fprintf(fid, '<p>Arrival time data in form of input catalog for ph2dt algorithm of HYPODD &mdash; <a href="ph2dtInputCatalog.dat">ph2dtInputCatalog.dat</a></p>\n\n');

fprintf(fid, '\n</body>\n</html>\n');
fclose(fid);
fprintf('Focal Mechanisms.html updated (%d archive entries).\n', length(runDates));
