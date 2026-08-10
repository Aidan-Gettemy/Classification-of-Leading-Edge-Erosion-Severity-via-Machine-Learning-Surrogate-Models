%% Classifier repeated k-fold cross validation 
clc;close;clear;

% Specify folds and repeats
k_folds = 5;
repeats = 10;
% Load the data: Set up for experiment 1
data_original = readtable("../Data/Exp6/LARGE3ExperimentResultTable1_600.txt");
FOLDS = load("10_x_5_test1RF_training_rkfolds.mat");FOLDS= FOLDS.FOLDS;
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
results_sim = run_repeated_kfold_rf( ...
    X, Y, predictorNames, "simulator-trained", k_folds, repeats, FOLDS);

save("TEST1star_results_sim_repeatedCV.mat","results_sim","-v7.3")

%% FUNCTIONS
function results = run_repeated_kfold_rf(X, Y, predictorNames, modelName, k_folds, repeats, FOLDS)

    rng(1)

    classes = categories(Y)
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

            Xtr = X(train_idx,:);
            Ytr = Y(train_idx);

            Xte = X(test_idx,:);
            Yte = Y(test_idx);

            % Hyperparameter tuning occurs only on the training fold
            Mdl = fitcensemble(Xtr,Ytr, ...
                'Method','Bag', ...
                'Learners','Tree', ...
                'PredictorNames',predictorNames, ...
                'OptimizeHyperparameters',{'NumLearningCycles','MaxNumSplits','MinLeafSize'}, ...
                'HyperparameterOptimizationOptions',struct( ...
                    'Repartition',true, ...
                    'KFold',5, ...                         % inner CV for tuning
                    'AcquisitionFunctionName','expected-improvement-plus', ...
                    'ShowPlots',false, ...
                    'Verbose',1));

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
