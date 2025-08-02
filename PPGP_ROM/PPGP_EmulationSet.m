clc,close,clear
addpath("RobustGaSP_matlab\")
% Here we will load emulator and the Input Data

% Remember that we predict certain outputs in order

% We will save the resulting table

%% Now we are ready to generate a new dataset directly from an input table.

% Extract the settings we need to make predictions from the model 
mdl_id = "PP_zGP"+num2str((170/210))+"package.mat";
PP_GPmodel = load(mdl_id);

PP_GP = PP_GPmodel.PP_GP;

modelPPzGP = PP_GP.model;
In_train = PP_GP.In_train;
Out_test = PP_GP.Out_test;
numvars = PP_GP.numvars;
zGP_scale = PP_GP.scaling_factors;
zGP_cols = PP_GP.zGP_index;
lim_types = PP_GP.lim_types;
targets = PP_GP.target_vars;
zGP_shift = PP_GP.zGP_shift;
yRLs = PP_GP.yRLs;

% Extract the columns we use to make the predictions
T = readtable("Exp4_inTable.txt");
In_test = T(:,[1,2,3,5:10]).Variables;
Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);
%% Prepare for saving the results 
Out_predict_means = Out_predict.mean;
% Reshape and save the predicted values into a dataset 
% Add the correct column names
EmTable = array2table(Out_predict_means,"VariableNames",PP_GPmodel.PP_GP.target_vars);
% Add the target Variable
EmTable.Alpha = T.Alpha;
% And save...
saveId = "EmulationDataset.txt";
writetable(EmTable,saveId)