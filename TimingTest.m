clc;close;clear;
%% Load up packages
addpath('PPGP_ROM/RobustGaSP_matlab/functions');
addpath('PPGP_ROM/RobustGaSP_matlab/data');
addpath('PPGP_ROM');
addpath('PPGP_ROM/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/');
% Load the data 
dataId = "Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
data = readtable(dataId);

addpath funcs/
addpath Simulate/
addpath Template_NREL5MW_Onshore/


%% Run a Simulation
tic1 = tic;
% Experiment 0: Perform two simulations.  Execute our model then execute
% the reference model
expName = "Exp0";
% TemplateID: set the location for the Template Files
TempID = "Template_NREL5MW_Onshore";
% Simulation Bounds (which row to start and stop on)
JobNum = [1, 2];
% Test Duration in seconds
test_dur = 180;
% Extract Statistics from the last x seconds
trans = 100;
% Time Step
DT = 1/160;
% Delete .out files
delOut = "false"; %"true" or "false"
% Delete Big TS dataTable
delTab = "false"; %"true" of "false"

% Run Simulation/Clean Up Results

% Input Table ID
inTableID = expName+"_inTable.txt";

% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;
%
% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Go ahead and make all the prep-folders and files
status = mkdir(ExperimentID);

% Read in the ExpInputTable
M = readtable(inTableID);

% Iterate through Simulation Jobs
% We execute one job like normal, and then one job just calls the functions
% directly for the reference turbine (no setup required)
for i = JobNum(1):JobNum(1)
    % Define the auxiliary setup inputs
    aux = {expName,test_dur,DT,i,StatusFileID,TempID,JobNum(1)};
    % Simulate Row i of ExpInputTable, according to stated SetUpFunction
    status = setup(M(i,:),aux);
end

toc1 = toc(tic1);

%% Fit the whole PPGP Model
% Examine the PPGPs ability to emulate all of the promising quantities at once

% Extract the features we want to use.
% Read in the selected predictors
tic2 = tic;
predimpID = "MachineLearning/Classification_imp.txt";
Importances=readmatrix(predimpID);
% We will use the first 8 most important variables 
numvars = 8;
% Percent of data to put towards testing
percent = (210-170)/210;
% Grab the columns for testing and training 
[In_train,Out_train,In_test,Out_test,targets] = PPGP_dataprep(numvars,Importances,data,percent);

% Note, several of these variables are range limited.

% Write a function which takes in the original values and returns the 
% values given by zGP imputation 
zGP_cols = [2,6,7,8];
lim_types = ["lower","lower","lower","upper"];
zGP_outs = zeros(numel(Out_train(:,1)),numel(zGP_cols));
zGP_scale = zeros(numel(zGP_cols),1);
zGP_shift = zeros(numel(zGP_cols),1);
yRLs = zeros(numel(In_train(:,1)),numel(zGP_cols));

% Impute zGP values for the desired columns
for i =1:numel(zGP_cols)
    output = Out_train(:,zGP_cols(i));
    [zGP_outs(:,i), zGP_scale(i), zGP_shift(i), yRLs(:,i)] = zGP_process2(output,...
        In_train, lim_types(i));
end

% Fix the Training Ouputs
Out_train(:,zGP_cols) = zGP_outs;
toc2 = toc(tic2);
tic3 = tic;
%options.trend=[ones(numel(Out_train(:,1)),numvars)  In_train];
%options.zero_mean  = false; 
%options.nugget_est = false;

% At last, the model
modelPPzGP=ppgasp(In_train,Out_train);
% Create an object which we can save which has all of the pieces that we
% need:
toc3 = toc(tic3);

%% Predict One Output from the model

tic4 = tic;

out_try = predicted_outputs2(modelPPzGP, In_test(1,:), numvars, zGP_scale, zGP_cols, lim_types, zGP_shift, yRLs, In_train);

toc4 = toc(tic4);

tics = [tic1,tic2,tic3,tic4];
tocs = [toc1,toc2,toc3,toc4];
writematrix(tocs,"Plots/Times.txt");