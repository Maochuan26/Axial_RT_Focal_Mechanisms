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
fprintf(fid, '<a href="#name2">Daily Focal Mechanism Archive</a>\n<br>\n\n');

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

fprintf(fid, '\n</body>\n</html>\n');
fclose(fid);
fprintf('Focal Mechanisms.html updated (%d archive entries).\n', length(runDates));
