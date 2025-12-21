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
rng(1)
[Sim_In_train,Sim_Out_train,Sim_In_test,Sim_Out_test] = class_split(classes,Sim_samples,percent,Simulationdata.Variables,SimOutput);
% Emulation 
rng(1)
[Em_In_train,Em_Out_train,Em_In_test,Em_Out_test] = class_split(classes,Em_samples,percent,emdata(:,[1:8]).Variables,emdata.Alpha);
%% Load the models
load("Ensemble_Emulation_results.mat")
load("Ensemble_Simulation_results.mat")

Em_Mdl = Em_Mdl_results.mdl;

Sim_Mdl = Sim_Mdl_results.mdl;

%% 
Sim_Data_In = [Sim_In_train;Sim_In_test];
Sim_Data_Out = [Sim_Out_train;Sim_Out_test];
Em_Data_In = [Em_In_train;Em_In_test];
Em_Data_Out = [Em_Out_train;Em_Out_test];
%% Use crossvalidation for the Simulation Trained Model
rng(1)
New_Sim_Model = fitcensemble(Sim_Data_In,Sim_Data_Out,...
    "Method",Sim_Mdl.Method,...
    "NumLearningCycles",Sim_Mdl.ModelParameters.NLearn,...
    'Learners',Sim_Mdl.ModelParameters.LearnerTemplates);
rng(1)
Sim_CVensemble = crossval(New_Sim_Model,'Kfold',10);
%% Make the Sim Confusion Chart

f = figure;
f.Position = [50 50 1400 750];
subplot(1,15,1:9)
rng(1)
[Sim_pred,Sim_score] = kfoldPredict(Sim_CVensemble);
cm = confusionchart(Sim_Data_Out,Sim_pred);
cm.FontSize = 20;
%cm.Title = "Simulation Trained";
%cm.Normalization = "total-normalized";
%cm.RowSummary = "row-normalized";
%cm.ColumnSummary = "column-normalized";
cm.FontName = 'Helvetica';
%% Make the Sim ROC 
figure

Sim_sim_rocObj_test = rocmetrics(Sim_Data_Out,Sim_score,New_Sim_Model.ClassNames);

AUC_test_sim_sim = Sim_sim_rocObj_test.AUC;

line1 = "Train: ";
line2 = "Test: ";
cats = categories(Sim_Mdl.ClassNames);
for i = 1:numel(cats)
    line2 = line2+"("+cats(i)+", "+num2str(AUC_test_sim_sim(i))+") ";
end
disp(line1)
disp(line2)
% Save the AUC metrics: table with the average AUC training, AUC testing
results_sim_sim = [mean(AUC_test_sim_sim)];

% Grab the internal data
n = numel(Sim_Mdl.ClassNames);
x = get(Sim_sim_rocObj_test.plot);
turbocustom=turbo(n);
colors = interp1(linspace(0, 24, n), turbocustom, linspace(0,24,n));
close

subplot(1,15,11:15)
set(gca, 'ColorOrder', colors , 'NextPlot', 'replacechildren');
hold on
vals = linspace(0,24,17);
for i = 1:numel(x)
    lgd{i} = sprintf('%.2f (AUC = %.3f)\n',(i-1)/4,AUC_test_sim_sim(i));
    xdats = x(i).XData;
    ydats = x(i).YData;
    plot(xdats,ydats,'LineWidth',3)
end
grid on
plot([0,1],[0,1],'LineStyle','--','LineWidth',4)
lgd{i+1} = ["1:1"];
xlabel("False Positive Rate",'FontName','Helvetica','FontSize',20)
ylabel("True Positive Rate",'FontName','Helvetica','FontSize',20)
%title("Ensemble: Simulation Trained on Simulation Data")
legend(lgd,'Location','best','FontSize',16,'FontName','Helvetica')
colormap(turbo(n))
cb = colorbar;cb.FontName = 'Helvetica';
saveID = "Plots/sim_sim_10foldAOCcurve.png";
fontname(gca,"Helvetica")
% %print('-dpng',saveID) 
%% Save both the AUC curve (right) and the confusion matrix (left)
saveID = "Plots/combinedsimulation.pdf";%"Plots/sim_sim_10foldConfusionMat.png";
%print('-dpng',saveID)
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)
%% Use crossvalidation for the Emulation Trained Models
rng(1)
New_Em_Model = fitcensemble(Em_Data_In,Em_Data_Out,...
    "Method",Em_Mdl.Method,...
    "NumLearningCycles",Em_Mdl.ModelParameters.NLearn,...
    'Learners',Em_Mdl.ModelParameters.LearnerTemplates);
rng(1)
Em_CVensemble = crossval(New_Em_Model,'Kfold',10);
%% Em on Em Confusion Chart
% hold off
% rng(1)
% [Em_pred,Em_score] = kfoldPredict(Em_CVensemble);
% cm = confusionchart(Em_Data_Out,Em_pred);
% cm.FontSize = 18;
%% Evaluate the Emulation Model on the same splits as the Simulation Models
M_scores = zeros(500,5,10);
M_pred = zeros(500,10);
rng(100)
for j = 1:10
    Em_Test_pred = zeros(500,1);
    True = zeros(500,1);
    Em_Test_score = zeros(500,5);
    for i = 1:10
        trained = Em_CVensemble.Trainable{j,1};
        In_test = Sim_Data_In(test(Sim_CVensemble.Partition,i),:);
        True((i-1)*50+1:i*50,1) = Sim_Data_Out(test(Sim_CVensemble.Partition,i),:);
        [Em_Test_pred((i-1)*50+1:i*50,1),...
            Em_Test_score((i-1)*50+1:i*50,:)] = predict(trained,In_test);
    end
    M_pred(:,j) = Em_Test_pred;
    M_scores(:,:,j) = Em_Test_score;
end
%%
Em_Test_pred = mode(M_pred,2);
for i = 1:5
    Em_Test_score(:,i) = mean(M_scores(:,i,:),3);
end

%% Em on Sim Confusion Chart
f = figure;
f.Position = [50 50 1400 750];
subplot(1,15,1:9)
cm = confusionchart((True-1)./4,(Em_Test_pred-1)./4);
cm.FontSize = 20;
%cm.Title = "Emulation Trained";
%cm.Normalization = "total-normalized";
%cm.RowSummary = "row-normalized";
%cm.ColumnSummary = "column-normalized";
cm.FontName = 'Helvetica';
saveID = "Plots/Em_sim_10foldConfusionMat.png";

%% Em on Sim ROC
figure
Em_sim_rocObj_test = rocmetrics((True-1)./4,(Em_Test_score-1)./4,New_Em_Model.ClassNames);

AUC_test_em_sim = Em_sim_rocObj_test.AUC;

line1 = "Train: ";
line2 = "Test: ";
cats = categories(Sim_Mdl.ClassNames);
for i = 1:numel(cats)
    line2 = line2+"("+cats(i)+", "+num2str(AUC_test_em_sim(i))+") ";
end
disp(line1)
disp(line2)
% Save the AUC metrics: table with the average AUC training, AUC testing
results = [mean(AUC_test_em_sim)];

% Grab the internal data
n = numel(Sim_Mdl.ClassNames);
x = get(Sim_sim_rocObj_test.plot);
turbocustom=turbo(n);
colors = interp1(linspace(0, 24, n), turbocustom, linspace(0,24,n));
close

subplot(1,15,11:15)
set(gca, 'ColorOrder', colors , 'NextPlot', 'replacechildren');
hold on
vals = linspace(0,24,17);
for i = 1:numel(x)
    lgd{i} = sprintf('%.2f (AUC = %.3f)\n',(i-1)/4,AUC_test_em_sim(i));
    xdats = x(i).XData;
    ydats = x(i).YData;
    plot(xdats,ydats,'LineWidth',3)
end
grid on
plot([0,1],[0,1],'LineStyle','--','LineWidth',4)
lgd{i+1} = ["1:1"];
xlabel("False Positive Rate",'FontName','Helvetica','FontSize',20)
ylabel("True Positive Rate",'FontName','Helvetica','FontSize',20)
%title("Ensemble: Emulation Trained on Simulation Data")
%fontsize(14,"points")
legend(lgd,'Location','southeast','FontSize',16)
colormap(turbo(n))
cb = colorbar;cb.FontName = 'Helvetica';
fontname(gca,"Helvetica")
saveID = "Plots/em_sim_10foldAOCcurve.png";
%print('-dpng',saveID)
%% Plot both on a shared figure: left is Confusion matrix right is ROC
%print('-dpng',saveID)
saveID = "Plots/combinedemulation.pdf";%"Plots/sim_sim_10foldConfusionMat.png";
% print('-dpng',saveID)
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)
%% Out of Box Predictions
err_sim_sim = zeros(1,10);
for i = 1:10
    err_sim_sim(:,i) = 1-loss(Sim_CVensemble.Trainable{i},....
        Sim_Data_In(test(Sim_CVensemble.Partition,i),:),...
        Sim_Data_Out(test(Sim_CVensemble.Partition,i),:),...
        "LossFun","classiferror");
end
err_em_sim = zeros(1,10);
for j = 1:10
    errs = zeros(1,10);
    for i = 1:10
        errs(:,i) = 1-loss(Em_CVensemble.Trainable{i},....
        Sim_Data_In(test(Sim_CVensemble.Partition,j),:),...
        Sim_Data_Out(test(Sim_CVensemble.Partition,j),:),...
        "LossFun","classiferror");
    end
    err_em_sim(:,j) = mean(errs);
end
%% Now make a table of statistics 
B = zeros(6,2);
B(1,:) = [mean(AUC_test_sim_sim),mean(AUC_test_em_sim)];
B(2,:)  = [std(AUC_test_sim_sim),std(AUC_test_em_sim)];
B(3,:) = [1,100*(B(1,2)-B(1,1))/B(1,1)];
B(4,:) = [mean(err_sim_sim),mean(err_em_sim)];
B(5,:) = [std(err_sim_sim),std(err_em_sim)];
B(6,:) = [1,100*(B(4,2)-B(4,1))/B(4,1)];

disp(B)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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