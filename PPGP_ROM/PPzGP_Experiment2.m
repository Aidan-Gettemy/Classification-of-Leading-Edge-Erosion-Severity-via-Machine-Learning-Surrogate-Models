%% New Experiment: Application

%% Step 1: Create two new input sets for emulation
clc;close;clear;
addpath ..\funcs\
addpath ..\erosionfuncs\
% Experiment 4: Inputs for PPGP Emulation
expName = "ExpNewAidan5000";

% Input Table ID
inTableID = expName+"_inTable.txt";

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
samples = 1000;
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
I(:,3) = 1.10+(1.42-1.10)*p(:,3);
% Wind Shear
I(:,4) = ones(num,1)*.2;
% Set the blade shape type
I(:,end) = ones(num,1)*1; % Shape is linear

% Draw samples from the erosion distribution
for i = 1:classes
    erprofile = bladeErDist(Er_classes(i),samples);
    I((i-1)*samples+1:i*samples,5:end-2) = [erprofile,erprofile,erprofile];
    I((i-1)*samples+1:i*samples,end-1) = Er_classes(i)*ones(samples,1);
end
%% Step 1.b: Check the erosion data Distribution
for j = 1:5
    figure
    [S,AX,BigAx,H,HAx] = plotmatrix(I((j-1)*samples+1:j*samples,5:10));
    title(BigAx,"Scatter Plots of Erosion Level Region vs Region for Severity = "+num2str(Er_classes(j)))
    for i = 1:6
        title(HAx(i),"Histogram Region "+num2str(i))
        xlabel(AX(6*i),"Region "+num2str(i))
        ylabel(AX(i),"Region "+num2str(i))
        for k = 1:6
            xlim(AX(i+(k-1)*6),[0,1])
            ylim(AX(i+(k-1)*6),[0,1])
        end
    end
end
%% Step 1.c: Build the table and save it
inputDesignTab = array2table(I,"VariableNames",invarNames);
writetable(inputDesignTab,inTableID)

%% Step 2: Load the trained emulator
addpath('RobustGaSP_matlab/functions');
addpath('RobustGaSP_matlab/data');
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
T = readtable("ExpNewAidan5000_inTable.txt");
In_test = T(:,[1,2,3,5:10]).Variables;
%% Step 3: Emulate the two datasets
Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);

Out_predict_means = Out_predict.mean;
% Reshape and save the predicted values into a dataset 
% Add the correct column names
EmTable = array2table(Out_predict_means,"VariableNames",PP_GPmodel.PP_GP.target_vars);
% Add the target Variable
EmTable.Alpha = T.Alpha;
% Add the wind speed variable
EmTable.WindSpeed = T.WindSpeed;
%% Plot Power Curves 

scatter(EmTable,"WindSpeed","GenPwrmean","filled","ColorVariable","Alpha")

%% And save...
saveId = "EmulationDatasetExpNewAidan5000.txt";
writetable(EmTable,saveId)

%% Step 4: Test the Random Forest Classifier with 10-fold crossvalidation on
% the two emulated datasets using POWER as the ONLY predictor. 
clc;close;clear;
testdataId = "EmulationDatasetExpNewAidan5000.txt";
data5000 = readtable(testdataId);

% Grab the predictor names that we need
% Recall, they are the column names of the emdata 

predictornames = data5000.Properties.VariableNames([8,10]);

data = data5000(:,predictornames);
Output = data5000.Alpha;
%% Now call a function which will give us the Training and Testing Data
% for holdout testing 
classes = 5;
samples = 1000;
percent = .15;
% Simulation 
[In_train,Out_train,In_test,Out_test] = class_split(classes,samples,percent,data.Variables,Output);
%% Train the model
params = "auto";
Mdl = fitcensemble(In_train,Out_train,...
    'OptimizeHyperparameters',params,...
    "HyperparameterOptimizationOptions", ...
    struct("AcquisitionFunctionName","expected-improvement-plus", ...
    "MaxObjectiveEvaluations",30));
%% Save the optimized model
AUX.mdl = Mdl;
AUX.In_train = In_train;
AUX.Out_train = Out_train;
AUX.In_test = In_test;
AUX.Out_test = Out_test;

save("PPzGP_exp2PwrWnd_classifier1000.mat",'AUX');
%% Use the optimized model parameters to do cross validation.
clc;close;clear;
load("PPzGP_exp2Pwr_classifier1000.mat")

Mdl = AUX.mdl;
 
Data_In = [AUX.In_train;AUX.In_test];
Data_Out = [AUX.Out_train;AUX.Out_test];

%% Use crossvalidation for the Simulation Trained Model
New_Model = fitcensemble(Data_In,Data_Out,...
    "Method",Mdl.Method,...
    "NumLearningCycles",Mdl.ModelParameters.NLearn,...
    'Learners',Mdl.ModelParameters.LearnerTemplates);
CVensemble = crossval(New_Model,'Kfold',10);

%% Step 5: The Confusion Matrix (in percentages)

[predict_test,scores_test] = kfoldPredict(CVensemble);
f = figure;
f.Position = [100 100 800 500];
cm = confusionchart(Data_Out,predict_test,"Normalization","total-normalized");
cm.Title = 'Classify by Power, 5000 Training Samples';
cm.FontSize = 18;
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

saveID = "Plots/Pwr5000_10foldConfusionMat.png";
print('-dpng',saveID)

%% Step 6: The ROC, AUC, etc.
figure
rocObj_test = rocmetrics(Data_Out,scores_test,New_Model.ClassNames);

AUC_test = rocObj_test.AUC;

line1 = "Train: ";
line2 = "Test: ";
cats = categories(Mdl.ClassNames);
for i = 1:numel(cats)
    line2 = line2+"("+cats(i)+", "+num2str(AUC_test(i))+") ";
end
disp(line1)
disp(line2)
% Save the AUC metrics: table with the average AUC training, AUC testing
results = [mean(AUC_test)];

% Grab the internal data
n = numel(Mdl.ClassNames);
x = get(rocObj_test.plot);
turbocustom=turbo(n);
colors = interp1(linspace(0, 24, n), turbocustom, linspace(0,24,n));
f = figure;
f.Position = [100 100 800 500];
set(gca, 'ColorOrder', colors , 'NextPlot', 'replacechildren');
hold on
vals = linspace(0,24,17);
for i = 1:numel(x)
    lgd{i} = sprintf('%.2f (AUC = %.3f)\n',(i-1)/4,AUC_test(i));
    xdats = x(i).XData;
    ydats = x(i).YData;
    plot(xdats,ydats,'LineWidth',3)
end
grid on
plot([0,1],[0,1],'LineStyle','--','LineWidth',4)
lgd{i+1} = ["1:1"];
xlabel("False Positive Rate")
ylabel("True Positive Rate")
title("Classify by Power, 5000 Training Samples")
fontsize(16,"points")
legend(lgd,'Location','southeast')
colormap(turbo(n))
cb = colorbar;

saveID = "Plots/Pwr5000_10foldROC.png";
print('-dpng',saveID)
%% Find the Classification Rate
corr_class_rate = zeros(1,10);
for i = 1:10
    corr_class_rate(:,i) = 1-loss(CVensemble.Trainable{i},....
        Data_In(test(CVensemble.Partition,i),:),...
        Data_Out(test(CVensemble.Partition,i),:),...
        "LossFun","classiferror");
end

%% Now make a table of statistics 
B = zeros(4,1);

AUC = [mean(AUC_test)];
AUC_std  = [std(AUC_test)];
Accuracy = [mean(corr_class_rate)];
Accuracy_std = [std(corr_class_rate)];

T = table(AUC, AUC_std, Accuracy, Accuracy_std);

writetable(T,'Pwr5000_resultsTable.txt')
%% Read Talbes

T1 = readtable("Pwr500_resultsTable.txt");
T2 = readtable("PwrWnd500_resultsTable.txt");
T3 = readtable("Pwr5000_resultsTable.txt");
T4 = readtable("PwrWnd5000_resultsTable.txt");

T = [T1;T2;T3;T4];T.Properties.RowNames = ["Power-500","Power+Wind-500",...
    "Power-5000","Power+Wind-5000"]

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