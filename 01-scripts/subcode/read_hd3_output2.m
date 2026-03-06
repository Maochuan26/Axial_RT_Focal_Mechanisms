function [event] = read_hd3_output2(filename);
% function [event] = read_hd3_output2(filename);
%
% read_output2 reads the output2 file from HASH driver 3 (version 1.1)
%
% INPUT:
%           filename         File name for the output2 file from HASH
%  COORDINATE SYSTEM for the input is (x,y,z) with x=north, y=east, z=down
%
% OUTPUT:
%           Data stored in event structure
%           event.id      (1x1)        	Earthquake id is "evid_orid "
%           event.avfnorm (1x3)     	Most probable mechanism fault normal vector
%           event.avslip  (1x3)     	Most probable mechanism slip vector
%           event.mechall  (nmec x 3)   Strike, dip, rake for every acceptable mechanism
%           event.fnorm1  (nmec x 3)    Fault normal vector for every acceptable mechanism
%           event fnorm2   (nmec x 3)   Slip vector for every acceptable mechanism
%           event.fnormall  (nmec x 3)  Fault normal vector for every acceptable mechanism - from mechall  - CHECK ON FNORM1
%           event slipall  (nmec x 3)   Slip vector for every acceptable mechanism - from mechall          - CHECK ON FNORM2
%   COORDINATE SYSTEM for the output is x=E, y=N, z=Up.

fid = fopen(filename,'r');

icnt = 0;   % Earthquakes
jcnt = 0;   % Number of mechanisms for that earthquake
while 1
    tline = fgetl(fid);
    if ~ischar(tline); break; end;
    if strcmp(tline(1:2),'20')		% then this is an earthquake line
        icnt = icnt+1;
        %disp(['Reading output2 event count = ' int2str(icnt)]);
        jcnt = 0;
    	%      write (11,412) iyr,imon,idy,ihr,imn,qsec,qmag,
    	%     &   qlat,qlon,qdep,sez,seh,npol,nout2,icusp,
    	%     &   str_avg,dip_avg,rak_avg,var_est(1),var_est(2),
    	%     &   mfrac,qual,prob,stdr
    	%412   format (i4,1x,i2,1x,i2,1x,i2,1x,i2,1x,f6.3,2x,f3.1,1x,f9.4,1x,
    	%     &   f10.4,1x,f6.2,1x,f8.4,1x,f8.4,1x,i5,1x,i5,1x,a16,1x,f7.1,1x,
    	%     &   f6.1,1x,f7.1,1x,f6.1,1x,f6.1,1x,f7.3,2x,a1,1x,f7.3,1x,f4.2)
        %        event(icnt).id = sscanf(tline,'%*4i %*2i %*2i %*2i %*2i %*6f  %*3f %*9f %*10f %*6f %*8f %*8f %*5i %*5i %i',[1]);
        event(icnt).id = sscanf(tline,'%*i %*i %*i %*i %*i %*f  %*f %*f %*f %*f %*f %*f %*i %*i %i',[1]);
        %         event(icnt).id = setstr(event(icnt).id)';
        event(icnt).avmech(1,:) = sscanf(tline,'%*i %*i %*i %*i %*i %*f  %*f %*f %*f %*f %*f %*f %*i %*i %*s %f %f %f',[3]);
    else				% this is a mechanism line
        jcnt = jcnt + 1;
    	% write (11,550) strike2(ic),dip2(ic),rake2(ic),f1norm(1,ic),
    	%     &      f1norm(2,ic),f1norm(3,ic),f2norm(1,ic),f2norm(2,ic),
    	%     &      f2norm(3,ic)
    	%550   format (5x,3f9.2,6f9.4)
        event(icnt).mechall(jcnt,:) = sscanf(tline,'%f %f %f',[3]);
        [event(icnt).fnormall(jcnt,:),event(icnt).slipall(jcnt,:)] = ...
            fp2fnorm(event(icnt).mechall(jcnt,1),event(icnt).mechall(jcnt,2),event(icnt).mechall(jcnt,3));
        event(icnt).fnorm1(jcnt,:) = sscanf(tline,'%*f %*f %*f %f %f %f',[3]);
        event(icnt).fnorm2(jcnt,:) = sscanf(tline,'%*f %*f %*f %*f %*f %*f %f %f %f',[3]);
        % Convert x=north, y=east, z=down TO x=E, y=N, z=Up.
        event(icnt).fnorm1(jcnt,:) = ned2enu(event(icnt).fnorm1(jcnt,:));
        event(icnt).fnorm2(jcnt,:) = ned2enu(event(icnt).fnorm2(jcnt,:));
    end
    % Change coordinate system for most probable mechanism
    if event(icnt).avmech(:,1) == 999,
        event(icnt).avfnorm = [];  event(icnt).avslip = [];
    else
        [event(icnt).avfnorm,event(icnt).avslip] =...
            fp2fnorm(event(icnt).avmech(:,1),event(icnt).avmech(:,2),event(icnt).avmech(:,3));
    end
end
fclose(fid);

for i =1:icnt,
    if isempty(event(icnt).mechall),
        event(i).avfnormall=[]; event(i).avslipall=[];
    else
        test=mean(event(i).mechall);
        if ~isnan(test) % MZ 0224
            [event(i).avfnormall,event(i).avslipall] = fp2fnorm(test(1),test(2),test(3));
        end
    end
end
