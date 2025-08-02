clear; close; clc;

addpath('RobustGaSP_matlab/functions');
addpath('RobustGaSP_matlab/data');
addpath('zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/');
% Load the data 
dataId = "../Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
data = readtable(dataId);
%%
K = 5;
number_training = 170;

coverages = zeros(8,K);
nRmses = zeros(8,K);

for k = 1:K
    % Extract the features we want to use.
    % Read in the selected predictors
    predimpID = "../MachineLearning/Classification_imp.txt";
    Importances=readmatrix(predimpID);
    % We will use the first 8 most important variables 
    numvars = 8;
    % Percent of data to put towards testing
    percent = (210-number_training)/210;
    % Grab the columns for testing and training 
    [In_train,Out_train,In_test,Out_test,targets] = PPGP_dataprep(numvars,Importances,data,percent);
    
    % Note, several of these variables are range limited.
    
    % Write a function which takes in the original values and returns the 
    % values given by zGP imputation 
    zGP_cols = [2,6,7,8];
    lim_types = ["lower","lower","lower","upper"];
    zGP_outs = zeros(numel(Out_train(:,1)),numel(zGP_cols));
    zGP_scale = zeros(numel(zGP_cols),1);
    zGP_shift = zeros(numel(zGP_cols),1);
    yRLs = zeros(numel(In_train(:,1)),numel(zGP_cols));
    
    % Impute zGP values for the desired columns
    for i =1:numel(zGP_cols)
        output = Out_train(:,zGP_cols(i));
        [zGP_outs(:,i), zGP_scale(i), zGP_shift(i), yRLs(:,i)] = zGP_process2(output,...
            In_train, lim_types(i));
    end
    
    % Fix the Training Ouputs
    Out_train(:,zGP_cols) = zGP_outs;
    
    %options.trend=[ones(numel(Out_train(:,1)),numvars)  In_train];
    %options.zero_mean  = false; 
    %options.nugget_est = false;
    
    % At last, the model
    modelPPzGP=ppgasp(In_train,Out_train);
    % Create an object which we can save which has all of the pieces that we
    % need:
    
    
    Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types, zGP_shift, yRLs, In_train);
    
    disp("*************************************")
    disp(num2str(k))
    for j = 1:numvars
        figure
        subplot(1,2,1)
        [Outsort, predictInd] = sort(Out_test(:,j));
        hold on 
        predict = Out_predict.mean(predictInd,j);
        % Number of Points to show
        points = 50;
        p = points/numel(Outsort);
        if p > 1;p = .9;end
        cvpart = cvpartition(numel(Outsort),'HoldOut',p);
    
        scatter(1:numel(Outsort(test(cvpart))),predict(test(cvpart)),'filled')
        
        scatter(1:numel(Outsort(test(cvpart))),Outsort(test(cvpart)),'filled')
        
        lower = Out_predict.mean(predictInd(test(cvpart)),j)-2*Out_predict.sd(predictInd(test(cvpart)),j);
        upper = Out_predict.mean(predictInd(test(cvpart)),j)+2*Out_predict.sd(predictInd(test(cvpart)),j);
        for i =1:numel(predict(test(cvpart)))
            plot([i,i],[lower(i),upper(i)],"Color",'k')
        end
        xlabel("Indexed by True "+targets(j)+" value")
        ylabel(targets(j))
        legend("Predicted","True","95% Confidence Interval",Location="southeast")
        title(num2str(k)+": "+targets(j)+" Points = "+num2str(numel(predictInd(test(cvpart)))))
        subplot(1,2,2)
        hold on
        scatter(Outsort,predict,'filled')
        ylabel('predicted')
        xlabel('true')
        title("Scatter Plot True vs Predicted "+targets(j))
        plot([min(min(predict),min(Outsort)),max(max(predict),max(Outsort))],[min(min(predict),min(Outsort)),max(max(predict),max(Outsort))],'red')
        count = 0;
        for kk = 1:numel(Out_test(:,j))
            if Out_test(kk,j) > Out_predict.mean(kk,j)-2*Out_predict.sd(kk,j)
                if Out_test(kk,j) < Out_predict.mean(kk,j)+2*Out_predict.sd(kk,j)
                    count = count+1;
                end
            end
        end
        counts(j) = count;
        S = sum((Out_test(:,j)-Out_predict.mean(:,j)).*(Out_test(:,j)-Out_predict.mean(:,j)));
        Nrmse(j) = sqrt(S/numel(Out_test(:,j)))/(max(Out_test(:,j))-min((Out_test(:,j))));
    end
    
    for i = 1:numel(Out_test(1,:))
        disp('Percent of '+targets(i)+' Predicted within Conf. Int. =  '+num2str(100*counts(i)/numel(predict)))
        coverages(i,k) = 100*counts(i)/numel(predict);
    end
    
    for i = 1:numel(Out_test(1,:))
        disp('Normalized RMSE of '+targets(i)+' = '+num2str(Nrmse(i)))
        nRmses(i,k) = Nrmse(i);
    end
end

writematrix(coverages,"kfold_coverages"+num2str(number_training)+".txt")
writematrix(nRmses,"kfold_nrmeses"+num2str(number_training)+".txt")
%% Compute the k-fold results
clc;close;clear;
% Load the data 
dataId = "../Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
data = readtable(dataId);
numvars = 8;
predimpID = "../MachineLearning/Classification_imp.txt";
Importances=readmatrix(predimpID);
percent = .5;

[In_train,Out_train,In_test,Out_test,targets] = PPGP_dataprep(numvars,Importances,data,percent);

coverages = readmatrix("kfold_coverages170.txt");
nRmses = readmatrix("kfold_nrmeses170.txt");
A = zeros(8,4);
A(:,1) = mean(coverages,2);
A(:,3) = mean(nRmses,2);
A(:,2) = std(coverages,0,2);
A(:,4) = std(nRmses,0,2);
new_table = array2table(A,"RowNames",targets,...
    "VariableNames",["Mean Coverage","Std Coverage","Mean NRMSE","Std NRMSE"]);
writetable(new_table,"ppzgp_5fold.csv",'Delimiter',',',"WriteRowNames",true)