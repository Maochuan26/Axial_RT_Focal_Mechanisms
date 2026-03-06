function [event] = read_hd3_output1(filename);
%function [event] = read_hd3_output1(filename);
%
% read_output1 reads the output1 file from HASH driver 3
%
% INPUT:
%           filename         File name for the output1 file from HASH
%
% OUTPUT:
%           Data stored in event structure
%           event.id      (1x1)        	Earthquake id is "evid_orid "    
%           event.lat     (1x1)        	Earthquake latitude    
%           event.lon     (1x1)        	Earthquake longitude    
%           event.depth   (1x1)        	Earthquake depth   
%           event.time   (1x1)        	Earthquake epoch time   
%           event.nmult   (1x1)         Number (N) of alternate distinctly different solutions
%           event.avmech (Nx3)     	    Most probable mechanism (strike,dip, rake)
%           event.avfnorm (Nx3)         Most probable fault normal vector
%           event.avslip (Nx3)     	    Most probable slip vector 
%           event.avfnorm_uncert (Nx1)  Uncertainty fault normal vector
%           event.avslip_uncert (Nx1)  Uncertainty slip vector 
%           event.polnum                # P first motion polarities
%           event.polmisfit (Nx1)        % misfit of first motions
%           event.mechqual              focal mechanism quality
%           event.mechprob (Nx1)       probability mechanism close solution
%           event.stdr     (Nx1)       station distribution ratio
%           event.namp                 # of log10(S/P) observations`
%           event.mavg     (Nx1)       mean absolute misfit of polarity observations
%           event.max_azimgap           maximum azimuthal gap
%           event.max_takeoff            maximum take-off angle gap for first motions
%   COORDINATE SYSTEM for the output is x=E, y=N, z=Up.

fid = fopen(filename,'r');

icnt = 0;   % Earthquakes
while 1
    tline = fgetl(fid);
    if ~ischar(tline); break; end;  % this is the end of the file
        icnt = icnt+1;

%      do i=1,nmult
%      write (13,411) icusp,iyr,imon,idy,ihr,imn,qsec,evtype,
%     &   qmag,magtype,qlat,qlon,qdep,locqual,rms,seh,sez,terr,
%     &   nppick+nspick,nppick,nspick,
%     &   nint(str_avg(i)),nint(dip_avg(i)),nint(rak_avg(i)),
%     &   nint(var_est(1,i)),nint(var_est(2,i)),nppl,nint(mfrac(i)*100.),
%     &   qual(i),nint(100*prob(i)),nint(100*stdr(i)),nspr,
%     &   nint(mavg(i)*100.),nmult,magap,mpgap
%      end do
%411   format(i16,1x,i4,1x,i2,1x,i2,1x,i2,1x,i2,1x,f6.3,1x,a1,1x,
%     &  f5.3,1x,a1,1x,f9.5,1x,f10.5,1x,f7.3,1x,a1,1x,f7.3,1x,f7.3,
%     &  1x,f7.3,1x,f7.3,3x,i4,1x,i4,1x,i4,1x,i4,1x,i3,1x,i4,3x,i2,
%     &  1x,i2,1x,i3,1x,i2,1x,a1,1x,i3,1x,i2,1x,i3,1x,i3,1x,a1,1x,
%     &  i3,1x,i2)
 
    event(icnt).id             = sscanf(tline,'%i',[1]);
    yr = sscanf(tline,'%*s %i',[1]);
    mo = sscanf(tline,'%*s %*i %i',[1]);
    da = sscanf(tline,'%*s %*i %*i %i',[1]);
    hr = sscanf(tline,'%*s %*i %*i %*i %i',[1]);
    mn = sscanf(tline,'%*s %*i %*i %*i %*i %i',[1]);
    sec = sscanf(tline,'%*s %*i %*i %*i %*i %*i %f',[1]);
    %jda = julday(mo,da,yr);%MZ 0224
    event(icnt).time           = datenum(yr,mo,da,hr,mn,sec);
    event(icnt).lat            = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %f',[1]);
    event(icnt).lon            = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %f',[1]);
    event(icnt).depth          = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %f',[1]);
    event(icnt).avmech(1,:)    = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %i %i %i',[3]);
    event(icnt).avfnorm_uncert = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %i',[1]);
    event(icnt).avslip_uncert  = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %i',[1]);
    event(icnt).polnum         = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %i',[1]);
    event(icnt).polmisfit      = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %i',[1]);
    event(icnt).mechqual       = setstr(sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %s',[1]));
    event(icnt).mechprob       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %i',[1]);
    event(icnt).stdr       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %*i %i',[1]);
    event(icnt).namp       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %*i %*i %i',[1]);
    event(icnt).mavg       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %*i %*i %*i %i',[1]);
    event(icnt).nmult       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %*i %*i %*i %*i %i',[1]);
    event(icnt).max_azimgap       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %*i %*i %*i %*i %*i %i',[1]);
    event(icnt).max_takeoff       = sscanf(tline,'%*s %*i %*i %*i %*i %*i %*f %*s %*f %*s %*f %*f %*f %*s %*f %*f %*f %*f %*i %*i %*i %*i %*i %*i %*i %*i %*i %*i %*s %*i %*i %*i %*i %*i %*i %i',[1]);

   % Change coordinate systems
    if event(icnt).avmech(:,1) == 999,
        event(icnt).avfnorm = [];  event(icnt).avslip = [];
    else
        [event(icnt).avfnorm,event(icnt).avslip] =...
       fp2fnorm(event(icnt).avmech(:,1),event(icnt).avmech(:,2),event(icnt).avmech(:,3));
    end
end

% Consolidate multiple solutions into single entry
ncnt = icnt;
icnt=1;
while icnt<=ncnt
  if event(icnt).nmult==1
    icnt = icnt+1;
  else
    for j=1:event(icnt).nmult-1;
      event(icnt).avfnorm = [event(icnt).avfnorm; event(icnt+j).avfnorm];
      event(icnt).avslip = [event(icnt).avslip; event(icnt+j).avslip];
      event(icnt).avmech = [event(icnt).avmech; event(icnt+j).avmech];
      event(icnt).avfnorm_uncert = [event(icnt).avfnorm_uncert;  event(icnt+j).avfnorm_uncert ];
      event(icnt).avslip_uncert  = [event(icnt).avslip_uncert;  event(icnt+j).avslip_uncert ];
      event(icnt).polmisfit = [event(icnt).polmisfit; event(icnt+j).polmisfit];
      event(icnt).mechprob = [event(icnt).mechprob; event(icnt+j).mechprob];
      event(icnt).stdr = [event(icnt).stdr; event(icnt+j).stdr];
      event(icnt).mavg = [event(icnt).mavg; event(icnt+j).mavg];
    end
    event = [event(1:icnt) event(icnt+event(icnt).nmult:end)];
    ncnt = ncnt - event(icnt).nmult + 1;
    icnt = icnt+1;
  end
end
      
    
fclose(fid);

