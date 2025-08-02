% Plot data gathered from simulation experiments including:
% - time series
% - scatter plots of the data summary statistics
clc;close all;clear;
addpath funcs/
%%
% Grab the experiment name
expName = "Exp1";
% What were the first and last job numbers
JobNum = [1,450];
% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;

% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = ExperimentID+"/"+...
    expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Gather data from StatusFile
data = gather_up(StatusFileID);
%% Choose a time-series datatable to explore:
TabNum=10;
tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
dataTab = readtable(tableID);
%%
outputNameID = data{TabNum}+"/Sensor_Data/output_names.mat";
outnames = load(outputNameID);
OPNames=outnames.Output_Names;
%% Investigate time-series one at a time
% Note, transientes are assumed to disappear in the last 4800 entries of
% each ts-data column
s = plot_ts(OPNames,dataTab);
%% Plot Multiple Plots at Once
start = 100;
stop = 101;
batch = cell(1,stop-start);
iter=1;
for i = start:stop
    TabNum=i;
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    
    outputNameID = data{TabNum}+"/Sensor_Data/output_names.mat";
    outnames = load(outputNameID);
    OPNames=outnames.Output_Names;
    
    targets = [19,31,32,33];
    plot_series = [ones(1,numel(targets));targets];
    ttl = "WindDir = "+num2str(exp1Tab.WindDirection(i))+...
        " Wind Speed = "+num2str(exp1Tab.WindSpeed(i))+":";
    batch{1,iter} = {dataTab,OPNames,plot_series,ttl};
    iter = iter+1;
end


s = plot_multi(batch);
%% Let us look at a given result table
expresultID = ExperimentID+"/ExperimentResultTable"+num2str(JobNum(1))+...
    "_"+num2str(JobNum(2))+".txt";
exp1Tab = readtable(expresultID);
%% Plot the different erosion levels separately
as = unique(exp1Tab.Alpha);

for i = 1:numel(as)
    subplot(5,2,i)
    a = as(i);
    rows = find(exp1Tab.Alpha==a);
    scatter(exp1Tab(rows,:),"WindSpeed","GenPwrmean",...
        ColorVariable="WindShear",Marker="o",MarkerFaceColor="flat");
end
%% Plot a Scatter Plot of Linear Shape
% Color by Air Density
f = figure;
f.Position = [50 50 900 600];
scatter(exp1Tab(1:150,:),"WindSpeed","GenPwrmean",...
        ColorVariable="AirDensity",Marker="o",MarkerFaceColor="flat");
colorbar 
title("Generator Power vs Wind Speed; Color by Air Density")
ylabel("Generator power (kW)")
xlabel("Wind Speed (m/s)")
g = gca();g.FontSize = 18;
grid on
saveID = "Plots/"+"MorrisData"+"cbair"+".png";
print('-dpng',saveID)
%% Plot a Scatter Plot of Linear Shape
% Color by Wind Direction
f = figure;
f.Position = [50 50 900 600];
scatter(exp1Tab(1:150,:),"WindSpeed","GenPwrmean",...
        ColorVariable="WindDirection",Marker="o",MarkerFaceColor="flat");
colorbar 
title("Generator Power vs Wind Speed; Color by Wind Direction")
ylabel("Generator power (kW)")
xlabel("Wind Speed (m/s)")
g = gca();g.FontSize = 18;
grid on
saveID = "Plots/"+"MorrisData"+"cbwd"+".png";
print('-dpng',saveID)
%% Plot a Scatter Plot of Linear Shape
% Color by Wind Shear
f = figure;
f.Position = [50 50 900 600];
scatter(exp1Tab(1:150,:),"WindSpeed","GenPwrmean",...
        ColorVariable="WindShear",Marker="o",MarkerFaceColor="flat");
colorbar 
title("Generator Power vs Wind Speed; Color by Wind Shear")
ylabel("Generator power (kW)")
xlabel("Wind Speed (m/s)")
g = gca();g.FontSize = 18;
grid on
saveID = "Plots/"+"MorrisData"+"cbws"+".png";
print('-dpng',saveID)
%% Plot a Scatter Plot of Linear Shape
% Color by Er
f = figure;
f.Position = [50 50 900 600];
scatter(exp1Tab(1:150,:),"WindSpeed","GenPwrmean",...
        ColorVariable="Alpha",Marker="o",MarkerFaceColor="flat");
colorbar 
title("Generator Power vs Wind Speed; Color by Erosion Severity")
ylabel("Generator power (kW)")
xlabel("Wind Speed (m/s)")
g = gca();g.FontSize = 18;
grid on
saveID = "Plots/"+"MorrisData"+"cber"+".png";
print('-dpng',saveID)
%% Index to find where the erosion level was 1.
exp1Tab.order = [1:numel(exp1Tab(:,1))]';

as = unique(exp1Tab.Alpha);
bs = unique(exp1Tab.WindShear);
disp(as)
disp(bs)
rows = find(exp1Tab.Alpha==as(7));
star = exp1Tab(rows,:);
star = star(find(star.WindShear==bs(2)),:);

o = star.order;
%% Plot Multiple Plots at Once
batch = cell(1,numel(o));
iter=1;
for i = 1:numel(o)
    TabNum=o(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    
    outputNameID = data{TabNum}+"/Sensor_Data/output_names.mat";
    outnames = load(outputNameID);
    OPNames=outnames.Output_Names;
    
    targets = [19,31,32,33];
    plot_series = [ones(1,numel(targets));targets];
    
    ttl = "Air Density = "+num2str(exp1Tab.AirDensity(o(i)))+...
        " Wind Speed = "+num2str(exp1Tab.WindSpeed(o(i)))+":";
    batch{1,iter} = {dataTab,OPNames,plot_series,ttl};
    iter = iter+1;
end


s = plot_multi(batch);