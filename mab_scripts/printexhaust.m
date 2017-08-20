bern = {'1of1','1of5','1of10'};
socType = [0 1]; %Type of Success of Comms curve (0-gamma, 1-exp)
socTypeS = {'gamma','exp'};
NN=[9 20]; %Number of agents
distType = [0 1]; % Spatial distribution type (0-Random, 1-Mesh)
iters = [100 500 1000]; %Number of iterations ("t")
vs = [0 1 2 3]; %Solution version: 0 - Varaiya, 1 - Baseline(random),
      %2 - Semi-intelligent
h = waitbar(0, 'loading and writing data, WAIT!');

data_name = strcat('improv_icradata19AUG17_stationaryB_1_beta_p95.txt');
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
                        load(char(strcat('./improv_icra17/data_stationaryB_1/cond_',...
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
loc_name_rnd9_orig = strcat('testloc_rnd9_icra.txt');
loc_name_rnd20_orig = strcat('testloc_rnd20_icra.txt');
loc_name_mesh9_orig = strcat('testloc_mesh9_icra.txt');
loc_name_mesh20_orig = strcat('testloc_mesh20_icra.txt');
load('./improv_icra17/data_stationaryB_1/cond_1of1/dataout_0_0_9_100_0.mat')
dlmwrite(loc_name_rnd9_orig,[locsA locsB]);
load('./improv_icra17/data_stationaryB_1/cond_1of1/dataout_1_0_9_100_0.mat')
dlmwrite(loc_name_mesh9_orig,[locsA locsB]);
load('./improv_icra17/data_stationaryB_1/cond_1of1/dataout_0_0_20_100_0.mat')
dlmwrite(loc_name_rnd20_orig,[locsA locsB]);
load('./improv_icra17/data_stationaryB_1/cond_1of1/dataout_1_0_20_100_0.mat')
dlmwrite(loc_name_mesh20_orig,[locsA locsB]);


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

%%
%Quick plotting comparison between different beta values for gittins
%indices
vp95 = [0.22263 0.28366 0.32072 0.34687 0.36678 0.38267 0.39577 0.40682 0.41631... %1-9
     0.42458 0.47295 0.49583 0.50953 0.51876 0.52543 0.53050 0.53449 0.53771... %10-90
    0.54037 0.55344 0.55829 0.56084 0.56242 0.56351 0.56431 0.56493 0.56543 0.56583]; %100 - 1000

% %For beta =0.8
% v = [0.22582 0.27584 0.30297 0.32059 0.33314 0.34261 0.35005 0.35607 0.36105... %1-9
%      0.36525 0.38715 0.39593 0.40070 0.40370 0.40577 0.40728 0.40843 0.40934... %10-90
%      0.41008 0.41348 0.41466 0.41525 0.41561 0.41585 0.41602 0.41615 0.41625 0.41633]; %100 - 1000

%For beta =0.5
%vp5 = [0.14542 0.17209 0.18522 0.19317 0.19855 0.20244 0.20539 0.20771 0.20959... %1-9
%     0.21113 0.21867 0.22142 0.22286 0.22374 0.22433 0.22476 0.22508 0.22534... %10-90
%     0.22554 0.22646 0.22678 0.22693 0.22703 0.22709 0.22714 0.22717 0.22720 0.22722]; %100 - 1000
 
vi = [1:10,20:10:100,200:100:1000]; %Generate vector of iterations associated with pre-calculated Gittins' Indices

vi_interp = linspace(1,1000,1000);
vNewp5 = interp1(vi,vp5,vi_interp,'cubic');
vNewp95 = interp1(vi,vp95,vi_interp,'cubic');
% %Plot of Gittins' Index values
%figure;
%plot(vi,v,'r');hold on
%plot(vi_interp,vNew,'b');
gittinsScale_p95 = 0.2236; 
gittinsScale_p5 = 0.7701; 
%Plot Gittins Index values (scaled version)
% Presuming a = 0.95, 0.2236 = (1-a)^0.5 and vi_interp = n, where n = [1 1000]
% Presuming a = 0.5, 0.7071 = (1-a)^0.5 and vi_interp = n, where n = [1 1000] 
%gittinsExp will be the function v(0,n,1) as referenced in 2.13 of Gittins
%et al. (1989)
gittinsExp_p95 = vNewp95./(vi_interp*gittinsScale_p95);
gittinsExp_p5 = vNewp5./(vi_interp*gittinsScale_p5);


figure;
semilogy(vi_interp,gittinsExp_p95,'r');hold on;
semilogy(vi_interp,gittinsExp_p5,'g');
legend('beta = 0.95','beta = 0.5')