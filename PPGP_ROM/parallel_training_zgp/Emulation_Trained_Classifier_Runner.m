%% Emulation Trained Classifier Runner 

%% Step 1.) Load datasets

clc;close;clear

% Load the original dataset
%emulator_data_original = readtable("../Data/Exp3/LARGE2noisyExperimentResultTable210.txt");
emulator_data_original = readtable("./LARGE3ExperimentResultTable1_470.txt");

% Load the zGP transformed dataset
% data_zgp = readtable("GP_Modeling\zGP_all_data\LARGE2ExperimentResultTable420_zGP.txt");
% data_zgp = readtable("GP_Modeling\zGP_all_data\LARGE2ExperimentResultTable1_zGP.txt");
% data_zgp   = readtable("LARGE2noisyExperimentResultTable210_zGP.txt");

% Load the parameters for the zGP reconstruction
% zGP_params = load("GP_Modeling\zGP_all_data\zGP_params420.mat");
% zGP_params = load("GP_Modeling\zGP_all_data\zGP_params.mat");
% zGP_params   = load("zGP_params210noisy.mat");

% Load the variable names
% suffixes = {"mean","sd","skew","kurt"};
% names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};

% predictor_ranking = readmatrix('Classification_imp_test2.txt');
% varnames = predictor_list(suffixes, names);
% predictorNames = varnames(predictor_ranking(1:9));

class_predictors = load('Classification_variables_test3.mat','TARGET_SENSORS');
predictorNames = class_predictors.TARGET_SENSORS;
%% Step 2.) Train
addpath ./RobustGaSP_matlab/functions/
addpath ./RobustGaSP_matlab/ 
addpath ./zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/
addpath ./erosionfuncs/
% For this plot, train with ALL the available data! 
rng(1)
aux = [1:45,71:110,171:210,271:310,371:415];
%aux = 1:420;
IN_TRAIN  = emulator_data_original(aux,:);
% OUT_TRAIN = data_zgp(aux,:);
%mdl  = ppGP_process2(IN_TRAIN, OUT_TRAIN);

mdl = ppGP_process1(IN_TRAIN, predictorNames, emulator_data_original(aux,:));

%% Step 3.) Emulate

% Generate Input Points
num_points = 50000;
rng(1)
IN_EMU = prediction_test(num_points);


% % ppGP settings 
% zGP_scale = zGP_params.zGP_scale;
% zGP_cols = [2,4];%[2,6,7,8];
% lim_types = ["lower","lower"];%,"lower","upper"];
% zGP_shift = zGP_params.zGP_shift;
% yRLs      = zGP_params.yRLs;
% Predict
% pred_EMU  = wrkflow_predict_ppzGP(mdl, IN_EMU(:,[1,2,3,5:10]).Variables, ...
%                             zGP_scale, zGP_cols, lim_types, zGP_shift, ...
%                             yRLs(aux,:), emulator_data_original(aux,[1,2,3,5:10]).Variables);

pred_EMU = wrkflow_predict_ppGP(mdl,IN_EMU(:,[1,2,3,5:10]).Variables);

%% Train One emulator trained model: 

EM_TRAIN_IN  = array2table(pred_EMU.mean,"VariableNames",predictorNames);
EM_TRAIN_OUT = categorical(IN_EMU.Alpha);
%%
treeTemplate = templateTree( ...
    'SplitCriterion','gdi', ...
    'Reproducible',true);

% % Hyperparameter tuning occurs only on the training fold
% Mdl = fitcensemble(EM_TRAIN_IN,EM_TRAIN_OUT, ...
%     'Method','Bag', ...
%     'Learners','Tree', ...
%     'PredictorNames',predictorNames, ...
%     'OptimizeHyperparameters',{'NumLearningCycles','MaxNumSplits','MinLeafSize'}, ...
%     'HyperparameterOptimizationOptions',struct( ...
%         'Repartition',true, ...
%         'KFold',5, ...                         % inner CV for tuning
%         'AcquisitionFunctionName','expected-improvement-plus', ...
%         'ShowPlots',false, ...
%         'Verbose',1));
% Start a local parallel pool if one is not already open
if isempty(gcp('nocreate'))
    parpool;   % or parpool('local', 8)
end

Mdl = fitcensemble(EM_TRAIN_IN, EM_TRAIN_OUT, ...
    'Method','Bag', ...
    'Learners',treeTemplate, ... % <- this is new
    'PredictorNames',predictorNames, ...
    'OptimizeHyperparameters',{'NumLearningCycles', ...
                               'MaxNumSplits', ...
                               'MinLeafSize', ...
                               'NumVariablesToSample'}, ... % <- this is new
    'HyperparameterOptimizationOptions',struct( ...
        'Repartition',true, ...
        'KFold',5, ...
        'MaxObjectiveEvaluations',30, ...
        'AcquisitionFunctionName','expected-improvement-plus', ...
        'ShowPlots',false, ...
        'UseParallel',true,...
	'Verbose',1));

%% Step 5.) Evaluate The Model

% True Testing Data
% testingDataID= "C:\Users\aidan\Downloads\Classificati" + ...
%     "on-of-Leading-Edge-Erosion-Severity-via-Machine-Learning-Sur" + ...
%     "rogate-Models-main\Data\Exp8\LARGE2ExperimentResultTable1_300.txt";

% testingDataID = "../Data/Exp2/LARGE2ExperimentResultTable500.txt";
testingDataID = "./LARGE3ExperimentResultTable1_600.txt";
TRUE_DATA = readtable(testingDataID);

% Specify folds and repeats

% FOLDS
FOLDS = load("10_x_5_test1starRF_training_rkfolds.mat");FOLDS= FOLDS.FOLDS;
r = 10;k_folds = 5;
% rng(400)
% for i = 1:r
%     % Use a stratification variable, alpha,
%     % to ensure that training in is balanced
%     FOLDS{i} = cvpartition(TRUE_DATA.Alpha,'KFold',k_folds); 
% end

% save(sprintf('%d_x_%d_test1starRF_training_rkfoldsNEW.mat',r,k_folds),"FOLDS")

% Set the datasets 
Y = categorical(TRUE_DATA.Alpha);
X = TRUE_DATA(:,predictorNames);

% Run the training and testing loops
results_em = run_repeated_kfold_rf_emulator( ...
    X, Y, "emulator-trained", k_folds, r, FOLDS, Mdl);

%% Step 6.) Save
save("TEST3_results_em50000_repeatedCV.mat","results_em","-v7.3")

%% Functions
function ppzgp = ppGP_process2(IN_TRAIN, OUT_TRAIN)
    % Summary: given a set of zero-transformed data (table)
    %           return the trained GP 
    In_train = IN_TRAIN(:,[1,2,3,5:10]).Variables;
    ppzgp   = ppgasp(In_train, OUT_TRAIN.Variables,struct('max_eval',256));
end

function predicted_outputs = wrkflow_predict_ppzGP(model, Input, ...
    scaling_factors, zGP_index, lim_types, shifts, yRLs, original_input)
    % PREDICTED_OUTPUTS
    % There might be an issue with the testing trend, which requires a new
    % approach
        %options.testing_trend=[ones(numel(Input(:,1)),out_dim)  Input];
        %options.mean_only  = false; 
    

    pred_model=predict_ppgasp(model,Input);

    for i = 1:numel(zGP_index)
        yRL = yRLs(:,i);
        H=@(xd)[ones(size(xd,1),1) xd];%
        B=H(original_input)\yRL;
        mu = @(x) H(x)*B;

        type = lim_types(i);
        scaling_factor = scaling_factors(i);
        shift = shifts(i);

        if strcmp("upper",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + min(-scaling_factor*pmean+scaling_factor,scaling_factor);
            pred_model.mean(:,zGP_index(i)) = pmean;

            plower = pred_model.lower95(:,zGP_index(i))+mu(Input);
            plower = shift + min(-scaling_factor*plower+scaling_factor,scaling_factor);
            

            pupper = pred_model.upper95(:,zGP_index(i))+mu(Input);
            pupper = shift + min(-scaling_factor*pupper+scaling_factor,scaling_factor);

            pred_model.lower95(:,zGP_index(i)) = pupper;
            pred_model.upper95(:,zGP_index(i)) = plower;
        end
        
        if strcmp("lower",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + max(scaling_factor*pmean,0);
            pred_model.mean(:,zGP_index(i)) = pmean;

            plower = pred_model.lower95(:,zGP_index(i))+mu(Input);
            plower = shift + max(scaling_factor*plower,0);
            pred_model.lower95(:,zGP_index(i)) = plower;

            pupper = pred_model.upper95(:,zGP_index(i))+mu(Input);
            pupper = shift + max(scaling_factor*pupper,0);
            pred_model.upper95(:,zGP_index(i)) = pupper;
        end

        pred_model.sd(:,zGP_index(i)) = scaling_factor*pred_model.sd(:,zGP_index(i));
    end
   predicted_outputs = pred_model;
end

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

function varnames = predictor_list(suffixes,names)
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

end

function results = run_repeated_kfold_rf_emulator(X, Y, modelName, k_folds, repeats, FOLDS, Mdl)

    rng(1)

    classes = categories(Y);
    nClasses = numel(classes);
    nJobs = k_folds * repeats;

    results = struct();
    results.modelName = modelName;
    results.classes = classes;
    results.fold = cell(nJobs,1);

    job = 1;

    for r = 1:repeats

        cvp = FOLDS{r};

        for k = 1:k_folds

            fprintf('Running %s: repeat %d/%d, fold %d/%d\n', ...
                modelName, r, repeats, k, k_folds);

            train_idx = training(cvp,k);
            test_idx  = test(cvp,k);
            numel(train_idx)
            Xtr = X(train_idx,:);
            Ytr = Y(train_idx);

            Xte = X(test_idx,:);
            Yte = Y(test_idx);

            [Ypred, Scores] = predict(Mdl,Xte);

            % Make sure predicted scores align with class order
            modelClasses = string(Mdl.ClassNames);
            ScoresAligned = nan(numel(Yte), nClasses);

            for c = 1:nClasses
                idxClass = find(modelClasses == string(classes{c}));
                if ~isempty(idxClass)
                    ScoresAligned(:,c) = Scores(:,idxClass);
                end
            end

            results.fold{job}.repeat = r;
            results.fold{job}.test_idx = find(test_idx);
            results.fold{job}.fold = k;
            results.fold{job}.Ytrue = Yte;
            results.fold{job}.Ypred = Ypred;
            results.fold{job}.Scores = ScoresAligned;
            results.fold{job}.predictorImportance = predictorImportance(Mdl);
            results.fold{job}.hyperparams = Mdl.ModelParameters;
            results.fold{job}.trainedModel = [];  % save model separately only if needed

            job = job + 1;
        end
    end
end

function ppzgp = ppGP_process1(IN_TRAIN, varnames, OUT_TRAIN)
    % Summary: given a set of zero-transformed data (table)
    %           return the trained GP 
    % Set the variable names = varnames
    In_train = IN_TRAIN(:,[1,2,3,5:10]).Variables;
    ppzgp   = ppgasp(In_train, OUT_TRAIN(:,varnames).Variables,struct('max_eval',256));
end

function predicted_outputs = wrkflow_predict_ppGP(model, Input)
    % PREDICTED_OUTPUTS
    % There might be an issue with the testing trend, which requires a new
    % approach
        %options.testing_trend=[ones(numel(Input(:,1)),out_dim)  Input];
        %options.mean_only  = false; 
   pred_model=predict_ppgasp(model,Input);
   predicted_outputs = pred_model;
end
