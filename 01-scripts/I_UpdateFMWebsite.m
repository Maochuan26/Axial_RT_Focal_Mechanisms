%% I_UpdateFMWebsite.m
% Rewrites Focal Mechanisms.html with the current summary images.
% Call after H_Plot_FM.m.

if ~exist('cfg','var'); run('config.m'); end
htdocs  = cfg.htdocs;
outFile = fullfile(htdocs, 'Focal Mechanisms.html');

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
fprintf(fid, '<a href="#name3">Accumulated Focal Mechanisms Monitoring of Shallow East</a>\n<br>\n');
fprintf(fid, '<a href="#name4">Focal Mechanisms: 2015 Eruption</a>\n<br>\n');
fprintf(fid, '<a href="#name5">Full FM Catalog 2015&#8211;2021</a>\n<br>\n');
fprintf(fid, '<a href="#name_monthly">Monthly FM Catalogs and Maps</a>\n<br>\n');
fprintf(fid, '<a href="#name6">Daily FM Catalogs and Maps</a>\n<br>\n');
fprintf(fid, '<a href="#name7">Full FM Catalog</a>\n<br>\n\n');

%% Recent maps
fprintf(fid, '<a name="name1"></a>\n');
fprintf(fid, '<h3>Recent Focal Mechanism Maps</h3>\n\n');
fprintf(fid, '<a href="FocalMechanism1day.jpg"><img src="FocalMechanism1day.jpg" alt="Past 24 hours" width="300"/></a>\n');
fprintf(fid, '<a href="FocalMechanism7day.jpg"><img src="FocalMechanism7day.jpg" alt="Past 7 days" width="300"/></a>\n');
fprintf(fid, '<a href="FocalMechanism30day.jpg"><img src="FocalMechanism30day.jpg" alt="Past 30 days" width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Accumulated FM plots for Shallow East
fprintf(fid, '<a name="name3"></a>\n');
fprintf(fid, '<h3>Accumulated Focal Mechanisms Monitoring of Shallow East</h3>\n\n');
fprintf(fid, '<a href="accumFM7day.jpg"><img src="accumFM7day.jpg" alt="Past 7 days" width="300"/></a>\n');
fprintf(fid, '<a href="accumFM30day.jpg"><img src="accumFM30day.jpg" alt="Past 30 days" width="300"/></a>\n');
fprintf(fid, '<a href="accumFM1year.jpg"><img src="accumFM1year.jpg" alt="Past 1 Year" width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Focal Mechanisms: 2015 Eruption
fprintf(fid, '<a name="name4"></a>\n');
fprintf(fid, '<h3>Focal Mechanisms: 2015 Eruption</h3>\n\n');
fprintf(fid, '<a href="EruptionFM_Before.jpg"><img src="EruptionFM_Before.jpg" alt="Before 2015 Eruption" width="300"/></a>\n');
fprintf(fid, '<a href="EruptionFM_During.jpg"><img src="EruptionFM_During.jpg" alt="During 2015 Eruption" width="300"/></a>\n');
fprintf(fid, '<a href="EruptionFM_After.jpg"><img src="EruptionFM_After.jpg"  alt="After 2015 Eruption"  width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Full FM Catalog 2015-2021
fprintf(fid, '<a name="name5"></a>\n');
fprintf(fid, '<h3>Full FM Catalog 2015&#8211;2021</h3>\n\n');
fprintf(fid, '<a href="fmCatalogAll1.jpg"><img src="fmCatalogAll1.jpg" alt="Full Catalog 1" width="300"/></a>\n');
fprintf(fid, '<a href="fmCatalogAll2.jpg"><img src="fmCatalogAll2.jpg" alt="Full Catalog 2" width="300"/></a>\n');
fprintf(fid, '<br>\n');
fprintf(fid, '<a href="fmCatalogAll3.jpg"><img src="fmCatalogAll3.jpg" alt="Full Catalog 3" width="300"/></a>\n');
fprintf(fid, '<a href="fmCatalogAll4.jpg"><img src="fmCatalogAll4.jpg" alt="Full Catalog 4" width="300"/></a>\n');
fprintf(fid, '<br>\n\n');

%% Monthly FM Catalogs and Maps
fprintf(fid, '<a name="name_monthly"></a>\n');
fprintf(fid, '<h3>Monthly FM Catalogs and Maps</h3>\n\n');
fprintf(fid, '<p>Beach ball size scaled by earthquake magnitude.</p>\n');
% Show thumbnail of most recent monthly map if it exists
monthlyDir   = fullfile(htdocs, 'monthlyFMmap');
monthlyFiles = dir(fullfile(monthlyDir, 'monthlyFMmap_*.jpg'));
if ~isempty(monthlyFiles)
    [~, si]     = sort({monthlyFiles.name}, 'descend');
    recentFile  = monthlyFiles(si(1)).name;
    tok = regexp(recentFile, 'monthlyFMmap_(\d{6})\.jpg', 'tokens');
    if ~isempty(tok)
        ym      = tok{1}{1};
        dispStr = datestr(datenum(str2double(ym(1:4)), str2double(ym(5:6)), 1), 'mmm yyyy');
        fprintf(fid, '<p>Most recent monthly map: <strong>%s</strong></p>\n', dispStr);
        fprintf(fid, '<a href="monthlyFMmap/%s"><img src="monthlyFMmap/%s" alt="Latest Monthly FM Map" width="300"/></a>\n', ...
            recentFile, recentFile);
        fprintf(fid, '<br>\n');
    end
end
fprintf(fid, '<p>All monthly maps &nbsp; <a href="monthlyFMmap.html">monthlyFMmap.html</a></p>\n\n');

%% Daily Catalogs and Maps
fprintf(fid, '<a name="name6"></a>\n');
fprintf(fid, '<h3>Daily FM Catalogs and Maps</h3>\n\n');
fprintf(fid, '<p>Caldera Focal Mechanisms &nbsp; <a href="FMmap.html">FMmap.html</a></p>\n');
fprintf(fid, '<p>Daily hypo71_FM files &nbsp; <a href="hypo71_FM.html">hypo71_FM.html</a></p>\n');
fprintf(fid, '<p>Daily ph2dt_po input files &nbsp; <a href="ph2dt.html">ph2dt.html</a></p>\n\n');

%% Full Catalog
fprintf(fid, '<a name="name7"></a>\n');
fprintf(fid, '<h3>Full FM Catalog (Big Files)</h3>\n\n');
fprintf(fid, '<p>HYPO71 style catalog &mdash; <a href="hypo71.dat">hypo71.dat</a></p>\n');
fprintf(fid, '<p>Arrival time data in form of input catalog for ph2dt algorithm of HYPODD &mdash; <a href="ph2dtInputCatalog.dat">ph2dtInputCatalog.dat</a></p>\n\n');

fprintf(fid, '\n</body>\n</html>\n');
fclose(fid);
fprintf('Focal Mechanisms.html updated.\n');
