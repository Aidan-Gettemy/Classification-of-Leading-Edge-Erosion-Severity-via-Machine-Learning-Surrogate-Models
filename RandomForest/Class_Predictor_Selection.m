%% Random Forest Classification
clc;close all;clear;

%% Step 1.) Load data

option = 'A'; % 'B', 'C'


% Load dataset
% Select list of potential training inputs/predictors
switch option

    case 'A'

        suffixes = {"mean","sd","skew","kurt"};
        dataID = "../Data/Exp2/LARGE2ExperimentResultTable1_500.txt";
        names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};
    case 'B'

        suffixes = {"mean","sd","skew","kurt"};
        dataID = "../Data/Exp10/LARGE2noisyExperimentResultTable1_500.txt";
        names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};
    case 'C'
        
        suffixes = {"mean","sd","skew","kurt","rms","nfd","bp1","bp3p","l1d","l1ac"};
        dataID = "../Data/Exp10/LARGE3ExperimentResultTable1_500.txt";
        names = {"TipALxb1","RootMxb1","RootFyb1","RootMzc1","TipALzb1",...
            "TwrBsMyt","TwrBsMxt","LSSTipMzs","LSSTipMys",...
            "RootFzc1",...
            "RtSpeed","TwrBsMyt","GenPwr"};
end


data_original = readtable(dataID);

%% Step 2.) Specify RF training parameters 

varnames = predictor_list(suffixes, names);

%% Step 3.a) Train the model

% Ready the output to be predicted
Out = categorical(data_original(:,"Alpha").Variables);
% Set the input data
In = data_original(:,varnames);

In_train = In;
Out_train = Out;

%% Step 3.bi) Set up Repeated k-fold cross validation
% Repeated k-fold predictor importance
k_folds = 5;
repeats = 10;

rng(1)  % for reproducibility
predictorNames = varnames;
n = size(In_train,1);
InNames = In.Properties.VariableNames;
OutName = 'Alpha';
p = numel(InNames);
% For case 3 with a huge number of predictors initially, 
% set maxIter greater than one to repeat the screening 
% until a reasonable number of predictors are identified
% Check that prediction does not deteriorate on the reduced set.
% Stop when this occurs.
maxIter = 1;
storage = zeros(maxIter,2);
for t = 1:maxIter
    storage(t,1) = p;
    fprintf('Round %d \n',t)
    [meanimps, stdimps, YTRUE, YPRED,acc] = runPredictorRank(k_folds,...
     repeats,p,n,Out_train,In_train,InNames,OutName);
    % Step 3.b.ii) Sort
    storage(t,2) = acc;
    [sorted_imp,idx] = sort(meanimps,'descend');
    sorted_std = stdimps(idx);
    energy=cumsum(sorted_imp)./sum(sorted_imp);
    [ie, ig] = find(energy>0.85);
    nvars = min(ig);
    if t<maxIter
        predictorNames = predictorNames(idx(1:nvars));
        InNames = predictorNames;p = numel(InNames);
    end
end

%% Step 3.c) Investigate preliminary confusion matrix
ytrue_all = YTRUE(:);
ypred_all = YPRED(:);

cm = confusionchart(ytrue_all, ypred_all);
cm.Normalization = 'row-normalized';
cm.Title = 'Row-Normalized Confusion Matrix';
cm.XLabel = 'Predicted Class';
cm.YLabel = 'True Class';
%% Step 4.) Make a plot of the predictor importances

% Number of predictors to display
n_top = 14;

% Sort importances
[sorted_imp,idx] = sort(meanimps,'descend');
sorted_std = stdimps(idx);
figure;energy=cumsum(sorted_imp)./sum(sorted_imp);
plot(energy)
hold on
yline(0.85)
[ie, ig] = find(energy>0.85);
lower_x = min(ig);
xline(lower_x)
text(lower_x,0.85,num2str(lower_x))
top_idx = idx(1:n_top);
top_imp = sorted_imp(1:n_top);
top_std = sorted_std(1:n_top);

% Convert internal predictor names to readable labels
top_names = makeReadablePredictorNames(InNames(top_idx));

% Reverse order so most important appears at top
top_imp   = flip(top_imp);
top_std   = flip(top_std);
top_names = flip(top_names);
readable_names = top_names;

% Plot
f = figure;
f.Position = [50 50 883 650];

y = 1:n_top;

hold on

% Light horizontal bars for importance
barh(y,top_imp, ...
    'FaceAlpha',0.25, ...
    'EdgeColor','none');

% Error bars
errorbar(top_imp,y,top_std, ...
    'horizontal', ...
    'o', ...
    'LineWidth',1.5, ...
    'MarkerSize',7, ...
    'MarkerFaceColor','auto', ...
    'CapSize',8);

% yticks(y)
% yticklabels(top_names)

yticks(1:numel(readable_names))
ax = gca;
yticklabels(ax,cellstr(readable_names))
ax = gca;

% Store current y tick positions
yt = ax.YTick;

% Hide default y tick labels
ax.YTickLabel = [];

% Get x limits so we know where to place labels
xl = ax.XLim;

% Put labels slightly to the left of the plotting area
x_text = xl(1) - 0.02 * range(xl);

g = gca;
g.FontSize = 18;

for i = 1:numel(yt)
    text(x_text, yt(i), readable_names(i), ...
        'Interpreter','latex', ...
        'HorizontalAlignment','right', ...
        'VerticalAlignment','middle', ...
        'FontSize', ax.FontSize);
end

% Make room on the left for the manual labels
ax.Position(1) = ax.Position(1) + 0.01;
ax.Position(3) = ax.Position(3) - 0.01;

ax.TickLabelInterpreter = 'latex';

xlabel('Predictor importance score')
ylabel('')

grid on
box on


%yline(2.5, 'r', 'LineWidth',3,'LineStyle',':')
ax = gca;
hold on

yl = ylim;
xl = xlim;

y_trunc = 2.5;   % change this to your truncation threshold

% Filled patch below truncation line
patch([xl(1) xl(2) xl(2) xl(1)], ...
      [yl(1) yl(1) y_trunc y_trunc], ...
      [0.8 0.8 0.8], ...
      'FaceAlpha',0.25, ...
      'EdgeColor','none', ...
      'HandleVisibility','off');

% Plot truncation line
yline(y_trunc,'--k','Truncation limit', ...
    'LineWidth',1.2, ...
    'LabelHorizontalAlignment','center', ...
    'HandleVisibility','off','FontSize',18);

% Send patch to back
uistack(findobj(ax,'Type','patch'),'bottom')

g = gca;
g.FontSize = 18;
g.FontName = 'Helvetica';
g.TickLabelInterpreter = 'none';
g.YDir = 'normal';
g.XGrid = 'on';
g.YGrid = 'off';

ylim([0.5 n_top+0.5])

% Add rank labels on the left if desired
rank_labels = string(n_top:-1:1);
% Optional: remove ylabel if predictor names are enough
% ylabel('')

set(f,'Color','w')

%% Step 5.) Test with reduced predictors
k_folds = 5;
repeats = 10;nvars = 14;

[sorted_imp,isorted_imp] = sort(meanimps,'descend');
predictor_ranking = isorted_imp;
predictorNames = InNames(isorted_imp(1:nvars));

rng(1)  % for reproducibility

n = size(In_train,1);
p = size(In_train,2);YPRED = zeros(k_folds*repeats,n*(1/k_folds));
YTRUE = zeros(k_folds*repeats,n*(1/k_folds));

iter = 1;

for r = 1:repeats

    % New random 5-fold split for each repeat
    cvp = cvpartition(Out_train,'KFold',k_folds);

    for k = 1:k_folds
        fprintf('Starting Iteration %16d: Fold %d Repeat %d\n ',iter,r,k)
        train_idx = training(cvp,k);
        test_idx  = test(cvp,k);

        Xtr = In_train(train_idx,:);
        Ytr = Out_train(train_idx);

        Xte = In_train(test_idx,:);
        Yte = Out_train(test_idx);

        Mdl = fitcensemble(Xtr,Ytr,'PredictorNames',...
            predictorNames,'ResponseName',OutName);

        % Store predictor importance
        % all_imps(iter,:) = predictorImportance(Mdl);

        % Optional: store fold accuracy
        Ypred = predict(Mdl,Xte);
        all_acc(iter) = mean(Ypred == Yte);
        YPRED(iter,:) = Ypred;
        YTRUE(iter,:) = Yte;

        iter = iter + 1;
    end
end

% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, k_folds*repeats - 1);

fprintf('Mean repeated-CV accuracy: %.3f ± %.3f\n', ...
    mean(all_acc), tcrit * std(all_acc)./sqrt(k_folds*repeats));
%% Step 6.) Confusion
ytrue_all = YTRUE(:);
ypred_all = YPRED(:);

cm = confusionchart(ytrue_all, ypred_all);
cm.Normalization = 'row-normalized';
cm.Title = 'Row-Normalized Confusion Matrix';
cm.XLabel = 'Predicted Class';
cm.YLabel = 'True Class';
%% Step 6.b) Check the distribution of these predictors
% Check the distribution of the important predictors
for nom = 1:14
figure;
vals = data_original(:,predictorNames{nom}).Variables;
histogram(vals, 'Normalization', 'probability');
xlabel(predictorNames{nom});
ylabel('Probability');
title(sprintf('min%.3f max %.3f',min(vals),max(vals)));
grid on;
end
%% Step 7.) Save the Important Predictors

[sorted_imp,isorted_imp] = sort(meanimps,'descend');
% isorted_imp has the index of the important predictors.  Save this
writematrix(isorted_imp,"Classification_imp_test1.txt")
% For the 3rd test, use this
% TARGET_SENSORS = InNames(isorted_imp(1:nvars));
% save("Classification_variables_test3.mat","TARGET_SENSORS");
%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

% function readable_names = makeReadablePredictorNames(raw_names)
% 
%     raw_names = string(raw_names);
%     readable_names = strings(size(raw_names));
% 
%     stat_suffixes = ["mean","sd","skew","kurt"];
% 
%     for i = 1:numel(raw_names)
% 
%         name = raw_names(i);
% 
%         % Identify statistic suffix
%         stat = "";
%         signal = name;
% 
%         for j = 1:numel(stat_suffixes)
%             suffix = stat_suffixes(j);
% 
%             if endsWith(name,suffix)
%                 stat = suffix;
%                 signal = extractBefore(name, strlength(name) - strlength(suffix) + 1);
%                 break
%             end
%         end
% 
%         % Convert signal names
%         switch signal
%             case "RootMxb1"
%                 signal_name = "Blade root moment";
%             case "TipALxb1"
%                 signal_name = "Blade tip acceleration";
%             case "B1N6Cl"
%                 signal_name = "Lift coefficient";
%             case "B1N6Cd"
%                 signal_name = "Drag coefficient";
%             case "GenPwr"
%                 signal_name = "Generator power";
%             case "WindDir"
%                 signal_name = "Wind direction";
%             case "WindSpeed"
%                 signal_name = "Wind speed";
%             case "AirDens"
%                 signal_name = "Air density";
%             case "GenTq"
%                 signal_name = "Generator torque";
%             case "HSShftV"
%                 signal_name = "High-speed shaft speed";
%             case "TipRDxb1"
%                 signal_name = "Blade tip x-deflection";
%             case "TipRDyb1"
%                 signal_name = "Blade tip y-deflection";
%             otherwise
%                 signal_name = signal;
%         end
% 
%         % Convert statistic names
%         switch stat
%             case "mean"
%                 stat_name = "$\\mu$";
%             case "sd"
%                 stat_name = "standard deviation";
%             case "skew"
%                 stat_name = "skewness";
%             case "kurt"
%                 stat_name = "kurtosis";
%             otherwise
%                 stat_name = "";
%         end
% 
%         % Combine signal and statistic
%         if stat_name ~= ""
%             readable_names(i) = sprintf('%s %s',signal_name,stat_name);
%         else
%             readable_names(i) = signal_name;
%         end
%     end
% end

function readable_names = makeReadablePredictorNames(raw_names)

    raw_names = string(raw_names);
    readable_names = strings(size(raw_names));

    stat_suffixes = ["mean","sd","skew","kurt"];

    for i = 1:numel(raw_names)

        name = raw_names(i);

        % Identify statistic suffix
        stat = "";
        signal = name;

        for j = 1:numel(stat_suffixes)
            suffix = stat_suffixes(j);

            if endsWith(name, suffix)
                stat = suffix;
                signal = extractBefore(name, strlength(name) - strlength(suffix) + 1);
                break
            end
        end

        % Convert signal names
        switch signal
            case "RootMxb1"
                signal_name = "M_{\mathrm{root}}";
            case {"TipALxb1","TipALxB1"}
                signal_name = "a_{\mathrm{tip}}";
            case "B1N6Cl"
                signal_name = "C_L";
            case "B1N6Cd"
                signal_name = "C_D";
            case "GenPwr"
                signal_name = "P_{\mathrm{gen}}";
            case "WindDir"
                signal_name = "Wind direction";
            case "WindSpeed"
                signal_name = "Wind speed";
            case "AirDens"
                signal_name = "Air density";
            case "GenTq"
                signal_name = "Generator torque";
            case "HSShftV"
                signal_name = "High-speed shaft speed";
            case "TipRDxb1"
                signal_name = "Blade tip x-deflection";
            case "TipRDyb1"
                signal_name = "Blade tip y-deflection";
            otherwise
                signal_name = char(signal);
        end
        % signal_name
        % Convert statistic names to LaTeX
        switch stat
            case "mean"
                stat_name = "\mu";
            case "sd"
                stat_name = "\sigma";
            case "skew"
                stat_name = "\gamma";
            case "kurt"
                stat_name = "\kappa";
            otherwise
                stat_name = "";
        end

        % Combine signal and statistic
        latex_signal = strrep(signal_name, " ", "\;");

        if stat_name ~= ""
            readable_names(i) = "$\mathrm{" + stat_name + "}$-$" + latex_signal + "$";
        else
            readable_names(i) = "$\mathrm{" + latex_signal + "}$";
        end
        % readable_names
    end
end

function [meanimps, stdimps,YTRUE,YPRED,acc] = runPredictorRank(k_folds,repeats,p,n,Out_train,In_train,InNames,OutName)
    all_imps = zeros(k_folds*repeats,p);
    all_acc  = zeros(k_folds*repeats,1);
    YPRED = zeros(k_folds*repeats,n*(1/k_folds));
    YTRUE = zeros(k_folds*repeats,n*(1/k_folds));
    
    iter = 1;
    rng(1)
    for r = 1:repeats
    
        % New random 5-fold split for each repeat
        cvp = cvpartition(Out_train,'KFold',k_folds);
    
        for k = 1:k_folds
            fprintf('Starting Iteration %16d: Fold %d Repeat %d\n ',iter,r,k)
            train_idx = training(cvp,k);
            test_idx  = test(cvp,k);
    
            Xtr = In_train(train_idx,:);
            Ytr = Out_train(train_idx);
    
            Xte = In_train(test_idx,:);
            Yte = Out_train(test_idx);
    
            Mdl = fitcensemble(Xtr,Ytr,'PredictorNames',...
                InNames,'ResponseName',OutName);
    
            % Store predictor importance
            all_imps(iter,:) = predictorImportance(Mdl);
    
            % Optional: store fold accuracy
            Ypred = predict(Mdl,Xte);
            all_acc(iter) = mean(Ypred == Yte);
            %fprintf('Accuracy %16d: Fold %d Repeat %d %.5f\n ',iter,r,k,mean(Ypred == Yte))
            YPRED(iter,:) = Ypred;
            YTRUE(iter,:) = Yte;
            iter = iter + 1;
        end
    end
    
    meanimps = mean(all_imps,1);
    stdimps  = std(all_imps,0,1);
    % critical value:
    alpha = 0.05;  % 95% CI
    tcrit = tinv(1 - alpha/2, k_folds*repeats - 1);
    acc = mean(all_acc);
    fprintf('Mean repeated-CV accuracy: %.3f ± %.3f\n', ...
        mean(all_acc), tcrit * std(all_acc)./sqrt(k_folds*repeats));

end
