%%
clc;close all;clear;

%% TEST 1.) Time simulations
addpath funcs\
addpath erosionfuncs\

num_points = 25;

TABLE = prediction_test(num_points);

% Timing Experiment
expName = "time1";
% TemplateID: set the location for the Template Files
TempID = "Template_NREL5MW_OnshoreTURB";
% Simulation Bounds (which row to start and stop on)
JobNum = [1,num_points];
% Test Duration in seconds
test_dur = 180;
% Extract Statistics from the last x seconds
trans = 60; 
% Time Step
DT = 1/160;
% Delete .out files
delOut = "true"; %"true" or "false"
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
%
% Go ahead and make all the prep-folders and files
status = mkdir(ExperimentID);

% Read in the ExpInputTable
M = TABLE;

% Iterate through Simulation Jobs
% We execute one job like normal, and then one job just calls the functions
% directly for the reference turbine (no setup required)
for i = JobNum(1):JobNum(2)
    timer1 = tic;
    % Define the auxiliary setup inputs
    aux = {expName,test_dur,DT,i,StatusFileID,TempID,JobNum(1)};
    % Simulate Row i of ExpInputTable, according to stated SetUpFunction
    status = setup(M(i,:),aux);
    time_count(i) = toc(timer1);
end

% ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
% Simulations are done now we can do the processing on the raw data tables
%%
m1 = mean(time_count)
std1 = std(time_count);
% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, num_points - 1);
se = std1/sqrt(num_points);
interval = [m1-tcrit*se m1+tcrit*se];

%save("Edits_2026/GP_Modeling/simulation_timing.mat","std1","m1","num_points","interval")
%% TEST 2.a) Time zGP imputation

% Add Paths
addpath('../PPGP_ROM/RobustGaSP_matlab/functions');
addpath('../PPGP_ROM/RobustGaSP_matlab/data');
addpath('../PPGP_ROM/')
addpath('../PPGP_ROM/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/');

%% TEST 2.b)  Load The Data
dataId = "../Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
data = readtable(dataId);

%% TEST 2.c)  Select Correct GP Input and Output Columns

% Load the columns that We Use
predimpID = "../MachineLearning/Classification_imp.txt";
Importances=readmatrix(predimpID);
% We will use the first 8 most important variables 
numvars = 8;
% Down-select to just the relevant columns
suffixes = {"mean","sd","skew","kurt"};
names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};

iter = 1;
for i = 1:numel(suffixes)
    for j = 1:numel(names)
        a = names{j}+suffixes{i};
        varnames(iter) = a;
        iter = iter + 1;
    end
end

others = {"WindDirection","WindSpeed","AirDensity"};
for i =1:numel(others)
    a = others{i};
    varnames(iter) = a;
    iter = iter +1;
end

k_folds = 5;

gpcv = cvpartition(data.Alpha,'KFold',k_folds);

targets = varnames(Importances(1:numvars));
% Prepare the input data for zGP_process2
In_train = data{gpcv.training(1), [1:2,3,5:10]}; % Extract relevant input columns
Out_train = data{gpcv.training(1), targets}; % Extract output columns for zGP

%% TEST 2.d)  Apply the zGP_process2 function to correct columns
% Write a function which takes in the original values and returns the 
% values given by zGP imputation 
zGP_cols = [2,6,7,8];
lim_types = ["lower","lower","lower","upper"];
zGP_outs = zeros(numel(Out_train(:,1)),numel(zGP_cols));
zGP_scale = zeros(numel(zGP_cols),1);
zGP_shift = zeros(numel(zGP_cols),1);
yRLs = zeros(numel(In_train(:,1)),numel(zGP_cols));

% Just need to time ONE output
time1 = tic;
% Impute zGP values for the desired columns
for i =1:1%numel(zGP_cols)
    output = Out_train(:,zGP_cols(i));
    [zGP_outs(:,i), zGP_scale(i), zGP_shift(i), yRLs(:,i)] = zGP_process2(output,...
        In_train, lim_types(i));
end
imputation_time = toc(time1);
%%
imputation_time
% June 15 ~ 279.24 seconds

% Fix the Training Ouputs
% Out_train(:,zGP_cols) = zGP_outs;

%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Prediction Functions
function TABLE = prediction_test(num_points)
    % The input column names
    invarNames = ["WindDirection","WindSpeed","AirDensity","WindShear",...
        "B1Er1","B1Er2","B1Er3","B1Er4","B1Er5","B1Er6",...
        "B2Er1","B2Er2","B2Er3","B2Er4","B2Er5","B2Er6",...
        "B3Er1","B3Er2","B3Er3","B3Er4","B3Er5","B3Er6"...
        "Alpha","Style"];
    
    % Build the matrix of input values/names
    
    % We will build the inputs using the latin hyper cube and the erosion
    % distribution
    
    % Number of Classes 
    classes = 5; 
    % Number of samples per Class
    samples = num_points/classes;
    % Total number of rows
    num = classes*samples;
    % Erosion Severity Values
    Er_classes = linspace(0,1,classes);
    % Holding Matrix
    I = zeros(num,numel(invarNames));
    
    % Use a latin-hyper cube to choose wind direction, wind speeed, and shear
    % values
    
    dim = 3;
    p = lhsdesign(num,dim,'Criterion','correlation','iterations',10);
    
    % Wind Direction
    I(:,1) = -15+30*p(:,1);
    % Wind Speed 
    I(:,2) = 3+22*p(:,2);
    % Air Density
    I(:,3) = 1.10+(1.42-1.10)*p(:,3);%ones(num,1)*1.225;
    % Wind Shear
    I(:,4) = ones(num,1)*0.2;%.5*p(:,3);
    % Set the blade shape type
    I(:,end) = ones(num,1)*1; % Shape is linear
    
    % Draw samples from the erosion distribution
    for i = 1:classes
        erprofile = bladeErDist(Er_classes(i),samples);
        I((i-1)*samples+1:i*samples,5:end-2) = [erprofile,erprofile,erprofile];
        I((i-1)*samples+1:i*samples,end-1) = Er_classes(i)*ones(samples,1);
    end
    
    % Build the table and save it
    TABLE = array2table(I,"VariableNames",invarNames);
end