%% Gaussian Processes Model Comparison Version 

% First, pass the original data through the zGP process2

% Save the outputs.

% Use this data for the k-fold cross validation comparison

clear; close; clc;
%% Add Paths
addpath('./RobustGaSP_matlab/functions/');
addpath('./RobustGaSP_matlab/data/');
addpath('./RobustGaSP_matlab/')
addpath('./zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/');
which separable_multi_kernel -all
%% 1.) Load The Data
% dataId = "../Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
dataId = "LARGE2noisyExperimentResultTable210.txt";
data = readtable(dataId);

%% 2.) Select Correct GP Input and Output Columns

% Load the columns that We Use
predimpID = "./Classification_imp_test2.txt";
Importances=readmatrix(predimpID);
% We will use the first 8 most important variables 
numvars = 9;
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

targets = varnames(Importances(1:numvars));
% Prepare the input data for zGP_process2
In_train = data{:, [1:2,3,5:10]}; % Extract relevant input columns
Out_train = data{:, targets}; % Extract output columns for zGP

%% 3.) Apply the zGP_process2 function to correct columns
% Write a function which takes in the original values and returns the 
% values given by zGP imputation 
zGP_cols = [2,4];
lim_types = ["lower","lower"];
zGP_outs = zeros(numel(Out_train(:,1)),numel(zGP_cols));
zGP_scale = zeros(numel(zGP_cols),1);
zGP_shift = zeros(numel(zGP_cols),1);
yRLs = zeros(numel(In_train(:,1)),numel(zGP_cols));

% Impute zGP values for the desired columns
parfor i =1:numel(zGP_cols)
    output = Out_train(:,zGP_cols(i));
    [zGP_outs(:,i), zGP_scale(i), zGP_shift(i), yRLs(:,i)] = zGP_process2(output,...
        In_train, lim_types(i));
end

% Fix the Training Ouputs
Out_train(:,zGP_cols) = zGP_outs;

%% 4.) Prepare for k-fold cross-validation
folderID = 'LARGE2noisyExperimentResultTable210_zGP.txt';
% Save the imputed outputs to a text file for cross-validation
writetable(array2table(Out_train), folderID);
% save the other zGP data
save('zGP_params210noisy.mat','zGP_scale', 'zGP_shift', 'yRLs')
