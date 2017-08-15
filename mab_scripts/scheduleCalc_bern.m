function [bestArmHistory, agentId, agentB, c_r, distTot, solnMat] = scheduleCalc_bern(beta,armLocA,armLocB,opts,mR,pType)
%Test script for schedule algorithm based on Weber Tutorial and L. Gregorio
%This script is modified to account/test for the impact of alternating
%arm/location selection to mimic TDMA communication protocol.
%Created by: Lonnie Parker
%Created on: 02/19/16
%Last modified on: 03/28/17
%Modification History:
%03/27/16: Created Bernoulli version of scheduleCalc.m
%(scheduleCalc_bern.m) to test unity reward and select arm based on
%proximity.
%10/10/16: Cleaned up for checking into git repo.
%03/28/17: Added history of Gittins values, gittinsMat, as a return
%variable
%Naval Undersea Warfare Center DIVNPT

%INPUTS
% beta: A n x 1 vector of discount values to be tested for each solution
% armLocA: Specifies the location of each arm within Agent A's scope
% armLocB: Specifies the location of each arm within Agent B's scope
% opts: 4 x 1 vector containing the options with which a solution should
% be tested [Solution type, length of run, minimum number of successes,
% total number of communication "trials" considered].
% Solution type can be:
% REMOVED as of 01MAR17
% (0 - Varaiya, 1 - Baseline(random), 2 - Parker, 3 - Sonin, 3 - Katehakis)
% REPLACED WITH
% (0 - Cheung, 1 - Baseline(random), 2 - Parker (ad-hoc, not used for
% 04APR17 review) 3 - Placeholder)
% mR: Maximum possible distance between agents
% pType: Success of Communication curve type (exponential or gamma) (as of
% 10FEB17.
% OUTPUTS
% bestArmHistory: A Nx4 vector of information representing a) the physical 
% locations of the best arm selection, [x,y], b) the separation distance at
% which that occurs, and c) the success/failure of the transmission at that
% location. N represents the total time steps/iterations.
% agentId: The id of the best arm selection at each time step.
% agentB: Send back the location of agentB (for now, since all
% agentA locations will be determined relative to a stationary AgentB).
% cofr: A 3 x n vector representing r, C(r), and the threshold used
% distTot: a 1x1 value representing the total distance traveled throughout
% all iterations.
% solnMat: A N x 5 x opts(2) multi-dimensional matrix that records the
% time history of each change in the Index calculations
% (Gittins/UCB/epsion-greedy) for each location (or arm). This variable
% will be empty if a purely random solution is sought.

rng('default'); %Set seed value for reproduceability
load socs.mat % Load SoC options
%Calculate derivative of SoC
if pType == 0
    c = ss_est_gamma;
else if pType == 1
        c = ss_est_exp;
    end
end

xx = linspace(0,mR,length(c));
%dc = diff(c)./diff(xx);dc = dc/max(dc); %Unused (artifact from previous idea for implementation)
%d2c = diff(dc)./diff(xx(1:end-1)); %Unused (artifact from previous idea for implementation)
gThresh = 0.5*max(c); %Threshold for successful acomms, "Gamma"
gPlot = gThresh*ones(1,length(xx));

%Return C(r) data along with threshold used for decisions
c_r = [xx;c;gPlot];
%subplot(3,1,2);plot(xx(1:end-1),dc/max(dc),'r'); %First derivative (no
%longer relevant)
%subplot(3,1,3);plot(xx(1:end-2),d2c/(2*max(d2c)),'r') %Second derivative
%no longer relevant)

%dc = dc/max(dc); %Normalize %Unused (artifact from previous idea for implementation)

armNumA = length(armLocA); %Total number of arms Agent A will consider
armNumB = length(armLocB); %Total number of arms Agent B will consider
vA = zeros(1,armNumA); % Gittins indices for AgentA
vB = zeros(1,armNumB); % Gittins indices for AgentB %Unused since Agent B is considered stationary

%History of Gittins indices
%vAvec = zeros(opts(2),armNumA); %Unused
%vBvec = zeros(opts(2),armNumB); %Unused
agentB = armLocB(1,:); %Freeze location of AgentB
%Define max reward as a function of max distance between AgentA arm
%locations

%localMr = max(pdist(armLocA)); %Unused
agentId = zeros(1,opts(2)); %Record agentA arm selection at each time epoch

%History of all arms selected
bestArmHistory = zeros(opts(2),5); %[X-pos Y-pos Prob(Separation Dist) Separation Dist success]
%03/20/17, LTP: Addition of vector that records history of estimates and
%drives arm selection more closely (nearly identically to) M. Cheung's
%approach. gittinsVec = [thetaAvg sigmaSq ni v]
% thetaAvg: From M. Cheung
% sigmaSq: From M. Cheung
% ni: From M. Cheung
% v: From M. Cheung

%03/20/17: Generate approximation of Gittins Indices v(0,n,1) decreasing
%logarithmically as observations increase.
%**************************************************************************
%For beta =0.95
vp = [0.22263 0.28366 0.32072 0.34687 0.36678 0.38267 0.39577 0.40682 0.41631... %1-9
     0.42458 0.47295 0.49583 0.50953 0.51876 0.52543 0.53050 0.53449 0.53771... %10-90
    0.54037 0.55344 0.55829 0.56084 0.56242 0.56351 0.56431 0.56493 0.56543 0.56583]; %100 - 1000

% %For beta =0.8
% vp = [0.22582 0.27584 0.30297 0.32059 0.33314 0.34261 0.35005 0.35607 0.36105... %1-9
%      0.36525 0.38715 0.39593 0.40070 0.40370 0.40577 0.40728 0.40843 0.40934... %10-90
%      0.41008 0.41348 0.41466 0.41525 0.41561 0.41585 0.41602 0.41615 0.41625 0.41633]; %100 - 1000

%For beta =0.5
%vp = [0.14542 0.17209 0.18522 0.19317 0.19855 0.20244 0.20539 0.20771 0.20959... %1-9
%     0.21113 0.21867 0.22142 0.22286 0.22374 0.22433 0.22476 0.22508 0.22534... %10-90
%     0.22554 0.22646 0.22678 0.22693 0.22703 0.22709 0.22714 0.22717 0.22720 0.22722]; %100 - 1000
 
vi = [1:10,20:10:100,200:100:1000]; %Generate vector of iterations associated with pre-calculated Gittins' Indices

vi_interp = linspace(1,1000,1000);
vNew = interp1(vi,vp,vi_interp,'cubic');
% %Plot of Gittins' Index values
%figure;
%plot(vi,v,'r');hold on
%plot(vi_interp,vNew,'b');
gittinsScale = 0.2236; 
%Plot Gittins Index values (scaled version)
% Presuming a = 0.95, 0.2236 = (1-a)^0.5 and vi_interp = n, where n = [1 1000]
% Presuming a = 0.5, 0.7071 = (1-a)^0.5 and vi_interp = n, where n = [1 1000] 
%gittinsExp will be the function v(0,n,1) as referenced in 2.13 of Gittins
%et al. (1989)
gittinsExp = vNew./(vi_interp*gittinsScale);

%**************************************************************************
distTot = 0; %Initialize total distance traversed between arm selections
%Flag to test impact on estimating location of transmitting agent (B) as
%stationary or mobile
% 0 - agent B location changes prior to each transmission, thus impacting
% the range from agent A.
% 1 - agent B location is estimated as the mean of all locations prior to
% each transmission.

stationaryB = 1;
epsG = 0.05; %Define epsilon greedy const
switch(opts(1))
    case {0} %Solution by M. Cheung et al.
        %Initialize Gittins Index snap shot
        gittinsVec = [zeros(armNumA, 4) (1:armNumA)'];
        %Initialize Gittins Index history matrix
        gittinsMat = zeros(armNumA, 5,opts(2)); %E.G. [N x 5 x Epochs]
%        h = waitbar(0,'Please wait...running through intelligent iterations');
        initAgentId = ceil(armNumA*rand);
        agentA = armLocA(initAgentId,:); %Initialize current location of Agent A
        agentId(1) = initAgentId;
        %Evaluate success or failure of decision based on the initial
        %location
        % "Move" agent B prior to transmitting
        rrVec = zeros(1,armNumA);
        if stationaryB == 0
            % Randomly select index of new location for Agent B
            bLoc = ceil(rand*length(armLocB));
            rrVec = pdist([armLocB(bLoc,:);armLocA],'euclidean');
            rrVec = rrVec(1:armNumB);
            %rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
        else
            rrVec = pdist([mean(armLocB,1);armLocA],'euclidean');
            rrVec = rrVec(1:armNumB);
            %rr = pdist([mean(armLocB,1);agentA],'euclidean');
        end
        
        %mark = envReward(rA,opts(3),opts(4));
        %Prime first location with mean and standard dev. for current loc.
        initStatVec = zeros(armNumA,100);
        thetaAvgVec = zeros(armNumA,1);
        sigmaAvgVec = zeros(armNumA,1);
        for aa = 1:armNumA
            for dd = 1:100
                rA = interp1(xx,c,rrVec(aa),'linear');
                initStatVec(aa,dd) = envReward(rA,opts(3),opts(4));
            end
        end
        thetaAvgVec = mean(initStatVec,2);
        sigmaSqVec = (std(initStatVec,0,2)).^2;

        ni = 1;
        v = thetaAvgVec(initAgentId) + sqrt(sigmaSqVec(initAgentId))*gittinsExp(ni);
        gittinsVec(initAgentId,:) = [thetaAvgVec(initAgentId) sigmaSqVec(initAgentId) ni v gittinsVec(initAgentId,5)];
        %Store all mean and stddev values for all arms at once (slightly
        %redundant as these values associated with initAgentId already
        %exist)
        gittinsVec(:,1:2) = [thetaAvgVec sigmaSqVec];
        %Log snapshot of Gittins information for all arms at initial
        %timestep.
        gittinsMat(:,:,1) = gittinsVec;
        bestV = initAgentId; %Initialize bestV, the index associated with the best arm selection
        mark = envReward(rrVec(initAgentId),opts(3),opts(4));
        
        %Initial save of [x-best y-best separation-best success/failure]
        bestArmHistory(1,:) = [agentA interp1(xx,c,rrVec(initAgentId),'linear') rrVec(initAgentId) mark];        
        
        for t = 2:opts(2) %Start at t=2 to indicate the real first "choice"
                          %of an arm is at the next decision epoch
            %Determine AgentA's next location for reception by calculating
            %Gittins Indices usings Equ. 2.13 from M.  Cheung MS Thesis
            %(2013)
            for a = 1:armNumA
                if (a == bestV) %If recently selected arm is being evaluated (i.e. played) 
                    ni = gittinsVec(a,3) + 1; %Update total arm pulls
                    thetaAvg = ((ni-1)/(ni))*gittinsVec(a,1) + (1/ni)*mark;
                    if ni >= 2
                        sigmaSq = ((ni-2)/(ni-1))*sqrt(gittinsVec(a,2)) + (1/ni)*(mark-gittinsVec(a,1))^2;
                    else
                        sigmaSq = gittinsVec(a,2);
                    end
                else
                    thetaAvg = gittinsVec(a,1);
                    sigmaSq = gittinsVec(a,2);
                    ni = gittinsVec(a,3); %No change in arm pull
                end

                v = thetaAvg + sqrt(sigmaSq)*gittinsExp(t);
                gittinsVec(a,:) = [thetaAvg sigmaSq ni v gittinsVec(a,5)];
            end
            %Log snapshot of Gittins information for all arms at t-th
            %timestep.            
            gittinsMat(:,:,t) = gittinsVec;            
            %Replicate the evaluation of a "continuation" index before
            %calcuating a "decision" index. IF newest GI calculated is LESS
            %than the previous BEST, then seek a new BEST, ELSE, CONTINUE
            %if (max(gittinsMat(bestV,4,1:t-1)) > gittinsVec(bestV,4)) && (t > 0.1*opts(2))
            %08APR17, LTP: Added correction to how "bestV" is indexed
            bestV = gittinsVec((gittinsVec(:,4) == max(gittinsVec(:,4))),5);

            %Initially, the calculated Gittins' Indices will be  the same,
            %so explore. (Consider the alternative case where you remain
            %where you are and look at the differences in output)
            %In case there are multiple max Gittins Indices, randomly
            %choose one.
            %Exploration policy
            if length(bestV) > 1
                % % Option 1: Randomly choose
                bestV = ceil(length(bestV)*rand);
            end
           
            %Update history of agent (arm) selection
            agentAold = agentA;
            %Assign newly identified best agent (arm)
            agentA = armLocA(bestV,:);
            %Record the ID of the best agent (arm)
            agentId(t) = bestV;
            
            %Keep track of total distance traversed.
            distTot = distTot + pdist([agentAold;agentA]);
            %Evaluate success or failure of decision based on the
            %location
            if stationaryB == 0
                % Randomly select index of new location for Agent B
                bLoc = ceil(rand*armNumB);
                rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
            else
                rr = pdist([mean(armLocB,1);agentA],'euclidean');
            end
            rA = interp1(xx,c,rr,'linear');            
            %Sample at recently arrived at arm location
            mark = envReward(rA,opts(3),opts(4));
            %Save [x-best, y-best, SoC(separation-best), separation-best, success/failure]
            bestArmHistory(t,:) = [agentA rA rr mark];
        end
        solnMat = gittinsMat; %Return history
        
    case {1} %Upper Confidence Bound (UCB)
        %Initialize UCB Index snap shot
        ucbVec = [zeros(armNumA, 4) (1:armNumA)']; 
        %Initialize UCB Index history matrix        
        ucbMat = zeros(armNumA, 5,opts(2)); %E.G. [N x 5 x Epochs]
%        h = waitbar(0,'Please wait...running through intelligent iterations');
        initAgentId = ceil(armNumA*rand);
        agentA = armLocA(initAgentId,:); %Initialize current location of Agent A
        agentId(1) = initAgentId;
        %Evaluate success or failure of decision based on the initial
        %location
        % "Move" agent B prior to transmitting
        rrVec = zeros(1,armNumA);
        if stationaryB == 0
            % Randomly select index of new location for Agent B
            bLoc = ceil(rand*length(armLocB));
            rrVec = pdist([armLocB(bLoc,:);armLocA],'euclidean');
            rrVec = rrVec(1:armNumB);
            %rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
        else
            rrVec = pdist([mean(armLocB,1);armLocA],'euclidean');
            rrVec = rrVec(1:armNumB);
            %rr = pdist([mean(armLocB,1);agentA],'euclidean');
        end
        
        %mark = envReward(rA,opts(3),opts(4));
        %Prime first location with mean and standard dev. for current loc.
        initStatVec = zeros(armNumA,100);
        thetaAvgVec = zeros(armNumA,1);
        confInt = zeros(armNumA,1);
        %Cycle through all locations to provide an initial mean and stddev
        for aa = 1:armNumA
            for dd = 1:100
                rA = interp1(xx,c,rrVec(aa),'linear');
                initStatVec(aa,dd) = envReward(rA,opts(3),opts(4));
            end
        end
        thetaAvgVec = mean(initStatVec,2);
        %For UCB, we will initialize with standard deviation, but further
        %down, confInt(arm-under-test) = 2*log(time epoch)/(number of arm pulls for that arm)
        confInt = (std(initStatVec,0,2)).^2;
        ni = 1;
        %
        ucb = thetaAvgVec(initAgentId) + sqrt(confInt(initAgentId));
        ucbVec(initAgentId,:) = [thetaAvgVec(initAgentId) confInt(initAgentId) ni ucb ucbVec(initAgentId,5)];
        %Store all mean and stddev values for all arms at once (slightly
        %redundant as these values associated with initAgentId already
        %exist)
        ucbVec(:,1:2) = [thetaAvgVec confInt];
        %Log snapshot of Gittins information for all arms at initial
        %timestep.
        ucbMat(:,:,1) = ucbVec;
        bestV = initAgentId; %Initialize bestV, the index associated with the best arm selection
        %Retrieve an initial sample at starting location.
        mark = envReward(rrVec(initAgentId),opts(3),opts(4));
        
        %Initial save of [x-best y-best separation-best success/failure]
        bestArmHistory(1,:) = [agentA interp1(xx,c,rrVec(initAgentId),'linear') rrVec(initAgentId) mark];        
        
        for t = 2:opts(2) %Start at t=2 to indicate the real first "choice"
                          %of an arm is at the next/second decision epoch
            %Determine AgentA's next location for reception by calculating
            %Upper Confidence Bound (based on beta-Bernoulli model, eq.
            %6.8) from Powell et al.
                
            for a = 1:armNumA
                if (a == bestV) %If recently selected arm is being evaluated (i.e. played) 
                    ni = ucbVec(a,3) + 1; %Update total arm pulls
                    %Update average/mean
                    thetaAvg = ((ni-1)/(ni))*ucbVec(a,1) + (1/ni)*mark;
                    if ni >= 1
                        conf = (2*log(t))/(ni); %This defined the confInt value for UCB
                    else
                        conf = ucbVec(a,2);
                    end
                else
                    thetaAvg = ucbVec(a,1);
                    conf = ucbVec(a,2);
                    ni = ucbVec(a,3); %No change in arm pull
                end

                ucb = thetaAvg + sqrt(conf);
                ucbVec(a,:) = [thetaAvg conf ni ucb ucbVec(a,5)];
            end
            %Log snapshot of UCB information for all arms at t-th
            %timestep.             
            ucbMat(:,:,t) = ucbVec;
            %Replicate the evaluation of a "continuation" index before
            %calcuating a "decision" index. IF newest GI calculated is LESS
            %than the previous BEST, then seek a new BEST, ELSE, CONTINUE
            %if (max(gittinsMat(bestV,4,1:t-1)) > gittinsVec(bestV,4)) && (t > 0.1*opts(2))
            %08APR17, LTP: Added correction to how "bestV" is indexed
            bestV = ucbVec((ucbVec(:,4) == max(ucbVec(:,4))),5);

            %Initially, the calculated Gittins' Indices will be  the same,
            %so explore. (Consider the alternative case where you remain
            %where you are and look at the differences in output)
            %In case there are multiple max Gittins Indices, randomly
            %choose one.
            %Exploration policy
            if length(bestV) > 1
                % % Option 1: Randomly choose
                bestV = ceil(length(bestV)*rand);
            end
           
            %Update history of agent (arm) selection
            agentAold = agentA;
            %Assign newly identified best agent (arm)
            agentA = armLocA(bestV,:);
            %Record the ID of the best agent (arm)
            agentId(t) = bestV;
            
            %Keep track of total distance traversed.
            distTot = distTot + pdist([agentAold;agentA]);
            %Evaluate success or failure of decision based on the
            %location
            if stationaryB == 0
                % Randomly select index of new location for Agent B
                bLoc = ceil(rand*armNumB);
                rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
            else
                rr = pdist([mean(armLocB,1);agentA],'euclidean');
            end
            rA = interp1(xx,c,rr,'linear');            
            %Sample at recently arrived at arm location
            mark = envReward(rA,opts(3),opts(4));
            %Save [x-best, y-best, SoC(separation-best), separation-best, success/failure]
            bestArmHistory(t,:) = [agentA rA rr mark];
        end
        solnMat = ucbMat; %Return history
        
    case{2} %Epsilon Greedy (using the Gittins Index as the "optimal"
            %solution, modified by epsilon.)
        %Initialize Gittins Index snap shot
        gittinsVec = [zeros(armNumA, 4) (1:armNumA)'];
        %Initialize Gittins Index history matrix
        gittinsMat = zeros(armNumA, 5,opts(2)); %E.G. [N x 5 x Epochs]
%        h = waitbar(0,'Please wait...running through intelligent iterations');
        initAgentId = ceil(armNumA*rand);
        agentA = armLocA(initAgentId,:); %Initialize current location of Agent A
        agentId(1) = initAgentId;
        %Evaluate success or failure of decision based on the initial
        %location
        % "Move" agent B prior to transmitting
        rrVec = zeros(1,armNumA);
        if stationaryB == 0
            % Randomly select index of new location for Agent B
            bLoc = ceil(rand*length(armLocB));
            rrVec = pdist([armLocB(bLoc,:);armLocA],'euclidean');
            rrVec = rrVec(1:armNumB);
            %rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
        else
            rrVec = pdist([mean(armLocB,1);armLocA],'euclidean');
            rrVec = rrVec(1:armNumB);
            %rr = pdist([mean(armLocB,1);agentA],'euclidean');
        end
        
        %mark = envReward(rA,opts(3),opts(4));
        %Prime first location with mean and standard dev. for current loc.
        initStatVec = zeros(armNumA,100);
        thetaAvgVec = zeros(armNumA,1);
        sigmaAvgVec = zeros(armNumA,1);
        %Cycle through all locations to provide an initial mean and stddev
        for aa = 1:armNumA
            for dd = 1:100
                rA = interp1(xx,c,rrVec(aa),'linear');
                initStatVec(aa,dd) = envReward(rA,opts(3),opts(4));
            end
        end
        thetaAvgVec = mean(initStatVec,2);
        sigmaSqVec = (std(initStatVec,0,2)).^2;

        ni = 1;
        v = thetaAvgVec(initAgentId) + sqrt(sigmaSqVec(initAgentId))*gittinsExp(ni);
        gittinsVec(initAgentId,:) = [thetaAvgVec(initAgentId) sigmaSqVec(initAgentId) ni v gittinsVec(initAgentId,5)];
        gittinsVec(:,1:2) = [thetaAvgVec sigmaSqVec];
        gittinsMat(:,:,1) = gittinsVec;
        bestV = initAgentId; %Initialize bestV, the index associated with the best arm selection
        mark = envReward(rrVec(initAgentId),opts(3),opts(4));
        
        %Initial save of [x-best y-best separation-best success/failure]
        bestArmHistory(1,:) = [agentA interp1(xx,c,rrVec(initAgentId),'linear') rrVec(initAgentId) mark];        
        
        for t = 2:opts(2) %Start at t=2 to indicate the real first "choice"
                          %of an arm is at the next decision epoch
            gittinsMat(:,:,t) = gittinsVec;
            %Determine AgentA's next location for reception by calculating
            %Gittins Indices usings Equ. 2.13 from M.  Cheung MS Thesis
            %(2013)
                
            for a = 1:armNumA
                if (a == bestV) %If recently selected arm is being evaluated (i.e. played) 
                    ni = gittinsVec(a,3) + 1; %Update total arm pulls
                    thetaAvg = ((ni-1)/(ni))*gittinsVec(a,1) + (1/ni)*mark;
                    if ni >= 2
                        sigmaSq = ((ni-2)/(ni-1))*sqrt(gittinsVec(a,2)) + (1/ni)*(mark-gittinsVec(a,1))^2;
                    else
                        sigmaSq = gittinsVec(a,2);
                    end
                else
                    thetaAvg = gittinsVec(a,1);
                    sigmaSq = gittinsVec(a,2);
                    ni = gittinsVec(a,3); %No change in arm pull
                end

                v = thetaAvg + sqrt(sigmaSq)*gittinsExp(t);
                gittinsVec(a,:) = [thetaAvg sigmaSq ni v gittinsVec(a,5)];
            end
            
            %Replicate the evaluation of a "continuation" index before
            %calcuating a "decision" index. IF newest GI calculated is LESS
            %than the previous BEST, then seek a new BEST, ELSE, CONTINUE
            %if (max(gittinsMat(bestV,4,1:t-1)) > gittinsVec(bestV,4)) && (t > 0.1*opts(2))
            %08APR17, LTP: Added correction to how "bestV" is indexed
            if rand < epsG
                bestV = ceil(armNumA*rand); %Select a random location contrary to the "optimal" choice
            else
                bestV = gittinsVec((gittinsVec(:,4) == max(gittinsVec(:,4))),5);
            end
            %Initially, the calculated Gittins' Indices will be  the same,
            %so explore. (Consider the alternative case where you remain
            %where you are and look at the differences in output)
            %In case there are multiple max Gittins Indices, randomly
            %choose one.
            %Exploration policy
            if length(bestV) > 1
                % % Option 1: Randomly choose
                bestV = ceil(length(bestV)*rand);
            end
           
            %Update history of agent (arm) selection
            agentAold = agentA;
            %Assign newly identified best agent (arm)
            agentA = armLocA(bestV,:);
            %Record the ID of the best agent (arm)
            agentId(t) = bestV;
            
            %Keep track of total distance traversed.
            distTot = distTot + pdist([agentAold;agentA]);
            %Evaluate success or failure of decision based on the
            %location
                if stationaryB == 0
                    % Randomly select index of new location for Agent B
                    bLoc = ceil(rand*armNumB);
                    rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
                else
                    rr = pdist([mean(armLocB,1);agentA],'euclidean');
                end
                    rA = interp1(xx,c,rr,'linear');            
            
            mark = envReward(rA,opts(3),opts(4));
            %Save [x-best, y-best, SoC(separation-best), separation-best, success/failure]
            bestArmHistory(t,:) = [agentA rA rr mark];
        end
        solnMat = gittinsMat; %Return history

     case {3} %Uniformed Random (UR)
        %Placeholder, not used, needed for return variable, analogous to
        %gittinsMat.
        dummyMat = zeros(armNumA, 5,opts(2)); %E.G. [N x 5 x Epochs]
        initAgentId = ceil(armNumA*rand);
        agentA = armLocA(initAgentId,:); %Initialize current location of Agent A
        for t = 1:opts(2)
                %Determine AgentA's next location for reception
                agentAold = agentA;
                ranSel = ceil(armNumA*rand); %Choose random location
                agentA = armLocA(ranSel,:); %Move agentA to new arm location
                distTot = distTot + pdist([agentAold;agentA]);
                agentId(t) = ranSel;
                
                if stationaryB == 0
                    % Randomly select index of new location for Agent B
                    bLoc = ceil(rand*armNumB);
                    rr = pdist([armLocB(bLoc,:);agentA],'euclidean');
                else
                    rr = pdist([mean(armLocB,1);agentA],'euclidean');
                end
                
                rA = interp1(xx,c,rr,'linear');
                
                %Evaluate success or failure of decision
                mark = envReward(rA,opts(3),opts(4));
                
                %Save [x-best y-best separation-best]
                bestArmHistory(t,:) = [agentA rA rr mark];
                %Update waitbar
%                waitbar(t/opts(2));
        end    
        solnMat = dummyMat;        
        
    otherwise
        disp{'Unknown selection'}
end
%close(h)