bern = {'1of1','1of5','1of10'};
socType = [0 1]; %Type of Success of Comms curve (0-gamma, 1-exp)
socTypeS = {'gamma','exp'};
NN=[20 100]; %Number of agents
distType = [0 1]; % Spatial distribution type (0-Random, 1-Mesh)
iters = [100 500 1000]; %Number of iterations ("t")
vs = [0 1 2]; %Solution version: 0 - Varaiya, 1 - Baseline(random),
      %2 - Semi-intelligent
h = waitbar(0, 'loading and writing data, WAIT!');

data_name = strcat('improv_testdata10MAY17_stationaryB_1.txt');
sB = 0;

%fid_data = fopen(data_name,'a+');
%fid_loc = fopen(loc_name,'a+');

for bn = 1:length(bern) %For bernoulli condition of success
    for dT = distType % Spatial distribution of candidate locations
        for sT = socType %Type of SoC curve
            for nn = NN % Number of candidate locations
                for iterate_i = iters % Number of iterations
                    for ii = vs % Solution type
                        [ii iterate_i bn nn]
                        load(char(strcat('/home/lparker/matlab_scripts/mab_scripts/improv/data_stationaryB_1/cond_',...
                             bern(bn),'/',...
                            'dataout_',...
                            num2str(dT),'_',...
                            num2str(sT), '_', num2str(nn), '_',...
                            num2str(iterate_i), '_', num2str(ii), '.mat')));
                        ob = ones(length(histA),1); %Generic 1's vector
                        dlmwrite(data_name,...
                            [aId' histA bn*ob, dT*ob, sT*ob, nn*ob, iterate_i*ob, ii*ob distMax*ob],'-append');
                        %dlmwrite(loc_name,[locsA locsB],'-append');
                    end
                end
            end
        end
        clearvars -except bn bern dT distType sT socType nn NN iterate_i iters ii vs data_name loc_name h %Clear previous data
    end
    waitbar(ii/length(vs),h);
end
loc_name_rnd20 = strcat('testloc_rnd20_cmp.txt');
loc_name_rnd100 = strcat('testloc_rnd100_cmp.txt');
loc_name_mesh20 = strcat('testloc_mesh20_cmp.txt');
loc_name_mesh100 = strcat('testloc_mesh100_cmp.txt');
load('/home/lparker/matlab_scripts/mab_scripts/improv/data_stationaryB_1/cond_1of1/dataout_0_0_20_100_0.mat')
dlmwrite(loc_name_rnd20,[locsA locsB]);
load('/home/lparker/matlab_scripts/mab_scripts/improv/data_stationaryB_1/cond_1of1/dataout_1_0_20_100_0.mat')
dlmwrite(loc_name_mesh20,[locsA locsB]);
load('/home/lparker/matlab_scripts/mab_scripts/improv/data_stationaryB_1/cond_1of1/dataout_0_0_100_100_0.mat')
dlmwrite(loc_name_rnd100,[locsA locsB]);
load('/home/lparker/matlab_scripts/mab_scripts/improv/data_stationaryB_1/cond_1of1/dataout_1_0_100_100_0.mat')
dlmwrite(loc_name_mesh100,[locsA locsB]);


close(h)

%% Generate quick visual tool for analyzing evolution of Gittins Indices
% Load data of interest
close all
%Select statistic to plot
% q = 1 -- Mean
% q = 2 -- StdDev
% q = 3 -- Number of arm pulls
% q = 4 -- Gittins Index


q = [1 2 3 4];

%Select the arms of interest (up to 4)
%Identify the arms with the top 5 Gittins Indices by the end of the run
refG = [(1:length(gittinsHist(:,:,end)))' gittinsHist(:,:,end)];
refGSort = sortrows(refG,-4); %Sort by the fifth column to obtain Gittins Indices in
% descending order.
refGInd = refGSort(1:5,1);
a1 = refGInd(1);
a2 = refGInd(2);
a3 = refGInd(3);
a4 = refGInd(4);
a5 = refGInd(5);
figure;
for qq = q
    y1 = squeeze(gittinsHist(a1,qq,:));
    y2 = squeeze(gittinsHist(a2,qq,:));
    y3 = squeeze(gittinsHist(a3,qq,:));
    y4 = squeeze(gittinsHist(a4,qq,:));
    y5 = squeeze(gittinsHist(a5,qq,:));
    subplot(2,2,qq);
    plot(y1,'r');hold on;
    plot(y2,'g');
    plot(y3,'c');
    plot(y4,'m');
    plot(y5,'k');
end
legend('1st','2nd','3rd','4th','5th')

xlabel('% of Trials');ylabel('Gittins Index');

figure;
load socs.mat % Load SoC options
maxSpace = 20; %Max space of navigation area (nmi)
maxR = sqrt((2*maxSpace)^2+maxSpace^2); %Defines the max distance between two agents
c = ss_est_gamma;
xx = linspace(0,maxR,length(c));
plot(xx,c,'r');hold on
for bb = refGInd'
    rr = pdist([mean(locsB,1);locsA(bb,:)],'euclidean');    
    rA = interp1(xx,c,rr,'linear');
    plot(rr,rA,'g*');
end
