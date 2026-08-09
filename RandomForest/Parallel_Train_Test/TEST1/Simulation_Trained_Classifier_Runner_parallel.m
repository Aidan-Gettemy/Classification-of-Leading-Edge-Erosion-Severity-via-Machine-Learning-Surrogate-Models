%% Classifier repeated k-fold cross validation 
clc;close;clear;

% Specify folds and repeats
k_folds = 5;
repeats = 10;
% Load the data
data_original = readtable("./LARGE2ExperimentResultTable1_600.txt");
FOLDS = load("10_x_5_test1starRF_training_rkfolds.mat");FOLDS= FOLDS.FOLDS;
predictor_ranking = readmatrix('Classification_imp_test1.txt');
% Load the variable names
suffixes = {"mean","sd","skew","kurt"};
names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};
varnames = predictor_list(suffixes, names);
predictorNames = varnames(predictor_ranking(1:8));
% Set the datasets 
Y = categorical(data_original.Alpha);
X = data_original(:,varnames);

%% Run the training and testing loops
results_sim = run_repeated_kfold_rf_parallel( ...
    X, Y, predictorNames, "simulator-trained", k_folds, repeats, FOLDS);

save("TEST1star_results_sim_repeatedCV.mat","results_sim","-v7.3")

%% FUNCTIONS
function results = run_repeated_kfold_rf_parallel(X, Y, predictorNames, modelName, k_folds, repeats, FOLDS, numWorkers)
%RUN_REPEATED_KFOLD_RF_PARALLEL
% Repeated k-fold cross-validation with hyperparameter tuning inside each
% training fold. The outer repeated folds are run in parallel using parfor.
%
% Inputs:
%   X              - predictor table or matrix
%   Y              - categorical response vector
%   predictorNames - cell/string array of predictor names
%   modelName      - string label for the model
%   k_folds        - number of folds
%   repeats        - number of repeats
%   numWorkers     - optional number of parallel workers
%
% Output:
%   results - struct containing fold-level predictions, scores, labels,
%             predictor importance, and CV bookkeeping.

    if nargin < 8 || isempty(numWorkers)
        numWorkers = get_num_workers_from_slurm();
    end

    rng(1)

    Y = categorical(Y);
    classes = categories(Y);
    nClasses = numel(classes);

    nJobs = k_folds * repeats;

    % ------------------------------------------------------------
    % Precompute CV partitions serially
    % ------------------------------------------------------------
    cvps = cell(repeats,1);

    for r = 1:repeats
        cvps{r} = FOLDS{r};
    end

    % ------------------------------------------------------------
    % Start parallel pool
    % ------------------------------------------------------------
    pool = gcp('nocreate');

    if isempty(pool)
        parpool('local',numWorkers);
    elseif pool.NumWorkers ~= numWorkers
        delete(pool)
        parpool('local',numWorkers);
    end

    % ------------------------------------------------------------
    % Preallocate fold results
    % ------------------------------------------------------------
    foldResults = cell(nJobs,1);

    % ------------------------------------------------------------
    % Parallel repeated k-fold CV
    % ------------------------------------------------------------
    parfor job = 1:nJobs

        % Map job index to repeat/fold pair
        r = ceil(job / k_folds);
        k = mod(job-1,k_folds) + 1;

        % Reproducibility inside parfor
        rng(100000 + job,'twister')

        cvp = cvps{r};

        train_idx = training(cvp,k);
        test_idx  = test(cvp,k);

        Xtr = X(train_idx,:);
        Ytr = Y(train_idx);

        Xte = X(test_idx,:);
        Yte = Y(test_idx);

        fprintf('Running %s: repeat %d/%d, fold %d/%d\n', ...
            modelName, r, repeats, k, k_folds);

        % --------------------------------------------------------
        % Train model with hyperparameter tuning inside this fold
        % --------------------------------------------------------
        Mdl = fitcensemble(Xtr,Ytr, ...
            'Method','Bag', ...
            'Learners','Tree', ...
            'PredictorNames',predictorNames, ...
            'OptimizeHyperparameters',{'NumLearningCycles','MaxNumSplits','MinLeafSize'}, ...
            'HyperparameterOptimizationOptions',struct( ...
                'Repartition',true, ...
                'KFold',5, ...
                'AcquisitionFunctionName','expected-improvement-plus', ...
                'ShowPlots',false, ...
                'Verbose',0, ...
                'UseParallel',false));

        % --------------------------------------------------------
        % Predict on held-out fold
        % --------------------------------------------------------
        [Ypred, Scores] = predict(Mdl,Xte);

        % Align score columns with global class order
        modelClasses = string(Mdl.ClassNames);
        ScoresAligned = nan(numel(Yte),nClasses);

        for c = 1:nClasses
            idxClass = find(modelClasses == string(classes{c}));

            if ~isempty(idxClass)
                ScoresAligned(:,c) = Scores(:,idxClass);
            end
        end

        % --------------------------------------------------------
        % Predictor importance
        % --------------------------------------------------------
        imp = predictorImportance(Mdl);

        % --------------------------------------------------------
        % Save selected hyperparameter information, if available
        % --------------------------------------------------------
        bestHyperparams = [];

        try
            bestHyperparams = Mdl.HyperparameterOptimizationResults.XAtMinObjective;
        catch
            bestHyperparams = [];
        end

        % --------------------------------------------------------
        % Store fold-level results
        % --------------------------------------------------------
        foldOut = struct();

        foldOut.repeat = r;
        foldOut.fold = k;
        foldOut.job = job;
        foldOut.test_idx = find(test_idx);

        foldOut.Ytrue = Yte;
        foldOut.Ypred = Ypred;
        foldOut.Scores = ScoresAligned;

        foldOut.predictorImportance = imp;
        foldOut.bestHyperparams = bestHyperparams;

        foldResults{job} = foldOut;
    end

    % ------------------------------------------------------------
    % Package output
    % ------------------------------------------------------------
    results = struct();

    results.modelName = modelName;
    results.classes = classes;
    results.k_folds = k_folds;
    
    results.repeats = repeats;
    results.nJobs = nJobs;
    results.predictorNames = predictorNames;
    results.fold = foldResults;

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

function numWorkers = get_num_workers_from_slurm()
%GET_NUM_WORKERS_FROM_SLURM
% Attempts to read worker count from SLURM_CPUS_PER_TASK.
% Falls back to 4 workers if not running under SLURM.

    numWorkers = str2double(getenv('SLURM_CPUS_PER_TASK'));

    if isnan(numWorkers) || numWorkers < 1
        numWorkers = 4;
    end
end
