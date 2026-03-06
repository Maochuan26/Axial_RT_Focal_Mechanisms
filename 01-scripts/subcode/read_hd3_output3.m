function [event] = read_hd3_output3(filename);
%function [event] = read_hd3_output3(filename);
%
% read_output1 reads the output1 file from HASH driver 3
%
% INPUT:
%           filename         File name for the output1 file from HASH
%
% OUTPUT:
%           Data stored in event structure
%           event.id      (1x1)        	Earthquake id is "evid_orid "    
%           event.nmult   (1x1)         Number (N) of alternate distinctly different solutions
%           event.npol                  Total number of observations
%           event.nppl                  number of polarity observations
%           event.nspr                  number of amplitude observations
%           event.nsta                  Number of stations with at least 1 observation
%           event.staid                 Station IDs
%           event.sta                   Station name in structure
%           event.azi                   Azimuths
%           event.takeoff               Takeoff angle
%           event.pol                   Polarity observations
%           event.qpol                  Polarity observation quality (0 = impulsive; 1 = emergent);
%           event.polpred               Polarity predictions
%           event.s2p                   S/P ratios
%           event.s2ppred               S/P ratio predictions

fid = fopen(filename,'r');

icnt = 0;   % Earthquakes
while 1
    tline = fgetl(fid);
    if ~ischar(tline); break; end;  % this is the end of the file
        icnt = icnt+1;

    event(icnt).id            = sscanf(tline,'%i',[1]);
    event(icnt).npol         = sscanf(tline,'%*s %i',[1]);
    event(icnt).nppl          = sscanf(tline,'%*s %*i %i',[1]);
    event(icnt).nspr          = sscanf(tline,'%*s %*i %*i %i',[1]);
    event(icnt).nmult          = sscanf(tline,'%*s %*i %*i %*i %i',[1]);
    for imult = 1:event(icnt).nmult
      for i=1:event(icnt).npol
        tline = fgetl(fid);
        sta = sscanf(tline,'%4s',[1]);
        event(icnt).staid(i) = get_stationid(sta);
        event(icnt).sta{i} = sta;
        event(icnt).azi(i) = sscanf(tline,'%*s %f',[1]);
        event(icnt).takeoff(i) = 180-sscanf(tline,'%*s %*f %f',[1]);
% Convert from relative to vertical up to relative to vertical down
%         event(icnt).qpol(i) = sscanf(tline,'%*s %*f %*f %i',[1]);
%         event(icnt).pol(i) = sscanf(tline,'%*s %*f %*f %*i %i',[1]);
%         event(icnt).polpred(imult,i) = sscanf(tline,'%*s %*f %*f %*i %*i %i',[1]);
%         event(icnt).s2p(i) = sscanf(tline,'%*s %*f %*f %*i %*i %*i %f',[1]);
%         event(icnt).s2ppred(imult,i) = sscanf(tline,'%*s %*f %*f %*i %*i %*i %*f %f',[1]);
      % MZ changed        
        event(icnt).qpol(i) = sscanf(tline,'%*s %*f %*f %i',[1]);
        event(icnt).pol(i) =  sscanf(tline,'%*s %*f %*f %i',[1]);
        event(icnt).polpred(imult,i) = sscanf(tline,'%*s %*f %*f %*i %i',[1]);
        event(icnt).s2p(i) = sscanf(tline,'%*s %*f %*f %*i %*i %i',[1]);
        event(icnt).s2ppred(imult,i) = sscanf(tline,'%*s %*f %*f %*i %*i %*i %f',[1]);
     
      end
    end
    % Merge lines with polarity and S/P data for the same station
    nsta = event(icnt).npol;
    ista = 1;
    while ista<nsta
      index = ista+find(event(icnt).staid(ista+1:end)==event(icnt).staid(ista));
      if length(index)>1
        error('Weird data');
      elseif length(index)==1
        if event(icnt).pol(ista)
          event(icnt).s2p(ista) = event(icnt).s2p(index);
          event(icnt).s2ppred(:,ista) = event(icnt).s2ppred(:,index);
        else
          event(icnt).pol(ista) = event(icnt).pol(index);
          event(icnt).qpol(ista) = event(icnt).qpol(index);
          event(icnt).polpred(:,ista) = event(icnt).polpred(:,index);
        end
        ikeep = [1:index-1 index+1:nsta];
        event(icnt).staid = event(icnt).staid(ikeep);
        event(icnt).sta = event(icnt).sta(ikeep);
        event(icnt).azi = event(icnt).azi(ikeep);
        event(icnt).takeoff = event(icnt).takeoff(ikeep);
        event(icnt).pol = event(icnt).pol(ikeep);
        event(icnt).qpol = event(icnt).qpol(ikeep);
        event(icnt).polpred = event(icnt).polpred(:,ikeep);
        event(icnt).s2p = event(icnt).s2p(ikeep);
        event(icnt).s2ppred = event(icnt).s2ppred(:,ikeep);
        nsta = nsta-1;
      end
      ista = ista+1;
    end
    event(icnt).nsta = nsta;
end
fclose(fid);

