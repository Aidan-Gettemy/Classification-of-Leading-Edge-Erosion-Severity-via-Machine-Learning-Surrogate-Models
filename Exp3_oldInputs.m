clc;close;clear;
addpath funcs\
addpath erosionfuncs\
%% Run this code to generate a table of inputs for experiment 3

% Experiment 3: Guassian Process Training Set

% We have determined that the effect of wind shear appears to be minimal

% We will use the linear blade erosion distribution since it is most
% likely 

expName = "Exp3";

% Input Table ID
inTableID = expName+"_inTable.txt";

% The input column names
invarNames = ["WindDirection","WindSpeed","AirDensity","WindShear",...
    "B1Er1","B1Er2","B1Er3","B1Er4","B1Er5","B1Er6",...
    "B2Er1","B2Er2","B2Er3","B2Er4","B2Er5","B2Er6",...
    "B3Er1","B3Er2","B3Er3","B3Er4","B3Er5","B3Er6"...
    "Alpha","Shape"];
%%
% After the latin hyper-cube, we have to map those values between 0 and 1
% into the experimental ranges.  These have been set for the environmental
% variables as the same as in the Morris Method Experiment

% Now, to determine the erosion regions, we will fit the kde
% to a large amount of random draws from the Blade Erosion Distribution
% from the five severity classes used.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Severity data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of Classes 
classes = 5; 
% Number of samples per Class
samples = 50;
% Total number of rows
num = classes*samples;
% Erosion Severity Values
severities = linspace(0,1,classes);
storage = zeros(num,6);
for i = 1:5
    severity = severities(i);
    storage((i-1)*samples+1:i*samples,:)=bladeErDist(severity,samples);
end
% Then we will use inverse cumulative distribution sampling to map unit
% interval into a sampling distribution that will evenly fill the space
% where we are most likely to need to make an evaluation of the simulator

% We will generate 1200 training points using the inverse cdf, and 100 from
% simulator with erosion level set to 0.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Latin Hyper Cube 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dim = 9;
p = lhsdesign(num,dim,'Criterion','correlation','iterations',10);

% Hold the Results of mapping from the Hyper-Cube to the Erosion Level
results = zeros(samples*classes,6);
for j = 1:6
    iter = 0;
    for i = 1:numel(results(:,1))
        a = samples*(iter)+1;
        b = samples*iter+samples;
        results(i,j)=kdeInvSamp(p(i,j+3),storage(a:b,j));
        if mod(i,samples)==0
            iter = iter+1;
        end
    end
end
%% Check if the GP training points have good coverage 
results(1:samples,:) = zeros(samples,6); % The first samples-many rows are zeros
a = 4;
b = 5;
close all
scatter(storage(:,a),storage(:,b),20,'blue','filled','>')
hold on
scatter(results(:,a),results(:,b),5,'black','o','filled')
xlim([0,1])
ylim([0,1])
xlabel(num2str(a));ylabel(num2str(b));
title("Plotting Distribution points vs Mapped Points "+num2str(a)+ " vs "+num2str(b))
legend({"distribution","mapped"})
%% You should see 4 distinct clusters and the origin
subplot(1,2,1)
plotmatrix(storage)
subplot(1,2,2)
plotmatrix(results)
%% Make the Input Table
% Number of inputs
dim = numel(invarNames);
M = zeros(num,dim);
class = 0;
% Build the matrix of input values/names
for i = 1:numel(M(:,1))
    % Environmental Variables
    M(i,1) = -15+30*p(i,1); % Wind Direction [-15, 15]
    M(i,2) = 3+22*p(i,2); % Wind Speed [3, 25]
    M(i,3) = 1.10+(1.42-1.10)*p(i,3);% Air Density [1.10, 1.42]
    M(i,4) = .2; % Set the wind shear level
    % Erosion Levels for Blade Regions
    erprofile = results(i,:);
    M(i,5:end-2) = [erprofile,erprofile,erprofile];
    M(i,end-1) = class/4;
    if mod(i,samples)==0
        class = class+1;
    end
    M(i,end) = 1;
end
%% Build the table and save it
% We only need ~1/3 as many of the clean samples, and even then, we have
% too much data
inputDesignTab = array2table(M(samples-29:end,:),"VariableNames",invarNames);
writetable(inputDesignTab,inTableID)

