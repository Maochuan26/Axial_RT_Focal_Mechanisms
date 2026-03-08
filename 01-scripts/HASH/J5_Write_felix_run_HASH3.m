% Write amp.dat and Phase.dat
function J5_Write_felix_run_HASH3(filename,path)
fid = fopen(filename,'r');
Nline=nan;
while 1
    tline = fgetl(fid);
    if strcmp(tline,'*');B(id-99)=Nline;break;end
    if strcmp(tline,'#')		% then this is an earthquake line
        if ~isnan(Nline)
            B(id-99)=Nline;
        end
        tline = fgetl(fid);
        Nline=0;
        id=str2num(tline(1:4));
        %if id==199;disp('prepare to pause');pause(5);end
    % elseif strcmp(tline(1:2),'AX') % MZ change for testing new hash
    %     Nline=Nline+1;
    elseif ismember(tline(1), {'A', 'C', 'E', 'I'})
         Nline=Nline+1;
    end
end
fclose(fid);
%% 
phaFile=[path '/phase.dat'];
ampFile=[path,'/amp.dat'];
if exist(phaFile) == 2
    delete(phaFile);
end

if exist(ampFile) == 2
    delete(ampFile);
end

%%
%filename=['Axial_cluster.dat'];
fid = fopen(filename,'r');
fid2=fopen([path '/phase.dat'],'w+');
fid3=fopen([path,'/amp.dat'],'w+');
id=nan;
while 1
    tline = fgetl(fid);
    if strcmp(tline,'*')
        fprintf(fid2,['                                                        ' ...
            '%16s\n'],id);
        break;
    end  % this is the end of the file
    if strcmp(tline,'#')		% then this is an earthquake line
        if ~isnan(id)
            fprintf(fid2,['                                                        ' ...
                '%16s\n'],id);
        end
        tline = fgetl(fid);
        id=tline(1:4);
        %if strcmp(tline(1:3),num2stop); break; end
        Amp_num=B(str2num(id)-99);
        fprintf(fid3,'%d     %d\n',str2num(id), Amp_num);
        t= datetime(str2num(tline(7:20)),'ConvertFrom','datenum');
        yr=year(t);mo=month(t);da=day(t);hr=hour(t);mn=minute(t);sec=second(t);
        ilat = floor(abs(str2num(tline(36:42))));
        mlat = 60*(abs(str2num(tline(36:42))) - ilat);
        cns = 'N'; %if sign(location.lat)==-1; cns='S'; end;
        ilon = floor(abs(str2num(tline(24:32))));
        mlon = 60*(abs(str2num(tline(24:32))) - ilon);
        cew = 'W'; %if sign(location.lon)==-1; cew='W'; end;
        dep = str2num(tline(46:49));
        eh = 0.2;
        ez = 0.3;
        % eh = 0.4;
        % ez = 0.6;
        mag = 1;
        fprintf(fid2,...
            '%4i%2i%2i%2i%2i%5.2f%2i%c%5.2f%3i%c%5.2f%5.2f %5.2f %5.2f %4.2f%16s\n',...
            yr,mo,da,hr,mn,sec,ilat,cns,mlat,ilon,cew,mlon,dep,eh,ez,mag,id);
    elseif ismember(tline(1), {'A', 'C', 'E', 'I'})
        sta=tline(1:3);
        staReal=tline(1:4);
        if strcmp(sta,'CC1')
            schan = 'HHZ';
        elseif strcmp(sta,'EC2')
            schan = 'HHZ';
        else
            schan = 'EHZ';
        end
        cpol=tline(7);
        oneset = 'I';
        fprintf(fid2,'%4s %2s  %3s %c %c\n',staReal, ...
            'OO',schan,oneset,cpol);
        Noise=str2num(tline(14:24));
        Pamp=str2num(tline(28:40));
        Samp=str2num(tline(44:56));
        fprintf(fid3,'%4s %3s %2s                 %10.3f %10.3f %10.3f %10.3f\n',staReal,schan,'OO',Noise,Noise,Pamp,Samp);
    end
end
fclose(fid);
fclose(fid2);
fclose(fid3);

cd /Users/mczhang/Documents/GitHub/FM/01-scripts/HASH_Manual_5test/
!./hash_driver3 < hash.input 
end