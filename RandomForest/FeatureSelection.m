clc;close;clear;
%% Designate Folder for plot results
% Subfolder for plots
plotID = "Plots/";
mkdir Plots
%% Load in Data Inputs and Outputs 

DataId = "../Data/Exp2/LARGE2ExperimentResultTable500.txt";
Data = readtable(DataId);

% Ready the output to be predicted
Out = categorical(Data(:,"Alpha").Variables);

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

%% Set the input data
In = Data(:,varnames);
%% Test using K-Fold cross validation 

In_train = In;
Out_train = Out;

InNames = In.Properties.VariableNames;
OutName = 'Alpha';
%% Set up the Model/Train the Model
Mdl = fitcensemble(In_train,Out_train,'PredictorNames',...
    InNames,'ResponseName',OutName);
CVMdl = crossval(Mdl,'Kfold',10);
%% Asses the results of cross validation 
genError = kfoldLoss(CVMdl);

genPredict = kfoldPredict(CVMdl);

%% Save/Load the Model
%save("FitcensembleFeatSel.mat",'CVMdl');
% Load it back
load FitcensembleFeatSel.mat
%% Plot and Save as .png files
figure
cm = confusionchart(Out_train,genPredict);
cm.Title = 'FitcEnsemble: 10-fold cross validation';
cm.FontSize = 10;
%print('-dpng',plotID+"confusion_class.png")
savefig(plotID+"FeatSel_confusion_class.fig")

%% Predictor Importance
imps = zeros(10,numel(CVMdl.PredictorNames));
for i = 1:10
    imps(i,:) = predictorImportance(CVMdl.Trainable{i});
end
meanimps = mean(imps,1);
stdimps = std(imps,1);

suffixes = {" Mean"," Standard Deviation"," Skew"," Kurtosis"};
names = {"Blade Root Moment", "Blade Tip Acceleration",...
    "Coefficient of Lift", "Coefficient of Drag", "Generator Power"};

iter = 1;
for i = 1:numel(suffixes)
    for j = 1:numel(names)
        a = names{j} + suffixes{i};
        varnames(iter) = a;
        iter = iter + 1;
    end
end

others = {"Wind Direction","Wind Speed","Air Density"};
for i =1:numel(others)
    a = others{i};
    varnames(iter) = a;
    iter = iter +1;
end

[sorted_imp,isorted_imp] = sort(meanimps,'ascend');
stdimps = stdimps(isorted_imp);
f = figure;
f.Position = [50 50 1250 700];
hold on
for i=14:23
    plot(sorted_imp(i)+[-stdimps(i),stdimps(i)],[i-14,i-14],color='r',LineWidth=8)
    if i >15
    text(...
        1*meanimps(isorted_imp(i))+.001,i-14,...
        strrep(varnames{isorted_imp(i)},'_',''),...
        'FontSize',20,'FontWeight', 'bold', ...    % Make text bold
    'BackgroundColor', 'yellow', ... % Add background color
    'EdgeColor', 'black', ...    % Add border around text
    'Margin', 5,'FontName','Helvetica');                % Add padding around text ...
    else
        text(...
        1*meanimps(isorted_imp(i))+.001,i-14,...
        strrep(varnames{isorted_imp(i)},'_',''),...
        'FontSize',20,...
    'Margin', 5,'FontName','Helvetica');                % Add padding around text ...
    end
    
end
scatter(sorted_imp(14:23),0:23-14,180,'k','filled')

%title("Classification Inputs",'FontSize',18)
xlim([0,max(sorted_imp)*1.75])
ylim([-1,10])
xlabel("Importance Score","FontSize",20)
ylabel("Rank","FontSize",20)
g = gca();
g.XGrid  = 'on';
g.YTick = [-1:10];
g.YTickLabel = {'','10','9','8','7','6','5','4','3','2','1'};
g.XMinorGrid = 'on';
g.FontSize = 20;
g.FontName = 'Helvetica';

saveID = "Plots/PredictorImportance.pdf";
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)


%%
[sorted_imp,isorted_imp] = sort(meanimps,'descend');
% isorted_imp has the index of the important predictors.  Save this
writematrix(isorted_imp,"Classification_imp.txt")

figure;
barh(meanimps(isorted_imp(1:20)));hold on;grid on;
barh(meanimps(isorted_imp(1:5)),'y');
barh(meanimps(isorted_imp(1:3)),'r');
title('Predictor Importance Classification');
xlabel('Estimates with Curvature Tests');ylabel('Predictors');
set(gca,'FontSize',20);
set(gca,'TickDir','out');
set(gca,'LineWidth',2);
ax = gca;ax.YDir='reverse';ax.XScale = 'log';
xlim([0.0, meanimps(isorted_imp(1))*9])

% label the bars
for i=1:20 %length(Mdl.PredictorNames)
    text(...
        1.05*meanimps(isorted_imp(i)),i,...
        strrep(Mdl.PredictorNames{isorted_imp(i)},'_',''),...
        'FontSize',12 ...
    )
end

%print('-dpng',plotID+"Classification_input_importance_class.png")
savefig(plotID+"FeatSel_kfold_avgfeatimp.fig")
%% Try again on the smaller dataset
% Testing Percentage = 25%
p = 0.25;
cvpart = cvpartition(Out,'holdout',p);

In_train = In(training(cvpart),:);
Out_train = Out(training(cvpart),:);

In_test = In(test(cvpart),:);
Out_test = Out(test(cvpart),:);

Mdl = fitcensemble(In_train(:,isorted_imp(end-9:end)),Out_train,...
    'PredictorNames',InNames(isorted_imp(end-9:end)),...
    'ResponseName',OutName,...
    'OptimizeHyperparameters',{'NumLearningCycles','MaxNumSplits','LearnRate'}, ...
    'HyperparameterOptimizationOptions',struct('Repartition',true, ...
    'AcquisitionFunctionName','expected-improvement-plus')...
   );
%% Evaluate the Optimal-Input Model and save the stats
save("FitcensembleFeatSel_rducd.mat",'Mdl');
Out_predict = Mdl.predict(In_test(:,isorted_imp(end-9:end)));

%% Plot and Save as .png files
figure
cm = confusionchart(Out_test,Out_predict);
cm.Title = 'Erosion Class Detection (Reduced Input): FitcEnsemble';
cm.FontSize = 12;
savefig(plotID+"FeatSel_Rducd_confusion_class.fig")
%% ROC curve
[~,Scores] = Mdl.predict(In_test(:,isorted_imp(end-9:end)));
rocObj = rocmetrics(Out_test,Scores,Mdl.ClassNames);
plot(rocObj,AverageROCType="micro",Linewidth=3)
savefig(plotID+"FeatSel_Rducd_ROC.fig")