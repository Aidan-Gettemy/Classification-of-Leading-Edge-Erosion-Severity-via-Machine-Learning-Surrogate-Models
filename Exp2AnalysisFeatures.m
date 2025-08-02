clc;close;clear;
addpath funcs/
% Generate combined datatable for full experiment with more features
%% Stage 1: Make a status file that contains all of the experiments

% Grab the experiment name
expName = "Exp2";

% Stage 2: Create additional Features
JobNum = [1, 500];

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
%% Combine the results into 3 different experiment tables
M = readtable("Exp2_inTable.txt");
variableList = {"mean","sd","skew","kurt"};

% Create ExperimentResultTable
expTab = combineResultsLarge(M,StatusFileID,variableList);
saveTabID = ExperimentID+"/LARGE2ExperimentResultTable"+num2str(i)+".txt";
writetable(expTab,saveTabID);