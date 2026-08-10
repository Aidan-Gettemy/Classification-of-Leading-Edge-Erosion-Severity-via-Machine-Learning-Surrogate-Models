%% Prepare k-fold repeated crossvalidationfor classification
clc;close;clear;
original_data = readtable("../Data/Exp6/LARGE2ExperimentResultTable1_600.txt");
r = 10;k_folds = 5;
rng(400)
for i = 1:r
    % Use a stratification variable, alpha,
    % to ensure that training in is balanced
    FOLDS{i} = cvpartition(original_data.Alpha,'KFold',k_folds); 
end

save(sprintf('%d_x_%d_test1starRF_training_rkfolds.mat',r,k_folds),"FOLDS")
% 
% gpcv1=FOLDS{1};
% gpcv2 = FOLDS2{1};
% 
% plot(gpcv1.training(1) - gpcv2.training(2)%%
%%
cvrf1 = FOLDS{1};
trainingIndices = cvrf1.training(1);
testIndices = cvrf1.test(1);
trainingData = original_data(trainingIndices, :);
testData = original_data(testIndices, :);