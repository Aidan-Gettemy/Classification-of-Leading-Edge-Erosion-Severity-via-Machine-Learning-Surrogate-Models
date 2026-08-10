%% Comparative Post Processing

clc;close;clear;

%% Step 1.) Load the Post-Processing Results

simulation_results = load('');
simulation_results = simulation_results.results_sim;

emulation_results = load('');
emulation_results = emulation_results.results_em;

% Emulator
metrics_em = compute_fold_metrics(emulation_results);

% Simulator
metrics_sim = compute_fold_metrics(simulation_results);

% Savename

%saveNom = 'TEST2_Results/em10000_vs_sim';

%% Step 2.a) Overall Table: Per Class Accuracy, Precision, Recall
classes = simulation_results.classes;

T_perclass_sim = make_per_class_table(metrics_sim, classes, "Simulator-trained");
T_perclass_emu = make_per_class_table(metrics_em, classes, "Emulator-trained");

T_perclass_all = [T_perclass_sim; T_perclass_emu];

disp(T_perclass_all)

writetable(T_perclass_all,[saveNom 'PerClassMetrics.csv'])

%% Step 3.) Overall Results: 
T_overall = make_overall_accuracy_table(metrics_sim, metrics_em);
disp(T_overall)

writetable(T_overall,[saveNom 'OverallAccuracy.csv'])

%% Step 4.) Balanced Accuracy and macro-F1, with paired differences

T_paired = make_paired_summary_table(metrics_sim, metrics_em);
disp(T_paired)

writetable(T_paired,[saveNom 'PairedBalancedAccuracy_MacroF1.csv'])

%% Step 5.) Optional: per-class paired differences

T_perclass_diff = make_per_class_paired_difference_table( ...
    metrics_sim, metrics_em, classes);

disp(T_perclass_diff)

writetable(T_perclass_diff,[saveNom 'PerClassPairedDifferences.csv'])

%% Step 6.) ROC metrics
roc_sim = compute_average_roc(simulation_results, 101);
roc_emu = compute_average_roc(emulation_results, 101);

[T_class_auc, T_macro_auc] = compare_auc_paired(roc_sim, roc_emu, 0.05);

disp(T_class_auc)
disp(T_macro_auc)

writetable(T_class_auc,[saveNom 'PerClassPairedAUC.csv'])

writetable(T_macro_auc,[saveNom 'MarcoPairedAUC.csv'])

%% Functions


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

function out = mean_ci(x, alpha)

    if nargin < 2
        alpha = 0.05;
    end

    x = x(:);
    x = x(~isnan(x));

    n = numel(x);
    mu = mean(x);
    sd = std(x);

    if n > 1
        tcrit = tinv(1-alpha/2,n-1);
        halfWidth = tcrit * sd / sqrt(n);
    else
        halfWidth = NaN;
    end

    out.mean = mu;
    out.std = sd;
    out.n = n;
    out.CI_low = mu - halfWidth;
    out.CI_high = mu + halfWidth;
    out.halfWidth = halfWidth;
end

function T = make_per_class_table(metrics, classes, methodName)

    classes = string(classes);
    nClasses = numel(classes);
    nFolds = numel(metrics);

    perClassAccuracy = zeros(nFolds,nClasses);
    precision = zeros(nFolds,nClasses);
    recall = zeros(nFolds,nClasses);

    for i = 1:nFolds
        perClassAccuracy(i,:) = metrics(i).perClassAccuracy;
        precision(i,:) = metrics(i).precision;
        recall(i,:) = metrics(i).recall;
    end

    alpha = 0.05;

    classCol = strings(nClasses,1);
    methodCol = strings(nClasses,1);

    accMean = zeros(nClasses,1);
    accLow  = zeros(nClasses,1);
    accHigh = zeros(nClasses,1);

    precMean = zeros(nClasses,1);
    precLow  = zeros(nClasses,1);
    precHigh = zeros(nClasses,1);

    recMean = zeros(nClasses,1);
    recLow  = zeros(nClasses,1);
    recHigh = zeros(nClasses,1);

    for c = 1:nClasses

        accStats = mean_ci(perClassAccuracy(:,c),alpha);
        preStats = mean_ci(precision(:,c),alpha);
        recStats = mean_ci(recall(:,c),alpha);

        classCol(c) = classes(c);
        methodCol(c) = methodName;

        accMean(c) = accStats.mean;
        accLow(c)  = accStats.CI_low;
        accHigh(c) = accStats.CI_high;

        precMean(c) = preStats.mean;
        precLow(c)  = preStats.CI_low;
        precHigh(c) = preStats.CI_high;

        recMean(c) = recStats.mean;
        recLow(c)  = recStats.CI_low;
        recHigh(c) = recStats.CI_high;
    end

    T = table(methodCol, classCol, ...
        accMean, accLow, accHigh, ...
        precMean, precLow, precHigh, ...
        recMean, recLow, recHigh, ...
        'VariableNames', { ...
        'Method','Class', ...
        'Accuracy_Mean','Accuracy_CI_Low','Accuracy_CI_High', ...
        'Precision_Mean','Precision_CI_Low','Precision_CI_High', ...
        'Recall_Mean','Recall_CI_Low','Recall_CI_High'});
end

function T = make_per_class_comparison_table(metricsA, metricsB, classes, methodAName, methodBName)

    classes = string(classes);
    nClasses = numel(classes);
    nFolds = numel(metricsA);

    if numel(metricsB) ~= nFolds
        error('metricsA and metricsB must have the same number of folds.');
    end

    alpha = 0.05;

    metricFields = ["perClassAccuracy", "precision", "recall"];
    metricLabels = ["Accuracy", "Precision", "Recall"];

    nMetrics = numel(metricFields);
    nRows = nClasses * nMetrics;

    MethodA = strings(nRows,1);
    MethodB = strings(nRows,1);
    Class = strings(nRows,1);
    Metric = strings(nRows,1);

    A_Mean = zeros(nRows,1);
    A_Std  = zeros(nRows,1);
    A_CI_Low  = zeros(nRows,1);
    A_CI_High = zeros(nRows,1);

    B_Mean = zeros(nRows,1);
    B_Std  = zeros(nRows,1);
    B_CI_Low  = zeros(nRows,1);
    B_CI_High = zeros(nRows,1);

    Difference_Mean = zeros(nRows,1);
    Difference_Std  = zeros(nRows,1);
    Difference_CI_Low  = zeros(nRows,1);
    Difference_CI_High = zeros(nRows,1);

    ZScore = zeros(nRows,1);
    PairedT = zeros(nRows,1);
    PValue = zeros(nRows,1);
    N = zeros(nRows,1);

    row = 1;

    for m = 1:nMetrics

        field = metricFields(m);
        label = metricLabels(m);

        for c = 1:nClasses

            valsA = zeros(nFolds,1);
            valsB = zeros(nFolds,1);

            for i = 1:nFolds
                valsA(i) = metricsA(i).(field)(c);
                valsB(i) = metricsB(i).(field)(c);
            end

            % Remove folds where either method is NaN
            valid = ~isnan(valsA) & ~isnan(valsB);
            valsA = valsA(valid);
            valsB = valsB(valid);

            d = valsB - valsA;

            statsA = mean_ci(valsA, alpha);
            statsB = mean_ci(valsB, alpha);
            statsD = mean_ci(d, alpha);

            n = numel(d);
            sd_d = std(d);

            if n > 1 && sd_d > 0
                % Standardized mean difference
                zscore = mean(d) / sd_d;

                % Paired t-statistic
                pairedT = mean(d) / (sd_d / sqrt(n));

                % Two-sided paired t-test p-value
                pval = 2 * (1 - tcdf(abs(pairedT), n-1));
            else
                zscore = NaN;
                pairedT = NaN;
                pval = NaN;
            end

            MethodA(row) = methodAName;
            MethodB(row) = methodBName;
            Class(row) = classes(c);
            Metric(row) = label;

            A_Mean(row) = statsA.mean;
            A_Std(row)  = statsA.std;
            A_CI_Low(row)  = statsA.CI_low;
            A_CI_High(row) = statsA.CI_high;

            B_Mean(row) = statsB.mean;
            B_Std(row)  = statsB.std;
            B_CI_Low(row)  = statsB.CI_low;
            B_CI_High(row) = statsB.CI_high;

            Difference_Mean(row) = statsD.mean;
            Difference_Std(row)  = statsD.std;
            Difference_CI_Low(row)  = statsD.CI_low;
            Difference_CI_High(row) = statsD.CI_high;

            ZScore(row) = zscore;
            PairedT(row) = pairedT;
            PValue(row) = pval;
            N(row) = n;

            row = row + 1;
        end
    end

    T = table(MethodA, MethodB, Class, Metric, ...
        A_Mean, A_Std, A_CI_Low, A_CI_High, ...
        B_Mean, B_Std, B_CI_Low, B_CI_High, ...
        Difference_Mean, Difference_Std, ...
        Difference_CI_Low, Difference_CI_High, ...
        ZScore, PairedT, PValue, N);
end

function T = make_overall_accuracy_table(metrics_sim, metrics_emu)

    simAcc = [metrics_sim.overallAccuracy]';
    emuAcc = [metrics_emu.overallAccuracy]';

    simStats = mean_ci(simAcc,0.05);
    emuStats = mean_ci(emuAcc,0.05);

    Method = ["Simulator-trained"; "Emulator-trained"];

    Accuracy_Mean = [simStats.mean; emuStats.mean];
    Accuracy_Std  = [simStats.std;  emuStats.std];
    Accuracy_CI_Low  = [simStats.CI_low;  emuStats.CI_low];
    Accuracy_CI_High = [simStats.CI_high; emuStats.CI_high];

    T = table(Method, Accuracy_Mean, Accuracy_Std, ...
        Accuracy_CI_Low, Accuracy_CI_High);
end

function T = make_paired_summary_table(metrics_sim, metrics_emu)

    metricNames = ["balancedAccuracy", "macroF1"];
    displayNames = ["Balanced accuracy", "Macro-F1"];

    nMetrics = numel(metricNames);

    Metric = strings(nMetrics,1);

    Sim_Mean = zeros(nMetrics,1);
    Sim_Std  = zeros(nMetrics,1);

    Emu_Mean = zeros(nMetrics,1);
    Emu_Std  = zeros(nMetrics,1);

    Difference_Mean = zeros(nMetrics,1);
    Difference_CI_Low = zeros(nMetrics,1);
    Difference_CI_High = zeros(nMetrics,1);
    Difference_Std = zeros(nMetrics,1);
    ZScore = zeros(nMetrics,1);
    PairedT = zeros(nMetrics,1);
    PValue = zeros(nMetrics,1);

    alpha = 0.05;

    for m = 1:nMetrics

        field = metricNames(m);

        simVals = zeros(numel(metrics_sim),1);
        emuVals = zeros(numel(metrics_emu),1);

        for i = 1:numel(metrics_sim)
            simVals(i) = metrics_sim(i).(field);
            emuVals(i) = metrics_emu(i).(field);
        end

        simStats = mean_ci(simVals,alpha);
        emuStats = mean_ci(emuVals,alpha);

        d = emuVals - simVals;
        dStats = mean_ci(d,alpha);

        n = numel(d);
        sd_d = std(d);

        % Standardized mean difference
        zscore = mean(d) / sd_d;

        % Paired t-statistic
        pairedT = mean(d) / (sd_d / sqrt(n));
        pval = 2 * (1 - tcdf(abs(pairedT), n-1));

        Metric(m) = displayNames(m);

        Sim_Mean(m) = simStats.mean;
        Sim_Std(m)  = simStats.std;

        Emu_Mean(m) = emuStats.mean;
        Emu_Std(m)  = emuStats.std;

        Difference_Mean(m) = dStats.mean;
        Difference_CI_Low(m) = dStats.CI_low;
        Difference_CI_High(m) = dStats.CI_high;
        Difference_Std(m) = dStats.std;

        ZScore(m) = zscore;
        PairedT(m) = pairedT;
        PValue(m) = pval;
    end

    T = table(Metric, ...
        Sim_Mean, Sim_Std, ...
        Emu_Mean, Emu_Std, ...
        Difference_Mean, Difference_Std, ...
        Difference_CI_Low, Difference_CI_High, ...
        ZScore, PairedT, PValue);
end

function T = make_per_class_paired_difference_table(metrics_sim, metrics_emu, classes)

    classes = string(classes);
    nClasses = numel(classes);
    nFolds = numel(metrics_sim);

    metricFields = ["perClassAccuracy", "precision", "recall"];
    metricLabels = ["Per-class accuracy", "Precision", "Recall"];

    rows = nClasses * numel(metricFields);

    Metric = strings(rows,1);
    Class = strings(rows,1);

    Difference_Mean = zeros(rows,1);
    Difference_Std = zeros(rows,1);
    Difference_CI_Low = zeros(rows,1);
    Difference_CI_High = zeros(rows,1);
    ZScore = zeros(rows,1);
    PairedT = zeros(rows,1);
    PValue = zeros(rows,1);

    alpha = 0.05;
    row = 1;

    for m = 1:numel(metricFields)

        field = metricFields(m);

        for c = 1:nClasses

            simVals = zeros(nFolds,1);
            emuVals = zeros(nFolds,1);

            for i = 1:nFolds
                simVals(i) = metrics_sim(i).(field)(c);
                emuVals(i) = metrics_emu(i).(field)(c);
            end

            d = emuVals - simVals;
            dStats = mean_ci(d,alpha);

            n = numel(d);
            sd_d = std(d);

            zscore = mean(d) / sd_d;
            pairedT = mean(d) / (sd_d / sqrt(n));
            pval = 2 * (1 - tcdf(abs(pairedT), n-1));

            Metric(row) = metricLabels(m);
            Class(row) = classes(c);

            Difference_Mean(row) = dStats.mean;
            Difference_Std(row) = dStats.std;
            Difference_CI_Low(row) = dStats.CI_low;
            Difference_CI_High(row) = dStats.CI_high;
            ZScore(row) = zscore;
            PairedT(row) = pairedT;
            PValue(row) = pval;

            row = row + 1;
        end
    end

    T = table(Metric, Class, ...
        Difference_Mean, Difference_Std, ...
        Difference_CI_Low, Difference_CI_High, ...
        ZScore, PairedT, PValue);
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

function [T_class_auc, T_macro_auc] = compare_auc_paired(roc_sim, roc_emu, alpha)

    if nargin < 3
        alpha = 0.05;
    end

    classes = string(roc_sim.classes);
    nClasses = numel(classes);

    % ------------------------------------------------------------
    % Class-wise paired AUC comparison
    % ------------------------------------------------------------

    Class = strings(nClasses,1);

    Sim_AUC_Mean = zeros(nClasses,1);
    Sim_AUC_Std  = zeros(nClasses,1);

    Emu_AUC_Mean = zeros(nClasses,1);
    Emu_AUC_Std  = zeros(nClasses,1);

    Difference_Mean = zeros(nClasses,1);
    Difference_Std  = zeros(nClasses,1);
    Difference_CI_Low  = zeros(nClasses,1);
    Difference_CI_High = zeros(nClasses,1);

    ZScore = zeros(nClasses,1);
    PairedT = zeros(nClasses,1);
    PValue = zeros(nClasses,1);
    N = zeros(nClasses,1);

    for c = 1:nClasses

        auc_sim = roc_sim.class(c).aucAll(:);
        auc_emu = roc_emu.class(c).aucAll(:);

        valid = ~isnan(auc_sim) & ~isnan(auc_emu);

        auc_sim = auc_sim(valid);
        auc_emu = auc_emu(valid);

        d = auc_emu - auc_sim;

        n = numel(d);
        dbar = mean(d);
        sd_d = std(d);

        if n > 1 && sd_d > 0
            tcrit = tinv(1-alpha/2,n-1);
            halfWidth = tcrit * sd_d / sqrt(n);

            zscore = dbar / sd_d;
            pairedT = dbar / (sd_d / sqrt(n));
            pval = 2 * (1 - tcdf(abs(pairedT),n-1));
        else
            halfWidth = NaN;
            zscore = NaN;
            pairedT = NaN;
            pval = NaN;
        end

        Class(c) = classes(c);

        Sim_AUC_Mean(c) = mean(auc_sim,'omitnan');
        Sim_AUC_Std(c)  = std(auc_sim,0,'omitnan');

        Emu_AUC_Mean(c) = mean(auc_emu,'omitnan');
        Emu_AUC_Std(c)  = std(auc_emu,0,'omitnan');

        Difference_Mean(c) = dbar;
        Difference_Std(c)  = sd_d;
        Difference_CI_Low(c)  = dbar - halfWidth;
        Difference_CI_High(c) = dbar + halfWidth;

        ZScore(c) = zscore;
        PairedT(c) = pairedT;
        PValue(c) = pval;
        N(c) = n;
    end

    T_class_auc = table(Class, ...
        Sim_AUC_Mean, Sim_AUC_Std, ...
        Emu_AUC_Mean, Emu_AUC_Std, ...
        Difference_Mean, Difference_Std, ...
        Difference_CI_Low, Difference_CI_High, ...
        ZScore, PairedT, PValue, N);

    % ------------------------------------------------------------
    % Macro-average AUC paired comparison
    % ------------------------------------------------------------

    % Assemble fold x class AUC matrices
    nFolds = numel(roc_sim.class(1).aucAll);

    aucMat_sim = nan(nFolds,nClasses);
    aucMat_emu = nan(nFolds,nClasses);

    for c = 1:nClasses
        aucMat_sim(:,c) = roc_sim.class(c).aucAll(:);
        aucMat_emu(:,c) = roc_emu.class(c).aucAll(:);
    end

    % Macro-average AUC within each fold
    macro_auc_sim = mean(aucMat_sim,2,'omitnan');
    macro_auc_emu = mean(aucMat_emu,2,'omitnan');

    valid = ~isnan(macro_auc_sim) & ~isnan(macro_auc_emu);

    macro_auc_sim = macro_auc_sim(valid);
    macro_auc_emu = macro_auc_emu(valid);

    d = macro_auc_emu - macro_auc_sim;

    n = numel(d);
    dbar = mean(d);
    sd_d = std(d);

    if n > 1 && sd_d > 0
        tcrit = tinv(1-alpha/2,n-1);
        halfWidth = tcrit * sd_d / sqrt(n);

        zscore = dbar / sd_d;
        pairedT = dbar / (sd_d / sqrt(n));
        pval = 2 * (1 - tcdf(abs(pairedT),n-1));
    else
        halfWidth = NaN;
        zscore = NaN;
        pairedT = NaN;
        pval = NaN;
    end

    Metric = "Macro-average AUC";

    Sim_Mean = mean(macro_auc_sim,'omitnan');
    Sim_Std  = std(macro_auc_sim,0,'omitnan');

    Emu_Mean = mean(macro_auc_emu,'omitnan');
    Emu_Std  = std(macro_auc_emu,0,'omitnan');

    Difference_Mean = dbar;
    Difference_Std = sd_d;
    Difference_CI_Low = dbar - halfWidth;
    Difference_CI_High = dbar + halfWidth;
    ZScore = zscore;
    PairedT = pairedT;
    PValue = pval;
    N = n;

    T_macro_auc = table(Metric, ...
        Sim_Mean, Sim_Std, ...
        Emu_Mean, Emu_Std, ...
        Difference_Mean, Difference_Std, ...
        Difference_CI_Low, Difference_CI_High, ...
        ZScore, PairedT, PValue, N);
end