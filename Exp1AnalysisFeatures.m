clc;close;clear;
addpath funcs/
% Generate combined datatable for full experiment with more features
%% Stage 1: Make a status file that contains all of the experiments

% Grab the experiment name
expName = "Exp1";

% Stage 2: Create additional Features
JobNum = [1, 450];

% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;

% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = ExperimentID+"/"+...
    expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Gather data from StatusFile
data = gather_up(StatusFileID);

%% Calculate More Summary Statistics
DT = 1/160;
trans = 60;
for i = 1:numel(data)
    % Make Summary Statistics for each Simulation Job
    disp(data{i})
    line = split(data{i},"/");
    TestID = line{3};

    % Now make the summary files
    SumID = ExperimentID + "/" + TestID + "/" +"Sensor_Data";
    tablename = "SensorDataT.txt";
    [status,len,stats] = create_sum_table_LARGE2(SumID,tablename,trans,DT);
    disp("Simulation "+num2str(i)+"(length = "+num2str(len)+") summary is done.")
end
%% Read the Original Morris Inputs
M = readmatrix("MorrisInputs.txt");
M = array2table(M);
%% Combine the results into 3 different experiment tables
M = readtable("Exp1_inTable.txt");
variableList = {"mean","sd","skew","kurt"};
StatusFileIDs = [ExperimentID+"/"+...
    expName+"_"+num2str(1)+"_"+num2str(150)+"_Status.txt",...
    ExperimentID+"/"+...
    expName+"_"+num2str(151)+"_"+num2str(300)+"_Status.txt",...
    ExperimentID+"/"+...
    expName+"_"+num2str(301)+"_"+num2str(450)+"_Status.txt"];

for i = 1:3
    % Create ExperimentResultTable
    expTab = combineResultsLarge(M(1+(i-1)*150:150+(i-1)*150,:),StatusFileIDs(i),variableList);
    saveTabID = ExperimentID+"/LARGE2ExperimentResultTable"+num2str(i)+".txt";
    writetable(expTab,saveTabID);
end
% Now go run the rest of the Morris Script
%% Look at the Morris Analysis Parquets

% Experiment Shape 
sh = 1;
elan = parquetread("MorrisResultAnalysisTable"+num2str(sh)+".parquet");

% Establish the proper row names
elan.Properties.RowNames=elan.x__index_level_0__;
% Drop the old row name column
elan.x__index_level_0__ = [];

%% Make a Scatter Plot of all of the Morris Results
hold on
scatter(elan.ErosionSeverityMuStar,elan.ErosionSeveritySigma,7,'r','filled')
scatter(elan.WindDirMuStar,elan.WindDirSigma,7,'b','filled')
scatter(elan.WindSpeedMuStar,elan.WindSpeedSigma,7,'k','filled')
scatter(elan.AirDensityMuStar,elan.AirDensitySigma,7,'g','filled')
scatter(elan.WindShearMuStar,elan.WindShearSigma,7,'cyan','filled')


title("Scatter of Morris Results")
xlabel("Mu Star")
ylabel("Sigma")
lgd = {"Erosion","WindDir","WindSpeed","AirDensity","WindShear"};
legend(lgd)
%% Subplot of Histograms
shapes = ["linear","quadratic","cubic"];% Shapes
for i = 1:3
    % Experiment Shape 
    sh = i;
    elan = parquetread("MorrisResultAnalysisTable"+num2str(sh)+".parquet");
    % Establish the proper row names
    elan.Properties.RowNames=elan.x__index_level_0__;
    % Drop the old row name column
    elan.x__index_level_0__ = [];
    for j = 1:5
        % Input
        ins = ["ErosionSeverity","WindDirNorm","AirDensityNorm",...
            "WindSpeedNorm","WindShearNorm"];
    subplot(3,5,5*(i-1)+j)
    eval("histogram(elan."+ins(j)+",15);");
    title(ins(j)+" Shape "+shapes(i))
    xlabel("Euclidean Norm of \mu^* and \sigma")
    ylabel("Count")
    end
end
%% Do an analysis of the average effects across outputs for each input
B = zeros(3,10);
for i = 1:3
    sh = i;
    elan = parquetread("MorrisResultAnalysisTable"+num2str(sh)+".parquet");
    
    % Establish the proper row names
    elan.Properties.RowNames=elan.x__index_level_0__;
    % Drop the old row name column
    elan.x__index_level_0__ = [];
    winddirmu = elan.WindDirMuStar;
    winddirsigma = elan.WindDirSigma;

    windspeedmu = elan.WindSpeedMuStar;
    windspeedsigma = elan.WindSpeedSigma;

    airdenmu = elan.AirDensityMuStar;
    airdensigma = elan.AirDensitySigma;

    shearmu = elan.WindShearMuStar;
    shearsigma = elan.WindShearSigma;

    ermu = elan.ErosionSeverityMuStar;
    ersigma = elan.ErosionSeveritySigma;

    B(i,:) = [mean(winddirmu(isfinite(winddirmu))),mean(winddirsigma(isfinite(winddirsigma))),...
        mean(windspeedmu(isfinite(windspeedmu))),mean(windspeedsigma(isfinite(windspeedsigma))),...
        mean(airdenmu(isfinite(airdenmu))),mean(airdensigma(isfinite(airdensigma))),...
        mean(shearmu(isfinite(shearmu))),mean(shearsigma(isfinite(shearsigma))),...
        mean(ermu(isfinite(ermu))),mean(ersigma(isfinite(ersigma)))];
end

%%
varnames = ["Wind Direction Mu","Wind Direction Sigma",...
    "Wind Speed Mu","Wind Speed Sigma",...
    "Air Density Mu","Air Density Sigma",...
    "Wind Shear Mu","Wind Shear Sigma",...
    "Erosion Severity Mu","Erosion Severity Sigma"];
BB = [B;[mean(B(:,1)),mean(B(:,2)),mean(B(:,3)),mean(B(:,4)),mean(B(:,5)),...
    mean(B(:,6)),mean(B(:,7)),mean(B(:,8)),mean(B(:,9)),mean(B(:,10))]];
bnames = ["Linear","Quadratic","Cubic","Overall"];
btable = array2table(BB,"VariableNames",varnames,"RowNames",bnames);
mkdir Data/Exp1/Analysis/
writetable(btable,"Data/Exp1/Analysis/SummaryResults.xls","FileType","spreadsheet","WriteRowNames",true)
%% Plot the results
hold on
for i = 1:5
    scatter(btable("Overall",:),varnames(2*i-1),varnames(2*i),"filled","SizeData",100)
    var = split(varnames(2*i-1));
    lgd{i} = var(1)+" "+var(2);
end
legend(lgd,location='northwest')
grid on
title("Across QOI Average Sensitivity Results")