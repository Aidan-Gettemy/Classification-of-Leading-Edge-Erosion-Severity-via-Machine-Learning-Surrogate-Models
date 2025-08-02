clc;close;clear;
addpath funcs\
addpath erosionfuncs\
%% Run this code to generate a table of inputs for experiment 1

% Experiment 1: Elementary Analysis of erosion and environmental effects
expName = "Exp1";

% Input Table ID
inTableID = expName+"_inTable.txt";

% The input column names
invarNames = ["WindDirection","WindSpeed","AirDensity","WindShear",...
    "B1Er1","B1Er2","B1Er3","B1Er4","B1Er5","B1Er6",...
    "B2Er1","B2Er2","B2Er3","B2Er4","B2Er5","B2Er6",...
    "B3Er1","B3Er2","B3Er3","B3Er4","B3Er5","B3Er6"...
    "Alpha","Style"];

% Build the matrix of input values/names
% Or read in a table from another source
I = readmatrix("MorrisInputs.txt");
%%
% Number of tests: repeat once for each shape function 
num = 3*numel(I(:,1)); 

% (linear, quadratic, cubic)
% Number of inputs
dim = numel(invarNames);

M = zeros(num,dim);

for j = 1:3
    style = j;
    for i = 1:num/3
        M(i+150*(j-1),1) = -15+30*I(i,1); % Wind Direction [-15, 15]
        M(i+150*(j-1),2) = 3+22*I(i,2); % Wind Speed [3, 25]
        M(i+150*(j-1),3) = 1.10+(1.42-1.10)*I(i,3);% try [1.10, 1.42]\\was:Air Density [.9, 1.1]*1.225
        M(i+150*(j-1),4) = .5*I(i,4); % Wind Shear Exponent [0.0, 0.5]
        alpha = I(i,5); % Erosion Level
        erprofile = erShape(style,alpha);
        M(i+150*(j-1),5:end-2) = [erprofile',erprofile',erprofile'];% Erosion Levels
        M(i+150*(j-1),end-1) = alpha;
        M(i+150*(j-1),end) = style;
    end
end
%%
% Build the table and save it
inputDesignTab = array2table(M,"VariableNames",invarNames);
writetable(inputDesignTab,inTableID)


