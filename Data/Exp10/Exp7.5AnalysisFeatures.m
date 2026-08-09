clc;close;clear;
addpath funcs/
% Generate combined datatable for full experiment with more features
%% Stage 1: Make a status file that contains all of the experiments

% Grab the experiment name
expName = "Exp7.5";

% Stage 2: Create additional Features
JobNum = [1,50];

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
M = readtable("Exp7.5_inTable.txt");
variableList = {"mean","sd","skew","kurt"};

% Create ExperimentResultTable
expTab = combineResultsLarge(M,StatusFileID,variableList);
saveTabID = ExperimentID+"/LARGE2ExperimentResultTable1_50.txt";
writetable(expTab,saveTabID);

%% Repeat, but calculate the features using noisy data for
DT = 1/160;
trans = 60;
noise_level = 0.1;
bias_level  = 0.1;
noise_entries = [2:44];
parfor i = 1:numel(data)
    % Make Summary Statistics for each Simulation Job
    disp(data{i})
    line = split(data{i},"/");
    TestID = line{3};

    % Now make the summary files
    SumID = ExperimentID + "/" + TestID + "/" +"Sensor_Data";
    tablename = "SensorDataT.txt";
    [status,len,stats] = create_sum_table_LARGE2_noisy(SumID,tablename,trans,DT,noise_entries,noise_level,bias_level);
    disp("Simulation "+num2str(i)+"(length = "+num2str(len)+") summary is done.")
end
%% Combine those results into a new table
M = readtable("Exp7.5_inTable.txt");
variableList = {"mean","sd","skew","kurt"};

% Create ExperimentResultTable
expTab = combineResultsLargeNoisy(M,StatusFileID,variableList);
saveTabID = ExperimentID+"/LARGE2noisyExperimentResultTable1_50.txt";
writetable(expTab,saveTabID);
%%
T1 =      readtable("Data\Exp7\LARGE2ExperimentResultTable1_420.txt");
T2 = readtable("Data\Exp7\LARGE2noisyExperimentResultTable1_420.txt");
%%
figure

hold on
scatter(T1,"B1Er1","RtSpeedmean")
%scatter(T2,"B1Er1","B1N6Clmean")
figure
x = T1.B1N6Cdmean;
y = T2.B1N6Cdmean;
scatter(x,y,'filled')
hold on
a1 = min(x);b1 = min(y);
a2 = max(x);b2 = max(y);
a = [min(a1,b1), max(a2,b2)];
plot(a,a)
%%
plot(T1.RtSpeedmean/60)
%%
min(T1.RtSpeedmean)*.9/60
max(T1.RtSpeedmean)*1.1/60
%% Repeat, but calculate additional features
DT = 1/160;
trans = 60;
parfor i = 1:numel(data)
    % Make Summary Statistics for each Simulation Job
    disp(data{i})
    line = split(data{i},"/");
    TestID = line{3};

    % Now make the summary files
    SumID = ExperimentID + "/" + TestID + "/" +"Sensor_Data";
    tablename = "SensorDataT.txt";
    [status,len,stats] = create_sum_table_LARGE3(SumID,tablename,trans,DT);
    disp("Simulation "+num2str(i)+"(length = "+num2str(len)+") summary is done.")
end
%% Combine those results into a new table
M = readtable("Exp7.5_inTable.txt");
variableList = {"mean","sd","skew","kurt","rms","nfd","bp1","bp3p","l1d",'l1ac'};

% Create ExperimentResultTable
expTab = combineResultsLarge3(M,StatusFileID,variableList);
saveTabID = ExperimentID+"/LARGE3ExperimentResultTable1_50.txt";
writetable(expTab,saveTabID);