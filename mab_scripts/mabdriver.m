function [] = mabdriver(kk, noN, gridType, probType, sizeType, SD)
rng(SD);
betaVal = 0;

%INPUTS
% kk: Minimum number of successes required to be considered successful
% comms
% noN: Specifies the location of each arm within Agent A's scope
% gridType: Specifies the location of each arm within Agent B's scope
% probType: Total number of "trials" or attempts at communicating between 
% agents.
% sizeType: A flag to determine the density of locations to be evaluated
% (0: small [20], 1: large [100])
% SD: Seed value used for random number generator
% OUTPUTS
% NONE
%**********OPTIONS FOR DATA COLLECTION*****************
%Define rows and columns of candidate locations
%Density of candidate locations: [3,3], [5,4]
if sizeType == 0
    m = 3; n = 3; 
else if sizeType == 1
        m = 5; n = 4;
    end
end
N = m*n;
iter = [50 75 100 125 150 175 200]; %Number of iterations ("t") %10FEB17: Removed 500 and 1000 to
% speed up analysis.
%iter = [50 100 150 200]; %Number of iterations ("t")
v = [0 1 2 3]; %Solution version: 0 - Gittins (Cheung), 1 - UCB,
      %2 - Epsilon Greedy (added 08APR17), 3 - Baseline (Random)
spaceType = gridType; %Define type of spatial distibution of candidate locations (
               %0 - uniform random, 1 - even grid
maxSpace = 1000; %Max space of navigation area ([m], meant to represent 1x1 nmi^2)
maxR = sqrt((2*maxSpace)^2+maxSpace^2); %Defines the max distance between two agents
%Set locations         
switch(spaceType)
    case(0)
        %This is the new branch where the method of how the candidate
        %locations are distributed is modified (Branch name: spatial_var).
        locsA = maxSpace*rand(N,2); %Define N random locations, set at 20nmi x 20nmi max
        locsB = maxSpace*rand(N,2); %Define N random locations, set at 20nmi x 20nmi max
    case(1)
        %Algorthm taken from:
        %https://forum.processing.org/one/topic/how-to-generate-a-set-of-2d-points-that-are-roughly-evenly-spaced.html
        %randomness = 2; %Not used
        %gap = maxSpace/N; %Not used
        size = [maxSpace,maxSpace];
        x = [];y = []; %Temporary vectors to store candidate locations
        for i = 1:m
            for j = 1:n
                x = [x;(i-1)*(size(2)/m)];
                y = [y;(j-1)*(size(2)/n)];
            end
        end
        locsA = [x y]; locsB = locsA;
        %figure;plot(x,y,'r*')
    otherwise
        disp{'Unknown selection'}
end

% Shift collective location of locsA and locsB to reside in the range of:
% [(-2*maxSpace,2*),(maxSpace/2,-maxSpace/2)]
    locsA = [(locsA(:,1) - maxSpace) (locsA(:,2) - maxSpace/2)];
    locsB = [locsB(:,1) (locsB(:,2) - maxSpace/n)];
%     figure;hold on;
%     plot(locsA(:,1),locsA(:,2),'b*');
%     plot(locsB(:,1),locsB(:,2),'r*');
%**********SETTINGS FOR DATA COLLECTION*****************
%hh = waitbar(0,'Please wait...running through iterations');

for iter_i = iter
    iter_i
    %hhh = waitbar(0,'Please wait...running through types of methods');
    for ii = v
        ii
        %figure;plot(locsA(:,1),locsA(:,2),'r*');hold on;plot(locsB(:,1),locsB(:,2),'b*')

        %Use for TDMA version
        %[histA histB] = scheduleCalc_tdma(betaVal,locsA,locsB,[v iter],maxR);

        %Use for single agent version
        %[histA aId] = scheduleCalc(betaVal,locsA,locsB,[v iter],maxR);

        %Use for single agent Bernoulli version
        [histA aId aB gRef distMax solnHist] = scheduleCalc_bern(betaVal,locsA,locsB,[ii iter_i kk noN],maxR,probType,SD);

        %Use for single agent Bernoulli version and binomial-defined rewards
        %[histA aId aB gRef] = scheduleCalc_bernbino(betaVal,locsA,locsB,[v iter],maxR);

        %Plot results for visual
        %eval(['save(''bernoulliGittens_' num2str(N) '_' ...
        %    num2str(iter) '.mat'',''histA'',''aId'',''aB'',''locsA'',''locsB'',''gRef'');']);
        % Store data in file according to -->
        % Spatial distribution type: Random/Uniform,
        % SoC type: Gamma/Exp, number of agents(or arms), number of time epochs, type of solution (GI/random)]
        eval(['save(''./improv_aamas17/data_stationaryB_1/cond_' num2str(kk) 'of' num2str(noN) '/dataout_' num2str(spaceType) '_' num2str(probType) '_' num2str(N) '_' num2str(iter_i) '_' num2str(ii) '_' num2str(SD) '.mat'');']);
        %waitbar(ii/length(v));
    end
    %waitbar(iter_i/length(iter));
end
%close(hh)
