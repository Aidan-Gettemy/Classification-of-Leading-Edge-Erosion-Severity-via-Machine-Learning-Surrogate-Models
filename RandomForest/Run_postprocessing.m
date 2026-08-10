%% Post Processing Files

clc;close;clear;
testingDataID = '../Data/Exp6/LARGE2ExperimentResultTable1_600.txt';
original_data      = readtable(testingDataID);

%% Settings: 

emulation = 0;

if emulation == 1
    results = load('');% choose the results
    results = results.results_em;
else
    results = load('');% choose the results
    results = results.results_sim;
end

predictor_ranking = readmatrix('');% depends on the experiment

% Load the variable names
suffixes = {"mean","sd","skew","kurt"};
names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};
varnames = predictor_list(suffixes, names);
a = 8; % for test 1, a is 8, for test 2 it is 9
predictorNames = varnames(predictor_ranking(1:a));

% For test 3
%predictorNames = load('Classification_variables_test3.mat');%varnames(predictor_ranking(1:9));
%predictorNames = predictorNames.TARGET_SENSORS;

saveID = "TEST1star_Results/CMEAN_emu10000.mat";

%% ComputeMetrics
metrics = compute_fold_metrics(results);

%% SummarizeMetrics
foldMetrics = summarize_metrics(metrics, results.classes);

%% Plotting: Confusion Matrix:
plot_aggregate_confusion(results)
f = gcf;
f.Position = [100 100 900 700];   % square figure window
title('')

% plot_confusion_imagec(simulation_results)


%% Plotting: Confusion Matrix Advanced
[Cmean,Cstd,Call] = average_confusion_matrix(results);
figure;
h = heatmap(string(results.classes), string(results.classes), Cmean);
h.Title = 'Mean normalized confusion matrix';
h.XLabel = 'Predicted erosion class';
h.YLabel = 'True erosion class';
h.CellLabelFormat = '%.2f';
h.FontName = 'Helvetica';
h.FontSize = 16;
classes = results.classes;

% Write the name to save to 
%save(saveID,"Cmean","classes")

%% Plotting: Confusion Matrix Advanced II
plot_mean_std_confusion(results)

%% Inspect Bad cases
badCases = find_bad_predictions(results, original_data(:,["WindSpeed" "WindDirection" "AirDensity" predictorNames]));
% Show the 20 worst cases
badCases(1:20,:)

%% Show Wrong and Confident Cases
confidentWrong = badCases(badCases.predicted_score > 0.8,:);
confidentWrong(1:min(20,height(confidentWrong)),:)

%% Inspect the Features in bad cases
featureName = predictorNames(1);

figure;
hold on

severeCases = badCases(badCases.class_error >= 2,:);
severeCases(1:min(20,height(severeCases)),:)

scatter(original_data.(featureName), double(categorical(original_data.Alpha)), ...
    30, 'filled', 'MarkerFaceAlpha',0.25)

scatter(severeCases.(featureName), double(severeCases.true_class), ...
    80, 'r', 'filled')

xlabel(featureName,'Interpreter','none')
ylabel('True erosion class')
grid on
box on

%% Plotting: ROC
roc = compute_average_roc(results,101);

plot_average_roc(roc)
title('')

%% Inspect ROC table

aucTable = make_auc_table(roc);

disp(aucTable)

macroAUC_mean = mean(aucTable.AUC_Mean,'omitnan');
macroAUC_std  = std(aucTable.AUC_Mean,0,'omitnan');

fprintf('Macro-average AUC: %.3f ± %.3f\n', macroAUC_mean, macroAUC_std);

roc.nFolds = 50;
[macroAUC_mean, macroAUC_std, macroAUC_all] = compute_macro_auc(roc);

fprintf('Fold-level macro-AUC: %.3f ± %.3f\n', ...
    macroAUC_mean, macroAUC_std);
%% Investigate confusion cost and new thresholds 
thresholds = linspace(0.5,0.01,31);%[0.5 0.4 0.3 0.2 0.1];

% If only the fully eroded class is considered severe:
thresholdSummary = compute_severe_threshold_confusion(results, categorical([1.0]), thresholds);
%save("TEST1star_Results/sim_thresholdSummary.mat","thresholdSummary")
t = 5; % for example, thresholds(3) = 0.3

figure;
confusionchart( ...
    thresholdSummary.threshold(t).Csum, ...
    string(thresholdSummary.classes), ...
    'Normalization','row-normalized');

title(sprintf('Severe threshold = %.2f', thresholdSummary.threshold(t).tau));

fprintf('\nThreshold   Severe Recall   Severe FNR   False Alarm Rate      Conf. Cost\n');
fprintf('---------------------------------------------------------------------------\n');

for t = 1:numel(thresholdSummary.thresholds)

    tau = thresholdSummary.threshold(t).tau;
    rec = thresholdSummary.threshold(t).severeRecallMean;
    fnr = thresholdSummary.threshold(t).severeFNRMean;
    far = thresholdSummary.threshold(t).falseAlarmMean;

    [avgCost, totalCost, costMatrix] = asymmetric_confusion_cost(thresholdSummary.threshold(t).Csum, 3, 1);

    % disp(costMatrix)
    %fprintf('Average asymmetric confusion cost: %.4f\n', avgCost);

    fprintf('%8.2f   %13.3f   %10.3f   %16.3f %16.3f\n', tau, rec, fnr, far,avgCost);

end
% %% Confusion costs
% C = confusionmat(Ytrue,Ypred,'Order',categorical(classes));


%% FUNCTIONS

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

function foldMetrics = compute_fold_metrics(results)

    classes = results.classes;
    nClasses = numel(classes);
    nFolds = numel(results.fold);

    foldMetrics = struct();

    for i = 1:nFolds

        Ytrue = results.fold{i}.Ytrue;
        Ypred = results.fold{i}.Ypred;
        Scores = results.fold{i}.Scores;

        [C,~] = confusionmat(Ytrue,Ypred,'Order',categorical(classes));

        TP = diag(C);
        FP = sum(C,1)' - TP;
        FN = sum(C,2) - TP;
        TN = sum(C,'all') - TP - FP - FN;

        precision = TP ./ (TP + FP);
        recall    = TP ./ (TP + FN);
        f1        = 2 .* precision .* recall ./ (precision + recall);

        % Handle undefined precision/F1
        precision(isnan(precision)) = 0;
        recall(isnan(recall)) = 0;
        f1(isnan(f1)) = 0;

        perClassAccuracy = (TP + TN) ./ sum(C,'all');

        overallAccuracy = sum(TP) / sum(C,'all');
        balancedAccuracy = mean(recall);
        macroF1 = mean(f1);

        auc = nan(nClasses,1);

        for c = 1:nClasses
            binaryTrue = double(Ytrue == categorical(classes(c)));
            classScore = Scores(:,c);

            try
                [~,~,~,auc(c)] = perfcurve(binaryTrue,classScore,1);
            catch
                auc(c) = NaN;
            end
        end

        foldMetrics(i).repeat = results.fold{i}.repeat;
        foldMetrics(i).fold = results.fold{i}.fold;
        foldMetrics(i).confusionMatrix = C;
        foldMetrics(i).perClassAccuracy = perClassAccuracy;
        foldMetrics(i).precision = precision;
        foldMetrics(i).recall = recall;
        foldMetrics(i).f1 = f1;
        foldMetrics(i).overallAccuracy = overallAccuracy;
        foldMetrics(i).balancedAccuracy = balancedAccuracy;
        foldMetrics(i).macroF1 = macroF1;
        foldMetrics(i).auc = auc;
    end
end

function rocSummary = compute_average_roc(results, nGrid)

    if nargin < 2
        nGrid = 101;
    end

    classes = results.classes;
    nClasses = numel(classes);
    nFolds = numel(results.fold);

    fprGrid = linspace(0,1,nGrid);

    rocSummary.classes = classes;
    rocSummary.fprGrid = fprGrid;

    for c = 1:nClasses

        tprAll = nan(nFolds,nGrid);
        aucAll = nan(nFolds,1);

        for i = 1:nFolds

            Ytrue = results.fold{i}.Ytrue;
            Scores = results.fold{i}.Scores;

            binaryTrue = double(Ytrue == categorical(classes(c)));
            classScore = Scores(:,c);

            try
                [fpr,tpr,~,auc] = perfcurve(binaryTrue,classScore,1);

                % Remove duplicate FPR values for interpolation
                [fprUnique,ia] = unique(fpr);
                tprUnique = tpr(ia);

                tprInterp = interp1(fprUnique,tprUnique,fprGrid, ...
                    'linear','extrap');

                tprInterp(tprInterp < 0) = 0;
                tprInterp(tprInterp > 1) = 1;

                tprAll(i,:) = tprInterp;
                aucAll(i) = auc;

            catch
                % Leave as NaN if class unavailable in a fold
            end
        end

        validCounts = sum(~isnan(tprAll),1);
        meanTPR = mean(tprAll,1,'omitnan');
        stdTPR = std(tprAll,0,1,'omitnan');

        tcrit = tinv(0.975,max(validCounts-1,1));
        ciHalf = tcrit .* stdTPR ./ sqrt(validCounts);

        rocSummary.class(c).meanTPR = meanTPR;
        rocSummary.class(c).stdTPR = stdTPR;
        rocSummary.class(c).lower95 = max(0,meanTPR - ciHalf);
        rocSummary.class(c).upper95 = min(1,meanTPR + ciHalf);
        rocSummary.class(c).aucMean = mean(aucAll,'omitnan');
        rocSummary.class(c).aucStd = std(aucAll,0,'omitnan');
        rocSummary.class(c).aucAll = aucAll;
    end
end

function aucTable = make_auc_table(rocSummary)

    classes = rocSummary.classes;
    nClasses = numel(classes);

    aucMean = zeros(nClasses,1);
    aucStd  = zeros(nClasses,1);

    for c = 1:nClasses
        aucMean(c) = rocSummary.class(c).aucMean;
        aucStd(c)  = rocSummary.class(c).aucStd;
    end

    aucTable = table(classes(:), aucMean, aucStd, ...
        'VariableNames',{'Class','AUC_Mean','AUC_Std'});
end

function [macroAUC_mean, macroAUC_std, macroAUC_all] = compute_macro_auc(rocSummary)

    nClasses = numel(rocSummary.classes);
    nFolds = rocSummary.nFolds;

    aucMat = nan(nFolds,nClasses);

    for c = 1:nClasses
        aucMat(:,c) = rocSummary.class(c).aucAll;
    end

    macroAUC_all = mean(aucMat,2,'omitnan');

    macroAUC_mean = mean(macroAUC_all,'omitnan');
    macroAUC_std  = std(macroAUC_all,0,'omitnan');
end

function plot_average_roc(rocSummary)

    % Force class labels to be a string array
    classes = string(rocSummary.classes);
    fprGrid = rocSummary.fprGrid;
    nClasses = numel(classes);

    f = figure;
    f.Position = [50 50 900 700];
    hold on

    % Use MATLAB default color order
    colors = lines(nClasses);

    for c = 1:nClasses

        meanTPR = rocSummary.class(c).meanTPR;
        lower95 = rocSummary.class(c).lower95;
        upper95 = rocSummary.class(c).upper95;
        aucMean = rocSummary.class(c).aucMean;
        aucStd  = rocSummary.class(c).aucStd;

        % Make sure everything is a row vector
        fpr = fprGrid(:)';
        mu  = meanTPR(:)';
        lo  = lower95(:)';
        hi  = upper95(:)';

        % Shaded 95% confidence interval
        patch([fpr fliplr(fpr)], ...
              [lo  fliplr(hi)], ...
              colors(c,:), ...
              'FaceAlpha',0.15, ...
              'EdgeColor','none', ...
              'HandleVisibility','off');

        % Mean ROC curve
        plot(fpr,mu, ...
            'Color',colors(c,:), ...
            'LineWidth',2.0, ...
            'DisplayName',sprintf('Class %s, AUC = %.3f \\pm %.2f', ...
                char(classes(c)), aucMean, aucStd));
    end

    % Chance line
    plot([0 1],[0 1],'k--', ...
        'LineWidth',1.2, ...
        'DisplayName','Chance')

    xlabel('False positive rate')
    ylabel('True positive rate')
    title('One-vs-rest ROC curves')

    legend('Location','southeast')
    grid on
    box on

    g = gca;
    g.FontSize = 20;
    g.FontName = 'Helvetica';

    xlim([0 1])
    ylim([0 1])

end

function summary = summarize_metrics(foldMetrics, classes)

    nFolds = numel(foldMetrics);
    nClasses = numel(classes);

    overallAcc = zeros(nFolds,1);
    balAcc = zeros(nFolds,1);
    macroF1 = zeros(nFolds,1);

    perClassAcc = zeros(nFolds,nClasses);
    precision = zeros(nFolds,nClasses);
    recall = zeros(nFolds,nClasses);
    f1 = zeros(nFolds,nClasses);
    auc = zeros(nFolds,nClasses);

    confusionMatrices = zeros(nClasses,nClasses,nFolds);

    for i = 1:nFolds
        overallAcc(i) = foldMetrics(i).overallAccuracy;
        balAcc(i) = foldMetrics(i).balancedAccuracy;
        macroF1(i) = foldMetrics(i).macroF1;

        perClassAcc(i,:) = foldMetrics(i).perClassAccuracy;
        precision(i,:) = foldMetrics(i).precision;
        recall(i,:) = foldMetrics(i).recall;
        f1(i,:) = foldMetrics(i).f1;
        auc(i,:) = foldMetrics(i).auc;

        confusionMatrices(:,:,i) = foldMetrics(i).confusionMatrix;
    end

    summary.classes = classes;

    summary.overallAccuracy.mean = mean(overallAcc);
    summary.overallAccuracy.std = std(overallAcc);

    summary.balancedAccuracy.mean = mean(balAcc);
    summary.balancedAccuracy.std = std(balAcc);

    summary.macroF1.mean = mean(macroF1);
    summary.macroF1.std = std(macroF1);

    summary.perClassAccuracy.mean = mean(perClassAcc,1);
    summary.perClassAccuracy.std = std(perClassAcc,0,1);

    summary.precision.mean = mean(precision,1);
    summary.precision.std = std(precision,0,1);

    summary.recall.mean = mean(recall,1);
    summary.recall.std = std(recall,0,1);

    summary.f1.mean = mean(f1,1);
    summary.f1.std = std(f1,0,1);

    summary.auc.mean = mean(auc,1,'omitnan');
    summary.auc.std = std(auc,0,1,'omitnan');

    summary.confusionMatrix.mean = mean(confusionMatrices,3);
    summary.confusionMatrix.std = std(confusionMatrices,0,3);
end

function plot_aggregate_confusion(results)

    classes = results.classes;
    nFolds = numel(results.fold);

    Ytrue_all = categorical();
    Ypred_all = categorical();

    for i = 1:nFolds
        Ytrue_all = [Ytrue_all; results.fold{i}.Ytrue];
        Ypred_all = [Ypred_all; results.fold{i}.Ypred];
    end

    % Make sure class order is fixed
    Ytrue_all = categorical(Ytrue_all, classes);
    Ypred_all = categorical(Ypred_all, classes);

    % Plot normalized confusion matrix
    figure;
    
    cm = confusionchart(Ytrue_all,Ypred_all, ...
        'Normalization','row-normalized');

    cm.Title = 'Aggregate confusion matrix';
    cm.XLabel = 'Predicted erosion class';
    cm.YLabel = 'True erosion class';
    cm.FontName = 'Helvetica';
    cm.FontSize = 16;

end

function plot_confusion_imagec(results)

    classes = results.classes;
    nFolds = numel(results.fold);

    Ytrue_all = categorical();
    Ypred_all = categorical();

    for i = 1:nFolds
        Ytrue_all = [Ytrue_all; results.fold{i}.Ytrue];
        Ypred_all = [Ypred_all; results.fold{i}.Ypred];
    end

    % Make sure class order is fixed
    Ytrue_all = categorical(Ytrue_all, classes);
    Ypred_all = categorical(Ypred_all, classes);

    C = confusionmat(Ytrue_all, Ypred_all, ...
    'Order', categorical(classes));

    C_norm = C ./ sum(C,2);
    C_norm(isnan(C_norm)) = 0;

    figure;
    f = gcf;
    f.Position = [100 100 700 700];
    
    imagesc(C_norm)
    axis square
    colorbar
    
    xticks(1:numel(classes))
    yticks(1:numel(classes))
    xticklabels(string(classes))
    yticklabels(string(classes))
    
    xlabel('Predicted Class')
    ylabel('True Class')
    title('Confusion Matrix')
    
    g = gca;
    g.FontName = 'Helvetica';
    g.FontSize = 16;
    g.TickLabelInterpreter = 'none';
    
    % Add cell labels
    for i = 1:size(C,1)
        for j = 1:size(C,2)
            text(j,i,sprintf('%.2f',C(i,j)), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',14, ...
                'FontWeight','bold');
        end
    end
end

function [Cmean,Cstd,Call] = average_confusion_matrix(results)

    classes = results.classes;
    nClasses = numel(classes);
    nFolds = numel(results.fold);

    Call = zeros(nClasses,nClasses,nFolds);

    for i = 1:nFolds

        Ytrue = categorical(results.fold{i}.Ytrue, classes);
        Ypred = categorical(results.fold{i}.Ypred, classes);

        C = confusionmat(Ytrue,Ypred,'Order',categorical(classes));

        % Row-normalize so rows represent per-class recall behavior
        C = C ./ sum(C,2);

        % Handle any empty rows
        C(isnan(C)) = 0;

        Call(:,:,i) = C;
    end

    Cmean = mean(Call,3);
    Cstd  = std(Call,0,3);
end

function plot_mean_std_confusion(results)

    [Cmean,Cstd] = average_confusion_matrix(results);
    validCounts  = numel(results.fold);

    classes = string(results.classes);
    nClasses = numel(classes);

    figure;
    imagesc(Cmean)
    axis equal tight
    colorbar

    colormap(parula)

    xticks(1:nClasses)
    yticks(1:nClasses)
    xticklabels(classes)
    yticklabels(classes)

    xlabel('Predicted erosion class')
    ylabel('True erosion class')
    title('Mean normalized confusion matrix')

    g = gca;
    g.FontName = 'Helvetica';
    g.FontSize = 16;
    g.TickLabelInterpreter = 'none';

    % Add mean ± std labels
    for i = 1:nClasses
        for j = 1:nClasses
            %tcrit = tinv(0.975,max(validCounts-1,1))/sqrt(validCounts);
            % label = sprintf('%.2f\n\\pm %.2f', Cmean(i,j), tcrit * Cstd(i,j));
            label = sprintf('%.2f\n\\pm %.2f', Cmean(i,j), Cstd(i,j));

            text(j,i,label, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',13, ...
                'FontWeight','bold', ...
                'Color','k');
        end
    end
end

function badCases = find_bad_predictions(results, data_original)

    classes = string(results.classes);
    nFolds = numel(results.fold);

    badCases = table();

    for i = 1:nFolds

        Ytrue = results.fold{i}.Ytrue;
        Ypred = results.fold{i}.Ypred;

        % Convert class labels to ordinal indices
        [~,true_idx] = ismember(string(Ytrue), classes);
        [~,pred_idx] = ismember(string(Ypred), classes);

        class_error = abs(pred_idx - true_idx);

        % Pull original row indices, if available
        if isfield(results.fold{i},'test_idx')
            original_idx = results.fold{i}.test_idx;
        else
            original_idx = (1:numel(Ytrue))';
        end

        T = table();
        T.repeat = repmat(results.fold{i}.repeat,numel(Ytrue),1);
        T.fold = repmat(results.fold{i}.fold,numel(Ytrue),1);
        T.original_idx = original_idx(:);
        T.true_class = Ytrue(:);
        T.predicted_class = Ypred(:);
        T.class_error = class_error(:);

        % Add prediction confidence if scores are available
        if isfield(results.fold{i},'Scores')
            Scores = results.fold{i}.Scores;
            T.predicted_score = max(Scores,[],2);
            T.true_class_score = zeros(numel(Ytrue),1);

            for j = 1:numel(Ytrue)
                ctrue = true_idx(j);
                if ctrue > 0
                    T.true_class_score(j) = Scores(j,ctrue);
                else
                    T.true_class_score(j) = NaN;
                end
            end
        end

        badCases = [badCases; T];
    end

    % Keep only incorrect predictions
    badCases = badCases(badCases.class_error > 0,:);

    % Sort by largest class error, then highest confidence
    if ismember('predicted_score',badCases.Properties.VariableNames)
        badCases = sortrows(badCases, ...
            {'class_error','predicted_score'}, ...
            {'descend','descend'});
    else
        badCases = sortrows(badCases,'class_error','descend');
    end

    % Attach original input/output data if original indices are valid
    if nargin > 1 && ~isempty(data_original)
        originalRows = data_original(badCases.original_idx,:);
        badCases = [badCases originalRows];
    end
end

function thresholdSummary = compute_severe_threshold_confusion(results, severeClasses, thresholds)

% severeClasses: classes treated as severe, e.g. ["4"] or ["3","4"]
% thresholds: values such as [0.5 0.4 0.3 0.2]

classes = results.classes;
nClasses = numel(classes);
nFolds = numel(results.fold);
nThresholds = numel(thresholds);

severeClasses = categorical(severeClasses);
severeIdx = ismember(categorical(classes), severeClasses);

thresholdSummary.classes = classes;
thresholdSummary.severeClasses = severeClasses;
thresholdSummary.thresholds = thresholds;

for t = 1:nThresholds

    tau = thresholds(t);

    Csum = zeros(nClasses,nClasses);
    severeRecallAll = nan(nFolds,1);
    severeFNRAll = nan(nFolds,1);
    falseAlarmAll = nan(nFolds,1);

    for i = 1:nFolds

        Ytrue = results.fold{i}.Ytrue;
        Scores = results.fold{i}.Scores;

        % Default multiclass prediction
        [~,idxDefault] = max(Scores,[],2);
        Ypred = categorical(classes(idxDefault));

        % Severe probability
        pSevere = sum(Scores(:,severeIdx),2);

        % Rows that trigger severe-damage alarm
        alarmRows = pSevere >= tau;

        % If alarm is triggered, assign the most likely severe class
        severeScoreSubset = Scores(alarmRows,severeIdx);
        severeClassList = classes(severeIdx);

        if any(alarmRows)
            [~,localIdx] = max(severeScoreSubset,[],2);
            Ypred(alarmRows) = categorical(severeClassList(localIdx));
        end

        % Fold confusion matrix
        C = confusionmat(Ytrue,Ypred,'Order',categorical(classes));
        Csum = Csum + C;

        % Severe-vs-not-severe diagnostics
        trueSevere = ismember(Ytrue,severeClasses);
        predSevere = ismember(Ypred,severeClasses);

        severeRecallAll(i) = sum(trueSevere & predSevere) / sum(trueSevere);
        severeFNRAll(i) = sum(trueSevere & ~predSevere) / sum(trueSevere);
        falseAlarmAll(i) = sum(~trueSevere & predSevere) / sum(~trueSevere);

    end

    % Row-normalized confusion matrix
    rowSums = sum(Csum,2);
    Cnorm = Csum ./ rowSums;

    thresholdSummary.threshold(t).tau = tau;
    thresholdSummary.threshold(t).Csum = Csum;
    thresholdSummary.threshold(t).Cnorm = Cnorm;

    thresholdSummary.threshold(t).severeRecallMean = mean(severeRecallAll,'omitnan');
    thresholdSummary.threshold(t).severeRecallStd = std(severeRecallAll,0,'omitnan');

    thresholdSummary.threshold(t).severeFNRMean = mean(severeFNRAll,'omitnan');
    thresholdSummary.threshold(t).severeFNRStd = std(severeFNRAll,0,'omitnan');

    thresholdSummary.threshold(t).falseAlarmMean = mean(falseAlarmAll,'omitnan');
    thresholdSummary.threshold(t).falseAlarmStd = std(falseAlarmAll,0,'omitnan');

    thresholdSummary.threshold(t).severeRecallAll = severeRecallAll;
    thresholdSummary.threshold(t).severeFNRAll = severeFNRAll;
    thresholdSummary.threshold(t).falseAlarmAll = falseAlarmAll;

end

end

function [avgCost, totalCost, costMatrix] = asymmetric_confusion_cost(C, underWeight, overWeight)
%ASYMMETRIC_CONFUSION_COST Compute weighted misclassification cost.
%
% Inputs:
%   C            Confusion matrix, rows = true classes, columns = predicted classes
%   underWeight  Penalty multiplier for underprediction, e.g. 2
%   overWeight   Penalty multiplier for overprediction, e.g. 1
%
% Outputs:
%   avgCost      Average cost per sample
%   totalCost    Total weighted confusion cost
%   costMatrix   Matrix of costs for each true/predicted class pair
%
% Assumes classes are ordered from least severe to most severe.

    if nargin < 2
        underWeight = 2;
    end

    if nargin < 3
        overWeight = 1;
    end

    nClasses = size(C,1);

    if size(C,1) ~= size(C,2)
        error('Confusion matrix must be square.');
    end

    costMatrix = zeros(nClasses,nClasses);

    for i = 1:nClasses          % true class
        for j = 1:nClasses      % predicted class

            classDistance = abs(i - j);

            if j < i
                % Predicted less damage than true damage
                costMatrix(i,j) = underWeight * classDistance;
            elseif j > i
                % Predicted more damage than true damage
                costMatrix(i,j) = overWeight * classDistance;
            else
                % Correct classification
                costMatrix(i,j) = 0;
            end

        end
    end

    totalCost = sum(C .* costMatrix, 'all');
    avgCost = totalCost / sum(C, 'all');

end