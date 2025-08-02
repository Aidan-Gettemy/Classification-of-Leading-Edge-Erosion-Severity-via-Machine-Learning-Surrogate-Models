clc;close;clear;
%% First, see how effective the model is at Emulating Generator Power
addpath('RobustGaSP_matlab/functions');
addpath('RobustGaSP_matlab/data');
addpath('zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/zGP_upper_constraint_for_Aidan/');
%% Load the data 
dataId = "../Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
data = readtable(dataId);
%%
clc
for i = 1:6
    a = min(data(161:210,i+4).Variables);
    b = max(data(161:210,i+4).Variables);
    a = [a,b];
    fprintf('[%.2f %.2f]\n',a(1),a(2));
end
%% Power Emulator 

% Calling this function will train and save the model on p% of the data
% The input and output used are saved with the model 

% Test on x% of the data
percts = (210-[30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180])./210;
%%
for i = 1:numel(percts)
    percent = percts(i); % Testing percent
    [mdl, In_test, Out_test] = trainGP_genpwr(data, percent);
    save("GenPwrGP_"+num2str(1-percent)+"mdl.mat",'mdl');
    save("GenPwrGP_"+num2str(1-percent)+"In_test.mat",'In_test')
    save("GenPwrGP_"+num2str(1-percent)+"Out_test.mat",'Out_test')
end

%% Visualize Results

% for each level of training; produce
% - plot of the predicted vs true with conf ints
% -- Save as a figure 
% - a value for the rmse 
% Test the model

trainpercs = 1-percts;
err = zeros(1,numel(trainpercs));
for j =1:numel(trainpercs)
    trainperc = trainpercs(j);
    model = load("GenPwrGP_"+num2str(trainperc)+"mdl.mat","mdl");
    model = model.mdl;
    In_test = load("GenPwrGP_"+num2str(trainperc)+"In_test.mat","In_test");
    In_test = In_test.In_test;
    Out_test = load("GenPwrGP_"+num2str(trainperc)+"Out_test.mat","Out_test");
    Out_test = Out_test.Out_test;
    
    Out_predict=predict_ppgasp(model,In_test);
    
    % Only display some of the data

    % Want to show 50 points
    p=1-30/numel(Out_test);% percent of testing points to leave out
    if p <0;p=1;end
    plotpart = cvpartition(numel(Out_predict.mean(:,1)),'HoldOut',p);
    
    % Later, we might consider using the zgp to account for the upper limit
    % of 5MW for power
    [Outsort, predictInd] = sort(Out_test);
    figure
    hold on 
    scatter(1:numel(Outsort(training(plotpart),1)),...
        Out_predict.mean(predictInd(training(plotpart),:)),'filled')
    
    scatter(1:numel(Outsort(training(plotpart),:)),...
        Out_test(predictInd(training(plotpart),:)),'filled')
    
    lower = Out_predict.lower95(predictInd(training(plotpart),:));
    upper = Out_predict.upper95(predictInd(training(plotpart),:));
    for i =1:numel(lower)
        plot([i,i],[lower(i),upper(i)],"Color",'k')
    end
    ylabel("Generator Power")
    xlabel("Testing Points Indexed by Value")
    legend("Predicted","True","95% Confidence Interval",Location="southeast")
    title("Generator Power GP: Training Points = "...
        +num2str(numel(data(:,1))*trainperc)+", Showing "...
        +num2str(numel(Out_test(training(plotpart),:)))+" Testing Points")

    err(j) = rms(Out_predict.mean-Out_test);
    count = 0;
    for k = 1:numel(Out_test)
        if Out_predict.mean(k) > Out_test(k)-2*Out_predict.sd(i)
            if Out_predict.mean(k) < Out_test(k)+2*Out_predict.sd(i)
                count = count+1;
            end
        end
    end
    coverage(j) = count/numel(Out_test);
end
%% Plot the RMSE for each model as a bargraph
figure
bar(trainpercs,err)
title("RMSE vs Training Percent of Data")
grid on
% Save as a figure
%% Plot the percent of predicted in 95% confidence
figure
bar(trainpercs,coverage(1:numel(trainpercs)))
title("95% Coverage vs Training Percent of Data")
grid on 
%% Examine the PPGPs ability to emulate all of the promising quantities at once

% Extract the features we want to use.
% Read in the selected predictors
predimpID = "../MachineLearning/Classification_imp.txt";
Importances=readmatrix(predimpID);
% We will use the first 8 most important variables 
numvars = 8;
% Percent of data to put towards testing
percent = (210-170)/210;
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

%% Impute zGP values for the desired columns
for i =1:numel(zGP_cols)
    output = Out_train(:,zGP_cols(i));
    [zGP_outs(:,i), zGP_scale(i), zGP_shift(i), yRLs(:,i)] = zGP_process2(output,...
        In_train, lim_types(i));
end

%% Fix the Training Ouputs
Out_train(:,zGP_cols) = zGP_outs;

%options.trend=[ones(numel(Out_train(:,1)),numvars)  In_train];
%options.zero_mean  = false; 
%options.nugget_est = false;

% At last, the model
modelPPzGP=ppgasp(In_train,Out_train);
% Create an object which we can save which has all of the pieces that we
% need:

%%
PP_GP.model = modelPPzGP;
PP_GP.In_test = In_test;
PP_GP.In_train = In_train;
PP_GP.Out_test = Out_test;
PP_GP.Out_train = Out_train;
PP_GP.numvars = numvars;
PP_GP.scaling_factors = zGP_scale;
PP_GP.zGP_index = zGP_cols;
PP_GP.lim_types = lim_types;
PP_GP.target_vars = targets;
PP_GP.zGP_shift = zGP_shift;
PP_GP.yRLs = yRLs;
% Save this object
save("PP_zGP"+num2str(1-percent)+"package.mat",'PP_GP');

%% Visualize the results
mdl_id = "PP_zGP"+num2str((170/210))+"package.mat";
PP_GPmodel = load(mdl_id);

PP_GP = PP_GPmodel.PP_GP;

modelPPzGP = PP_GP.model;
In_test = PP_GP.In_test;
In_train = PP_GP.In_train;
Out_test = PP_GP.Out_test;
numvars = PP_GP.numvars;
zGP_scale = PP_GP.scaling_factors;
zGP_cols = PP_GP.zGP_index;
lim_types = PP_GP.lim_types;
targets = PP_GP.target_vars;
zGP_shift = PP_GP.zGP_shift;
yRLs = PP_GP.yRLs;

%% Also, write a function which can predict and correct the output of the
% function after doing zGP 
Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types, zGP_shift, yRLs, In_train);

for j = 8:numvars
    figure
    subplot(1,2,1)
    [Outsort, predictInd] = sort(Out_test(:,j));
    hold on 
    predict = Out_predict.mean(predictInd,j);
    % Number of Points to show
    points = 25;
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
    title(targets(j)+" Points = "+num2str(numel(predictInd(test(cvpart)))))
    subplot(1,2,2)
    hold on
    scatter(Outsort,predict,'filled')
    ylabel('predicted')
    xlabel('true')
    title("Scatter Plot True vs Predicted "+targets(j))
    plot([min(min(predict),min(Outsort)),max(max(predict),max(Outsort))],[min(min(predict),min(Outsort)),max(max(predict),max(Outsort))],'red')
    count = 0;
    for k = 1:numel(Out_test(:,j))
        
        if Out_test(k,j) > Out_predict.mean(k,j)-2*Out_predict.sd(k,j)
            if  Out_test(k,j) < Out_predict.mean(k,j)+2*Out_predict.sd(k,j)
                count = count+1;
                disp([k, count])
            end
        end
    end
    counts(j) = count;
    S = sum((Out_test(:,j)-Out_predict.mean(:,j)).*(Out_test(:,j)-Out_predict.mean(:,j)));
    Nrmse(j) = sqrt(S/numel(Out_test(:,j)))/(max(Out_test(:,j))-min((Out_test(:,j))));
end

for i = 1:numel(Out_test(1,:))
    disp('Percent of '+targets(i)+' Predicted within Conf. Int. =  '+num2str(100*counts(i)/numel(predict)))
end

for i = 1:numel(Out_test(1,:))
    disp('Normalized RMSE of '+targets(i)+' = '+num2str(Nrmse(i)))
end

%% Compare predictions with another dataset

% Extract the columns we use to make the predictions
Importances = readmatrix("..\MachineLearning\Classification_imp.txt");
T = readtable("..\Exp2_inTable.txt");
In_test = T(:,[1,2,3,5:10]).Variables;
Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);
r_id = "../Data/Exp2/LARGE2ExperimentResultTable500.txt";
r_data = readtable(r_id);
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

targets = varnames(Importances(1:numvars));

Out_test = r_data(:,targets).Variables;
%%
for j = 1:numvars
    f = figure;
    f.Position = [100 100 800 500];
    subplot(1,2,1)
    [Outsort, predictInd] = sort(Out_test(:,j));
    hold on 
    predict = Out_predict.mean(predictInd,j);
    % Number of Points to show
    points = 25;
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
    title(targets(j)+" Points = "+num2str(numel(predictInd(test(cvpart)))))
    subplot(1,2,2)
    hold on
    scatter(Outsort,predict,'filled')
    ylabel('predicted')
    xlabel('true')
    title("Scatter Plot True vs Predicted "+targets(j))
    plot([min(min(predict),min(Outsort)),max(max(predict),max(Outsort))],[min(min(predict),min(Outsort)),max(max(predict),max(Outsort))],'red')
    count = 0;
    for k = 1:numel(Out_test(:,j))
        if Out_predict.mean(k,j) > Out_test(k,j)-2*Out_predict.sd(i,j)
            if Out_predict.mean(k,j) < Out_test(k,j)+2*Out_predict.sd(i,j)
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
end

for i = 1:numel(Out_test(1,:))
    disp('Normalized RMSE of '+targets(i)+' = '+num2str(Nrmse(i)))
end
%% Official Plots
% targets1 = ["Drag Coefficient Mean ","Drag Coefficient Standard Deviation",...
%     "Lift Coefficient Mean",...
%     "Tip Acceleration Skew","Root Moment Mean","Lift Coefficient Standard Deviation",...
%     "Tip Acceleration Standard Deviation",...
%     "Generator Power Mean"];
targets1 = ["Drag coefficient mean","Drag coefficient standard deviation",...
    "Lift coefficient mean",...
    "Tip acceleration skew","Root moment mean","Lift coefficient standard deviation",...
    "Tip acceleration standard deviation",...
    "Generator power mean"];
targets2 = [" (-)",""," (-)",""," (kN-m)",""," ($ms^{-2}$)"," (MW)"];
targets3 = ["$\mu$", "$\sigma$",...
    "$\mu$","$\gamma$","$\mu$",...
    "$\sigma$","$\sigma$", '$\mu$'];
f = figure;
f.Position = [50 50 1050 600];
tiledlayout(2,2)
for j = [1,7,5,8]%1:numvars
    nexttile
    [Outsort, predictInd] = sort(Out_test(:,j));
    hold on 
    predict = Out_predict.mean(predictInd,j);
    % Number of Points to show
    points = 37;
    p = points/numel(Outsort);
    if p > 1;p = .9;end
        m = 1;
        if j == 8
            m = 1/1000;
        end
    if p < 1
        cvpart = cvpartition(numel(Outsort),'HoldOut',p);
        m = 1;
        if j == 8
            m = 1/1000;
        end
        errorbar(1:numel(Outsort(test(cvpart))),m*predict(test(cvpart)),...
            m*2*Out_predict.sd(predictInd(test(cvpart)),j),...
            'Linestyle','none','Marker','o','LineWidth',1,'MarkerSize',5,...
            'MarkerFaceColor',	"#0072BD",'MarkerEdgeColor','k')
        
        scatter(1:numel(Outsort(test(cvpart))),m*Outsort(test(cvpart)),'filled','MarkerEdgeColor','k',...
            'LineWidth',1,'MarkerSize',5)
        
        lower = Out_predict.mean(predictInd(test(cvpart)),j)-2*Out_predict.sd(predictInd(test(cvpart)),j);
        upper = Out_predict.mean(predictInd(test(cvpart)),j)+2*Out_predict.sd(predictInd(test(cvpart)),j);
        
        xlabel("Indexed by True"+" QOI")
        ylabel(sprintf('%s',targets3(j)),'Interpreter','latex')
        legend("Predicted","True",Location="northwest")
        title(targets1(j)+" Showing "+num2str(numel(predictInd))+" Points")
    end
    if p == 1
        errorbar(1:numel(Outsort),m*predict,...
            m*2*Out_predict.sd(predictInd,j),...
            'Linestyle','none','Marker','o','LineWidth',1,'MarkerSize',5,...
            'MarkerFaceColor',	"#0072BD",'MarkerEdgeColor','k')
    
        scatter(1:numel(Outsort),m*Outsort,'filled','MarkerEdgeColor','k',...
            'LineWidth',1)
        
        lower = Out_predict.mean(predictInd,j)-2*Out_predict.sd(predictInd,j);
        upper = Out_predict.mean(predictInd,j)+2*Out_predict.sd(predictInd,j);
        
        %xlabel("Indexed by True Value")
        ylabel(targets3(j)+targets2(j),'Interpreter','latex','FontSize',14,'FontWeight','normal','FontName','Helvetica')
        legend({"Predicted","True"},"Location","best",'FontSize',14,'FontWeight','normal','FontName','Helvetica')
        title(targets1(j),'FontSize',14,'FontWeight','normal','FontName','Helvetica')
    end
    g = gca();g.FontSize = 14;g.FontName= 'Helvetica';
    grid on
    grid minor
    %saveID = "Plots/PPzGP_predict"+targets(j)+".png";
    %print('-dpng',saveID)
    
end
saveID = "Plots/PPzGP_predict_onefig"+".pdf";
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)
%%
addpath("..\erosionfuncs\")
s = 5;
f = figure;
f.Position = [100 100 1050 650];
mkrs = ["o","square","diamond","square","o"];
ltsy = ["-","--",":","-","--"];
for i = 1:s
    hold on
    n = 31;
    x = linspace(5,18,n);
    In_test = zeros(n,9);
    In_test(:,2) = x;
    In_test(:,1) = 0*ones(n,1);
    In_test(:,3) = 1.225*ones(n,1);
    In_test(:,4:9) = (erShape(1,(i-1)/(s-1))*ones(1,n))';
    
    Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);
    
    lgd{i} = "Erosion severity " + num2str((i-1)/(s-1));
    errorbar(x,1/1000*Out_predict.mean(:,8),1/1000*2*Out_predict.sd(:,8),'LineWidth',1.2,...
        'MarkerSize',8,'Marker',mkrs(i),'MarkerFaceColor','auto','LineStyle',ltsy(i))
end
g = gca();
%title("Generator Power vs Wind Speed PPzGP Estimates")
legend(lgd,'location','southeast')
ylabel("Generator Power (MW)")
xlabel("Wind Speed (m/s)")
g.FontSize = 18;
grid on
grid minor
xlim([5,18])
ylim([-0.50,6])
saveID = "Plots/PPzGP_powercurvewither.png";
print('-dpng',saveID)
%% Make a MeshGrid of the Predictions
f = figure;
f.Position = [50 50 850 650];
n = 150;
erlim = 1;
[XX,YY] = meshgrid(0:erlim/n:erlim,5:(15-5)/n:15);%meshgrid(0:erlim/n:erlim,3:(25-3)/n:25);
n = n+1;
s = 8; % Target
targets1 = ["Drag Sensor mean","Drag Sensor sd", "Lift Sensor mean",...
    "Tip Acceleration Skew","Root Moment mean","Lift Sensor sd","Tip Acceleration sd",...
    "Generator Power mean"];
targets2 = [" (-)",""," (-)",""," (kN-m)","",""," (kW)"];

XX = reshape(XX,[numel(XX),1]);
YY = reshape(YY,[numel(YY),1]);
In_test = ones(numel(XX),9);
In_test(:,1) = In_test(:,1)*0;% Wind Direction
In_test(:,2) = YY; % Wind Speed
In_test(:,3) = 1.235*In_test(:,3);%1.225*In_test(:,3); % Air Density
for i = 1:numel(XX)
    In_test(i,4:9) = erShape(1,XX(i));% Blade Profile
end

Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);

powermean = reshape(Out_predict.mean(:,s),[n, n]);

[XX,YY] = meshgrid(0:erlim/(n-1):erlim,5:(15-5)/(n-1):15);
contourf(XX,YY,powermean/1000);
g = gca();
g.FontSize = 18;
%title(targets1(s)+" vs Erosion Level vs Wind Speed")
xlabel("Erosion severity factor (-)",'Interpreter','latex')
ylabel("Wind speed $(m s^{-1})$",'Interpreter','latex')
zlabel(sprintf('Generator power (MW)'),'Interpreter','latex');%(targets1(s)+targets2(s))
cb = colorbar;cb.Label.String =sprintf('Generator power (MW)');%targets1(s)+targets2(s);
cb.Label.Interpreter = 'latex';cb.Label.FontSize = 18;
fontname(f,"Helvetica")
grid on
%grid minor
%view(2)
ylim([5,15])
saveID = "Plots/PPzGP_mainplot.pdf";
%print('-dpng',saveID)
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)
%% Now plot the uncertainty 
f = figure;
f.Position = [50 50 850 650];
powerstd = reshape(Out_predict.sd(:,s),[n, n]);

[XX,YY] = meshgrid(0:erlim/(n-1):erlim,3:(25-3)/(n-1):25);
surf(XX,YY,powerstd);
g = gca();
g.FontSize = 18;
title(targets1(s)+" STD vs Erosion Level vs Wind Speed")
xlabel("Erosion Severity Factor (-)")
ylabel("Wind Speed (m/s)")
zlabel(targets1(s)+targets2(s))
cb = colorbar;cb.Label.String ="Generator Power STD";
grid on
grid minor
view(2)
ylim([3,25])
%saveID = "Plots/PPzGP_rootSurfacestd.png";
%print('-dpng',saveID)
%% Now investigate the air density and wind direction effects 
f = figure;
f.Position = [50 50 1300 600];
addpath("..\erosionfuncs\")
subplot(1,5,1:3)
s = 5;

mkrs = ["o","square","diamond","square","o"];
ltsy = ["-","--",":","-","--"];
for i = 1:s
    hold on
    n = 17;
    x = linspace(5,18,n);
    In_test = zeros(n,9);
    In_test(:,2) = x;
    In_test(:,1) = 0*ones(n,1);
    In_test(:,3) = 1.225*ones(n,1);
    In_test(:,4:9) = (erShape(1,(i-1)/(s-1))*ones(1,n))';
    
    Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);
    
    lgd{i} = "Erosion severity " + num2str((i-1)/(s-1));
    errorbar(x,1/1000*Out_predict.mean(:,8),1/1000*2*Out_predict.sd(:,8),'LineWidth',1.2,...
        'MarkerSize',6,'Marker',mkrs(i),'MarkerFaceColor','auto','LineStyle',ltsy(i))
end
g = gca();
%title("Generator Power vs Wind Speed PPzGP Estimates")
legend(lgd,'location','southeast','Interpreter','latex','FontName','Helvetica')
ylabel("Generator power (MW)",'Interpreter','latex','FontName','Helvetica')
xlabel("Wind speed $(ms^{-1})$",'Interpreter','latex','FontName','Helvetica')
g.FontSize = 14;
grid on

xlim([5,18])
ylim([-0.50,6])
fontname(f,"Arial")


subplot(1,5,4:5)
% set a wind speed
% 5 different air densities
% vary the wind dir
s = 5;
airdens = linspace(1.1,1.4,s);

mkrs = ["o","square","diamond","square","o"];
ltsy = ["-","--",":","-","--"];
for i = 1:s
    hold on
    n = 9;
    x = linspace(-15,15,n);
    In_test = ones(n,9);
    In_test(:,1) = x;
    In_test(:,2) = 10.5*ones(n,1);
    In_test(:,3) = airdens(i)*ones(n,1);
    In_test(:,4:9) = (erShape(1,0)*ones(1,n))';
    
    Out_predict = predicted_outputs2(modelPPzGP, In_test, numvars, zGP_scale, zGP_cols, lim_types,zGP_shift,yRLs,In_train);
    
    lgd{i} = sprintf('Air density %.3f $kgm^{-3}$',airdens(i));
    errorbar(x,Out_predict.mean(:,8)/1000,2*Out_predict.sd(:,8)/1000,'LineWidth',1.2,...
        'MarkerSize',6,'Marker',mkrs(i),'MarkerFaceColor','auto','LineStyle',ltsy(i))
end
g = gca;
%title("Power vs Wind Direction; Wind Speed = 10.5 m/s")
legend(lgd,'location','southeast','Interpreter','latex','FontName','Helvetica')
%ylabel("Power (MW)")
ylim([-0.50,6]);%ylim([1500/1000, 4500/1000])
xlim([-16,16])
xlabel("Wind direction $(^{\circ})$",'Interpreter','latex','FontName','Helvetica')
set(g,'yticklabels',[])
g.FontSize = 14;g.YLabel=[];
grid on
%grid minor

saveID = "Plots/PPzGP_infplotsnew.pdf";
%print('-dpng',saveID)
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [model,In_test,Out_test] = trainGP_genpwr(data, percent)
    % Select the Output we want 
    output_clean = data.GenPwrmean(1:10);
    output_class1 = data.GenPwrmean(11:60);
    output_class2 = data.GenPwrmean(61:110);
    output_class3 = data.GenPwrmean(111:160);
    output_class4 = data.GenPwrmean(161:210);
    
    % Select the training data and testing data (recall the classes)
    In_clean = data(1:10,[1:2,4,5:10]);
    In_class1 = data(11:60,[1:2,3,5:10]);
    In_class2 = data(61:110,[1:2,3,5:10]);
    In_class3 = data(111:160,[1:2,3,5:10]);
    In_class4 = data(161:210,[1:2,3,5:10]);
    
    p = percent;% Testing percent
    cvpartc = cvpartition(numel(output_clean),'HoldOut',p);
    cvpart1 = cvpartition(numel(output_class1),'HoldOut',p);
    cvpart2 = cvpartition(numel(output_class2),'HoldOut',p);
    cvpart3 = cvpartition(numel(output_class3),'HoldOut',p);
    cvpart4 = cvpartition(numel(output_class4),'HoldOut',p);
    
    In_trainc = In_clean(training(cvpartc),:).Variables;
    Out_trainc = output_clean(training(cvpartc));
    
    In_train1 = In_class1(training(cvpart1),:).Variables;
    Out_train1 = output_class1(training(cvpart1));
    
    In_train2 = In_class2(training(cvpart2),:).Variables;
    Out_train2 = output_class2(training(cvpart2));
    
    In_train3 = In_class3(training(cvpart3),:).Variables;
    Out_train3 = output_class3(training(cvpart3));
    
    In_train4 = In_class4(training(cvpart4),:).Variables;
    Out_train4 = output_class4(training(cvpart4));
    
    
    In_train = cat(1,In_trainc,In_train1);
    In_train = cat(1,In_train,In_train2);
    In_train = cat(1,In_train,In_train3);
    In_train = cat(1,In_train,In_train4);
    
    Out_train = cat(1,Out_trainc,Out_train1);
    Out_train = cat(1,Out_train,Out_train2);
    Out_train = cat(1,Out_train,Out_train3);
    Out_train = cat(1,Out_train,Out_train4);
    
    In_testc = In_clean(test(cvpartc),:).Variables;
    Out_testc = output_clean(test(cvpartc));
    
    In_test1 = In_class1(test(cvpart1),:).Variables;
    Out_test1 = output_class1(test(cvpart1));
    
    In_test2 = In_class2(test(cvpart2),:).Variables;
    Out_test2 = output_class2(test(cvpart2));
    
    In_test3 = In_class3(test(cvpart3),:).Variables;
    Out_test3 = output_class3(test(cvpart3));
    
    In_test4 = In_class4(test(cvpart4),:).Variables;
    Out_test4 = output_class4(test(cvpart4));
    
    In_test = cat(1,In_testc,In_test1);
    In_test = cat(1,In_test,In_test2);
    In_test = cat(1,In_test,In_test3);
    In_test = cat(1,In_test,In_test4);
    
    Out_test = cat(1,Out_testc,Out_test1);
    Out_test = cat(1,Out_test,Out_test2);
    Out_test = cat(1,Out_test,Out_test3);
    Out_test = cat(1,Out_test,Out_test4);
    
    % Fit the model
    model=ppgasp(In_train,Out_train);
end