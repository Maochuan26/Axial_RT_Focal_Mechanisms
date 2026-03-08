% Plot  acceptable focal mechansism for each event analyzed by HASH driver 3 (ver 1.1) - based on EEEH, JP code
% also plot the first motion polarity observations
% A new figure is generated for each event
% USES fp2fnorm, read_hd3_output1, read_hd3_output2, read_hd3_output3,
%      plot_focal_base1,  plot_focal_plane, plot_filled_mech
% Updated 9/25/07 by W. Wilcock for driver 3 (amplitudes)
clc;clear;close all;
pdf_file = ['/Users/mczhang/Documents/GitHub/FM3/03-output-graphics/G_diff_SP_PO.pdf'];
if exist(pdf_file, 'file') == 2
    delete(pdf_file);
end
radius = 1;
scale = 1;
sizefac = 0.03;      % negative means no labels
old_fig = 0;
% Define the ranges
range1 = 0:0.05:0.5;
range2 = 0:0.1:0.9;
 k=1;
% Iterate over all combinations of range1 and range2 values
for i1 = 1:length(range1)
    for j1 = 1:length(range2)
        clear event*
        filename=sprintf('G_FM_%d_%d.mat', range1(i1)*100, range2(j1)*10);
       
        load(filename);
        nevent = min(length(event1));
        for i=1:nevent,
            fig = floor((k-1)/4)+1;
            if fig ~= old_fig,
                    exportgraphics(gcf, pdf_file, 'Append', true);
                figure(fig),
                 
                set(fig,'defaulttextfontsize',10);
                set(fig,'units','inches','pos',[1 1 8.5 11])
                old_fig = fig;
                rest = 1;
                clf;
            end
            nmec = length(event2(i).fnorm1);
            subplot(4,2,rest), hold on
            rest = rest+1;
            for j = 1:100,
                h1 = plot_focal_plane([event2(i).fnorm1(j,:)],'-');
                h2 = plot_focal_plane([event2(i).fnorm2(j,:)],'-');
            end
            color = setstr(ones(event3(i).nsta,1)*114 + event3(i).qpol(:)*7);
            plot_focal_base1(event3(i).azi,event3(i).takeoff,event3(i).pol,cell2mat(event3(i).sta'),sizefac,[],color);
            subplot(4,2,rest)
            rest = rest+1;
            if ~isempty(event2(i).avfnorm),
                plot_filled_mech([event1(i).avfnorm(1,:)] , [event1(i).avslip(1,:)])
                if event1(i).nmult>1;
                    for j=2:event1(i).nmult
                        h1 = plot_focal_plane([event1(i).avfnorm(j,:)],'--y');
                        h2 = plot_focal_plane([event1(i).avslip(j,:)],'--y');
                    end
                end
                hold on
            end
            hold on;
            plot_focal_base1([],[],[],[])
            % Polarity observations with no amplitude
            j = find(~event3(i).s2p);
            plot_focal_base1(event3(i).azi(j),event3(i).takeoff(j),event3(i).pol(j),  ...
                cell2mat(event3(i).sta'),sizefac,[0 0.5 1],[],3);
            % Amplitude observations with no polarity
            j = find(event3(i).s2p & ~event3(i).pol);
            sizefac1 = min(0.5,(event3(i).s2p(j)+0.5)*2*sizefac);
            plot_focal_base1(event3(i).azi(j),event3(i).takeoff(j),event3(i).pol(j)+1,  ...
                cell2mat(event3(i).sta'),sizefac1,[1 0.5 0],[],3);
            %Amplitude observations for negative polarity
            j = find(event3(i).s2p & event3(i).pol<0);
            sizefac1 = min(0.5,(event3(i).s2p(j)+0.5)*2*sizefac);
            plot_focal_base1(event3(i).azi(j),event3(i).takeoff(j),-event3(i).pol(j),  ...
                cell2mat(event3(i).sta'),sizefac1,[1 1 0],[],3);
            % Amplitude observations for positive polarity
            j = find(event3(i).s2p & event3(i).pol>0);
            sizefac1 = min(0.5,(event3(i).s2p(j)+0.5)*2*sizefac);
            plot_focal_base1(event3(i).azi(j),event3(i).takeoff(j),event3(i).pol(j),  ...
                cell2mat(event3(i).sta'),sizefac1,[0 0.5 0.25],[],3);
            % % Amplitude predictions
            % j = find(event3(i).s2p);
            % sizefac1 = min(0.5,(event3(i).s2ppred(1,j)+0.5)*2*sizefac);
            % plot_focal_base1(event3(i).azi(j),event3(i).takeoff(j), ...
            %     1+0*event3(i).pol(j),cell2mat(event3(i).sta'),sizefac1,[1 0 0],[],4);

            %find RMS fault plane uncertianty
            event1(i).RMS=(event1(i).avfnorm_uncert+event1(i).avslip_uncert)/2;
            %  ttl =  make_lbl(event2(i).id);
            ttl = int2str(event2(i).id);
            for j=1:event1(i).nmult
                if j==1;
                    string=['ID: ' ttl ', ' setstr(event1(i).mechqual) ' , Dep: = '  num2str(event1(i).depth,2) ' , ndata = ' int2str([event1(i).polnum event1(i).namp])  ' , misfit = ' int2str([event1(i).polmisfit(j) event1(i).mavg(j)])  ' , prob = ' int2str(event1(i).mechprob(j)) ' , stndistrat = ' int2str(event1(i).stdr(j)) ];
                else
                    %      string=['Alternative solution - misfit = ' int2str([event1(i).polmisfit(j) event1(i).mavg(j)])  ' , stndistrat = ' int2str(event1(i).stdr(j)) ' , prob = ' int2str(event1(i).mechprob(j))];
                end
                text(-5.3,1.1-(j-1)*.15,string, 'horizontalalignment','left','FontSize',16);
            end
            orient('tall')
            text (-5.3,1.1-event1(i).nmult*0.2,['uncert = '  int2str(event1(i).RMS')  ' , Azim gap = ' int2str(event1(i).max_azimgap) ' , Takeoff gap = '   int2str(event1(i).max_takeoff) 'Po badfrac: ' num2str(range1(i1),2) ',SP badfrac:' num2str(range2(j1),2)], 'horizontalalignment','left' ,'FontSize',16)
            drawnow
            k=k+1;
        end
        
    end
end