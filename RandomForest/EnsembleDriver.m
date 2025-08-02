clc;close;clear;
%% Designate Folder for plot results
% Subfolder for plots
plotID = "Plots/";
mkdir("Plots/")

%% Load in Data Inputs and Outputs 
% Load the testing data:
% Load the data 
testdataId = "../Data/Exp2/LARGE2ExperimentResultTable500.txt";
simdata = readtable(testdataId);
% Load the emulation data:
emdataId = "../PPGP_ROM/EmulationDataset.txt";
emdata = readtable(emdataId);
%%
% Grab the predictor names that we need

% Recall, they are the column names of the emdata 

predictornames = emdata.Properties.VariableNames(1:8);

Simulationdata = simdata(:,predictornames);
SimOutput = simdata.Alpha;
%% Now call a function which will give us the Training and Testing Data
% for holdout testing 
classes = 5;
Sim_samples = 100;
Em_samples = 1000;
percent = .15;
% Simulation 
[Sim_In_train,Sim_Out_train,Sim_In_test,Sim_Out_test] = class_split(classes,Sim_samples,percent,Simulationdata.Variables,SimOutput);
% Emulation 
[Em_In_train,Em_Out_train,Em_In_test,Em_Out_test] = class_split(classes,Em_samples,percent,emdata(:,[1:8]).Variables,emdata.Alpha);
%% Train the models

% Train one model on the Em Training Data
params = "auto";
Em_Mdl = fitcensemble(Em_In_train,Em_Out_train,...
    'OptimizeHyperparameters',params,...
    "HyperparameterOptimizationOptions", ...
    struct("AcquisitionFunctionName","expected-improvement-plus", ...
    "MaxObjectiveEvaluations",20));
%% Save Results
% Save Results
Em_Mdl_results.mdl = Em_Mdl;
Em_Mdl_results.Em_Out_test = Em_Out_test;
Em_Mdl_results.Em_In_test = Em_In_test;
Em_Mdl_results.Sim_Out_test = Sim_Out_test;
Em_Mdl_results.Sim_In_test = Sim_In_test;

save("Ensemble_Emulation_results.mat",'Em_Mdl_results');
%% Load Results
load('Ensemble_Emulation_results.mat')
Em_Mdl = Em_Mdl_results.mdl;
Em_Out_test = Em_Mdl_results.Em_Out_test;
Em_In_test = Em_Mdl_results.Em_In_test;
Sim_Out_test = Em_Mdl_results.Sim_Out_test;
Sim_In_test = Em_Mdl_results.Sim_In_test;
%% Train another model on the Direct Simulation Training Data
params = "auto";
Sim_Mdl = fitcensemble(Sim_In_train,Sim_Out_train,...
    'OptimizeHyperparameters',params,...
    "HyperparameterOptimizationOptions", ...
    struct("AcquisitionFunctionName","expected-improvement-plus", ...
    "MaxObjectiveEvaluations",20));
%% Save the sim model

Sim_Mdl_results.mdl = Sim_Mdl;
Sim_Mdl_results.Sim_Out_test = Sim_Out_test;
Sim_Mdl_results.Sim_In_test = Sim_In_test;

save("Ensemble_Simulation_results.mat",'Sim_Mdl_results');

%% Load the results
load('Ensemble_Simulation_results.mat')
Sim_Mdl = Sim_Mdl_results.mdl;
Sim_Out_test = Sim_Mdl_results.Sim_Out_test;
Sim_In_test = Sim_Mdl_results.Sim_In_test;

%% Evaluate the resulting models both on the Sim testing data

% Evaluate the Em model on the Sim testing data 
[Em_predict_sim_test,Em_scores_sim_test] = Em_Mdl.predict(Sim_In_test);
%%
% Also validate the Em model on the Em testing data
[Em_predict_em_test,Em_scores_em_test] = Em_Mdl.predict(Em_In_test);

%% Evaluating the Simulation Results

[Sim_predict_sim_test,Sim_scores_sim_test] = Sim_Mdl.predict(Sim_In_test);

%% Visualize the results
% Emulation Trained Tested on Simulation Data
f = figure;
f.Position = [100 100 800 500];
cm = confusionchart(Sim_Out_test,Em_predict_sim_test);
cm.Title = 'Classifier Trained on Emulated Data';
cm.FontSize = 18;

savefig(plotID+"Ensemble_Em_mdl_sim_test_confusion_class.fig")
saveID = plotID+"Ensemble_Em_mdl_sim_test_confusion_class.png";
%print('-dpng',saveID)
%% Emulation Trained Tested on Emulation Data 
f = figure;
f.Position = [100 100 800 500];
cm = confusionchart(Em_Out_test,Em_predict_em_test);
cm.Title = 'Ensemble: Emulator Trained on Emulation Data Test';
cm.FontSize = 18;

savefig(plotID+"Ensemble_Em_mdl_em_test_confusion_class.fig")
saveID = plotID+"Ensemble_Em_mdl_em_test_confusion_class.png";
print('-dpng',saveID)
%% Simulation on Simulation Data

% Simulation Trained Tested on Simulation Data
f = figure;
f.Position = [100 100 800 500];
cm = confusionchart(Sim_Out_test,Sim_predict_sim_test);
cm.Title = 'Classifier Trained on Simulated Data';
cm.FontSize = 18;

savefig(plotID+"Ensemble_Sim_mdl_sim_test_confusion_class.fig")
saveID = plotID+"Ensemble_Sim_mdl_sim_test_confusion_class.png";
print('-dpng',saveID)
%% Visualize ROC curves Emulation Trained on Simulation Data

Em_sim_rocObj_test = rocmetrics(Sim_Out_test,Em_scores_sim_test,Em_Mdl.ClassNames);

AUC_test = Em_sim_rocObj_test.AUC;

line1 = "Train: ";
line2 = "Test: ";
cats = categories(Em_Mdl.ClassNames);
for i = 1:numel(cats)
    line2 = line2+"("+cats(i)+", "+num2str(AUC_test(i))+") ";
end
disp(line1)
disp(line2)
% Save the AUC metrics: table with the average AUC training, AUC testing
results = [mean(AUC_test)];

% Grab the internal data
n = numel(Em_Mdl.ClassNames);
x = get(Em_sim_rocObj_test.plot);
turbocustom=turbo(n);
colors = interp1(linspace(0, 24, n), turbocustom, linspace(0,24,n));
f = figure;
f.Position = [100 100 800 500];
set(gca, 'ColorOrder', colors , 'NextPlot', 'replacechildren');
hold on
vals = linspace(0,24,17);
for i = 1:numel(x)
    lgd{i} = [num2str(vals(i))+" (AUC = "+num2str(AUC_test(i))+")"];
    xdats = x(i).XData;
    ydats = x(i).YData;
    plot(xdats,ydats,'LineWidth',3)
end
grid on
plot([0,1],[0,1],'LineStyle','--','LineWidth',4)
lgd{i+1} = ["1:1"];
xlabel("False Positive Rate")
ylabel("True Positive Rate")
title("Ensemble: Emulation Trained on Simulation Data")
fontsize(18,"points")
legend(lgd,'Location','eastoutside')
colormap(turbo(n))
cb = colorbar;
%saveID = plotID+"ROC_test.png";
%print('-dpng',saveID)
%% Visualize ROC curves Simulation Trained on Simulation Data

%[Out_predict_train,scores_train] = Mdl.predict(In_train);

%[Out_predict_test,scores_test] = Mdl.predict(In_test);

Sim_sim_rocObj_test = rocmetrics(Sim_Out_test,Sim_scores_sim_test,Sim_Mdl.ClassNames);

AUC_test = Sim_sim_rocObj_test.AUC;

line1 = "Train: ";
line2 = "Test: ";
cats = categories(Sim_Mdl.ClassNames);
for i = 1:numel(cats)
    line2 = line2+"("+cats(i)+", "+num2str(AUC_test(i))+") ";
end
disp(line1)
disp(line2)
% Save the AUC metrics: table with the average AUC training, AUC testing
results = [mean(AUC_test)];

% Grab the internal data
n = numel(Sim_Mdl.ClassNames);
x = get(Sim_sim_rocObj_test.plot);
turbocustom=turbo(n);
colors = interp1(linspace(0, 24, n), turbocustom, linspace(0,24,n));
f = figure;
f.Position = [100 100 800 500];
set(gca, 'ColorOrder', colors , 'NextPlot', 'replacechildren');
hold on
vals = linspace(0,24,17);
for i = 1:numel(x)
    lgd{i} = [num2str(vals(i))+" (AUC = "+num2str(AUC_test(i))+")"];
    xdats = x(i).XData;
    ydats = x(i).YData;
    plot(xdats,ydats,'LineWidth',3)
end
grid on
plot([0,1],[0,1],'LineStyle','--','LineWidth',4)
lgd{i+1} = ["1:1"];
xlabel("False Positive Rate")
ylabel("True Positive Rate")
title("Ensemble: Simulation Trained on Simulation Data")
fontsize(16,"points")
legend(lgd,'Location','eastoutside')
colormap(turbo(n))
cb = colorbar;
%saveID = plotID+"ROC_test.png";
%print('-dpng',saveID)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [In_train,Out_train,In_test,Out_test] = class_split(classes,samples,percent,Input,Output)

    % Create the Output
    % Select the Output we want 
    output_classes = zeros(samples,classes);
    for i = 1:classes
        output_classes(:,i) = Output(samples*(i-1)+1:samples*i);
    end

    Input_classes = {};
    for i = 1:classes
        Input_classes{i} = Input(samples*(i-1)+1:samples*i,:);
    end
    
    p = percent;% Testing percent
    cvpart = cvpartition(samples,'HoldOut',p);
    
    In_train = Input_classes{1}(training(cvpart),:);
    Out_train = output_classes(training(cvpart),1);
    for i = 2:classes
        In_train = cat(1,In_train,Input_classes{i}(training(cvpart),:));
        Out_train = cat(1,Out_train,output_classes(training(cvpart),i));
    end

    In_test = Input_classes{1}(test(cvpart),:);
    Out_test = output_classes(test(cvpart),1);
    for i = 2:classes
        In_test = cat(1,In_test,Input_classes{i}(test(cvpart),:));
        Out_test = cat(1,Out_test,output_classes(test(cvpart),i));
    end

    Out_train = categorical(Out_train);
    Out_test = categorical(Out_test);
end