% Plot data gathered from simulation experiments including:
% - time series
% - scatter plots of the data summary statistics
clc;close all;clear;
addpath funcs/
%%
% Grab the experiment name
expName = "Exp2";
% What were the first and last job numbers
JobNum = [1,500];
% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;

% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = ExperimentID+"/"+...
    expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Gather data from StatusFile
data = gather_up(StatusFileID);
%% Choose a time-series datatable to explore:
TabNum=19;
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
expresultID = ExperimentID+"/ExperimentResultTable"+num2str(JobNum(1))+...
    "_"+num2str(JobNum(2))+".txt";
exp1Tab = readtable(expresultID);
start = 10;
stop = 15;
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
    subplot(3,2,i)
    a = as(i);
    rows = find(exp1Tab.Alpha==a);
    scatter(exp1Tab(rows,:),"WindSpeed","GenPwrmean",...
        ColorVariable="WindDirection",Marker="o",MarkerFaceColor="flat");
    title("Alpha = "+num2str(a))
end
%%
scatter(exp1Tab,"WindSpeed","GenPwrmean",...
        ColorVariable="Alpha",Marker="o",MarkerFaceColor="flat");

%% Plotting with the Big table
expTab = exp1Tab;
f = figure;
f.Position = [50 50 1000 750];

expTabstar = expTab(1:100,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'r','Marker','o','SizeData',70)
hold on

expTabstar = expTab(101:200,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'b','Marker','square','SizeData',70)

expTabstar = expTab(201:300,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'c','Marker','pentagram','SizeData',70)

expTabstar = expTab(301:400,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'g','Marker','diamond','SizeData',70)

expTabstar = expTab(401:500,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'k','Marker','^','SizeData',70)

legend({"Clean","Stage 1","Stage 2","Stage 3","Stage 4"},location="northwest")
title("Generator Power vs Wind Speed by Class for Testing Dataset")

g = gca();g.FontSize = 18;
grid on
xlabel("Wind Speed (m/s)")
ylabel("Generator Power (kW)")
saveID = "Plots/"+"TestDataPowerCurve"+".png";
print('-dpng',saveID)


%% Index to find where the erosion level was 1.
exp1Tab.order = [1:numel(exp1Tab(:,1))]';
% Use this to index where particular experiments are located
as = unique(exp1Tab.Alpha);
bs = unique(exp1Tab.WindShear);
disp(as)
%disp(bs)
rows = find(exp1Tab.Alpha==as(2));
star = exp1Tab(rows,:);
star = star((star.AirDensity<1.2),:);
star = star((star.WindSpeed<9),:);

o = star.order;
%% Index to find where the windspeed is around 6.
exp1Tab.order = [1:numel(exp1Tab(:,1))]';
% Use this to index where particular experiments are located
EL = unique(exp1Tab.Alpha);
WS = unique(exp1Tab.WindSpeed);

disp(EL)
%disp(bs)
for i = 1:numel(EL)
rows = find(exp1Tab.Alpha==EL(i));
star = exp1Tab(rows,:);
star = star((star.AirDensity>1.15&star.AirDensity<1.35),:);
star = star((star.WindSpeed<7.5&star.WindSpeed>6.5),:);
star = star((star.WindDirection<10&star.WindDirection>-10),:);
basket{i} = star.order;
star.order
end

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
%% Plot a blade profile vs the generator power
% Choose samples in each class that are about the same wind speed, wind dir
% and air density
% winddir ~ 0
% windspee ~ 9
% airdens ~ 1.29
tabs = [25,188,231,308,408];
f = figure;
f.Position = [50 50 1050 650];
for i = 1:5
    subplot(5,2,2*i)
    TabNum=tabs(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    plot(dataTab.Time,dataTab.GenPwr*1/1000,LineWidth=2)
    if i == 1;title("Simulated Generator Power (MW)",...
            'FontWeight','bold');end
    %ylabel("Er "+num2str((i-1)/4))
    ylabel([])
    xlabel([])
    ylim([0.700,1.220])
    g = gca();
    if i<5
        g.XTickLabel = [];
    end
    if  i == 5
        xlabel("Time (s)")
    end
    g = gca();
    g.FontSize = 16;
    grid on
    grid minor
end
for i = 1:5
    subplot(5,2,2*i-1)
    TabNum=tabs(i);
    x=exp1Tab(tabs(i),[5,6,7,8,9,10]).Variables;
    bar(x)
    if i == 1;title("Blade Erosion Severity Level",'FontWeight','bold');
    end
    ylabel(""+num2str(((2*i-1)-1)/8))
    %ylabel([])
    xlabel([])
    ylim([0,1])
    g = gca();
    if i<5
        g.XTickLabel = [];
    end
    if  i == 5
        xlabel("Blade Regions")
    end
    g = gca();
    g.FontSize = 16;
    %grid on
    %grid minor
end
sgtitle("Erosion Inputs and Power Simulation by Class",'FontSize',20,...
    'FontWeight','bold')
saveID = "Plots/pwrTS.png";
print('-dpng',saveID)