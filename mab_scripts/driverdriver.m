clear all
clc
close all
rng('default');
successTrials = [1 1;
                 1 5;
                 1 10];
for j = 1:length(successTrials)
%For each maxNumTrials, evaluate mabdriver for 1 to j total successes
%02FEB17, lparker: Originally tested cases of multiple successes out of
%multiple trials, i.e., 1 of 2, 3 of 5, 5 of 5, but since these reflected
%study of message reliability more than the study of successful TX/RX of
%single messages, those cases were removed and the number of cases was
%simplified to the following.
a = successTrials(j,1); %Number of successes
b = successTrials(j,2); %Number of trials
    %eval(['mkdir(''./data'',''cond_' num2str(a) '_' num2str(b) ''');']);
    % After "a" and "b", additional parameters are described as follows:
    % mabdriver(a,b,c,d,e)
    % c: 0- Uniform Random distribution, 1: Even mesh grid
    % d: 0- Gamma, 1- Exponential (Success of communication curve type)
    % e: 0- Small distribution (9 locs), 1- Large distribution (20 locs)
    mabdriver(a,b,0,0,0); % These two data sets should produce the same
    mabdriver(a,b,0,1,0); % sets of locations
    
    mabdriver(a,b,0,0,1); % These two data sets should produce the same
    mabdriver(a,b,0,1,1); % sets of locations

    mabdriver(a,b,1,0,0); % These two data sets should produce the same
    mabdriver(a,b,1,1,0); % sets of locations
    
    mabdriver(a,b,1,0,1); % These two data sets should produce the same
    mabdriver(a,b,1,1,1); % sets of locations    
end

% mabdriver(1,4)
% mabdriver(1,5)
% mabdriver(3,3)
% mabdriver(2,4)
% mabdriver(2,5)
% mabdriver(3,4)
% mabdriver(3,5)
% mabdriver(4,4)
% mabdriver(4,5)
% mabdriver(5,5)
% 
