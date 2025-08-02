clc;close;clear;
%% Run this code to generate a table of inputs for an experiment

% Name the experiment
expName = "TwBaseDamageMorris";
% This will explore the impact of changing 
% N1FAS: [.9,1]
% N1SS: [.9,1]
% waveHs: 1.1*[.9,1.1]
% waveDir: [-10, 10]

% Input Table ID
inTableID = expName+"_inTable.txt";

% The input column names
invarNames = ["windfileID","N1FAS","N2FAS","N1SS","N2SS",...
    "waveMod","waveHs","waveTp","waveDir"];

% Build the matrix of input values/names
% Or read in a table from another source
% Read in the MorrisInputs
D = readmatrix("MorrisInputs.txt");

% Number of tests
num = numel(D(:,1));
% Number of inputs
dim = numel(invarNames);
% windfileID
windfileID = "IEA15MW_ws08.0ms-1_Seed1.bts";
M = cell(num,dim);
%%
for i = 1:num
    M(i,1) = {categorical(windfileID)};
    M(i,2) = {.9+.1*D(i,1)};% FA stif node 1
    M(i,4) = {.9+.1*D(i,2)};% SS stif node 1
    M(i,7) = {.9*1.1+.2*1.1*D(i,3)};% wave height
    M(i,9) = {-10+20*D(i,4)};% wave dir
    M(i,3) = {1};% FA stif node 2
    M(i,5) = {1};% SS stif node 2
    M(i,6) = {2};% wave mode
    M(i,8) = {4.0};% wave period
end

% Build the table and save it
inputDesignTab = cell2table(M,"VariableNames",invarNames);
writetable(inputDesignTab,inTableID)


