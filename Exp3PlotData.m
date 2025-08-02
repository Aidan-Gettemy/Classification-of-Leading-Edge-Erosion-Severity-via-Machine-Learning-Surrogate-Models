% Plot data gathered from simulation experiments including:
% - time series
% - scatter plots of the data summary statistics
clc;close all;clear;
addpath funcs/
%%
% Grab the experiment name
expName = "Exp3"; 
% What were the first and last job numbers
JobNum = [1,210];
% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;

% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = ExperimentID+"/"+...
    expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Gather data from StatusFile
data = gather_up(StatusFileID);
%% Choose a time-series datatable to explore:
TabNum=50;
tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
dataTab = readtable(tableID);
%% We plot some time series.  One for each class
% Choose samples in each class that are about the same level.
tabs = [4,42,89,142,205];
f = figure;
f.Position = [50 50 1050 650];
for i = 1:5
    subplot(5,1,i)
    TabNum=tabs(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    plot(dataTab,"Time","RootMxb1",LineWidth=2)
    ws(i) = exp1Tab.WindSpeed(tabs(i));
    ylabel("Er "+num2str((i-1)/4))
    %ylabel([])
    xlabel([])
    ylim([-3500,5000])
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
sgtitle("Blade Root Moment (kN-m)")
saveID = "Plots/rootTS.png";
print('-dpng',saveID)
%%
tabs = [4,42,89,142,205];
f = figure;
f.Position = [50 50 1050 650];
for i = 1:5
    subplot(5,1,i)
    TabNum=tabs(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    plot(dataTab,"Time","TipALxb1",LineWidth=2)
    
    ylabel("Er "+num2str((i-1)/4))
    %ylabel([])
    xlabel([])
    ylim([-5,25])
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
sgtitle("Tip Acceleration (m/s^2)")
saveID = "Plots/tipTS.png";
print('-dpng',saveID)
%%
tabs = [4,42,89,142,205];
f = figure;
f.Position = [50 50 1050 650];
for i = 1:5
    subplot(5,1,i)
    TabNum=tabs(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    plot(dataTab,"Time","B1N6Cl",LineWidth=2)
    
    ylabel("Er "+num2str((i-1)/4))
    %ylabel([])
    xlabel([])
    ylim([.45,1.15])
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
sgtitle("Blade Lift Sensor (-)")
saveID = "Plots/clTS.png";
print('-dpng',saveID)
%%
tabs = [4,42,89,142,205];
f = figure;
f.Position = [50 50 1050 650];
for i = 1:5
    subplot(5,1,i)
    TabNum=tabs(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    plot(dataTab,"Time","B1N6Cd",LineWidth=2)
    
    ylabel("Er "+num2str((i-1)/4))
    %ylabel([])
    xlabel([])
    ylim([0,.075])
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
sgtitle("Drag Sensor (m/s^2)")
saveID = "Plots/CdTS.png";
print('-dpng',saveID)
%%
tabs = [4,42,89,142,205];
f = figure;
f.Position = [50 50 1050 650];
for i = 1:5
    subplot(5,2,2*i)
    TabNum=tabs(i);
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    plot(dataTab,"Time","GenPwr",LineWidth=2)
    
    %ylabel("Er "+num2str((i-1)/4))
    ylabel([])
    xlabel([])
    ylim([1500,4500])
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
    subplot(5,2,i)
    TabNum=tabs(i);
    tableID = "Exp3_inTable.txt";
    dataTab = readtable(tableID);
    plot(dataTab.Time.Variables,dataTab.GenPwr.Variables,LineWidth=2)
    
    %ylabel("Er "+num2str((i-1)/4))
    ylabel([])
    xlabel([])
    ylim([1500,4500])
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
sgtitle("Generator Power (kW)")
saveID = "Plots/pwrTS.png";
print('-dpng',saveID)
%%
outputNameID = data{TabNum}+"/Sensor_Data/output_names.mat";
outnames = load(outputNameID);
OPNames=outnames.Output_Names;
%% Investigate time-series one at a time
% Note, transientes are assumed to disappear in the last 4800 entries of
% each ts-data column
s = plot_ts(OPNames,dataTab);
%% Plot Multiple Plots at Once
start = 45;
stop = 55;
batch = cell(1,stop-start);
iter=1;
for i = start:stop
    TabNum=i;
    tableID = data{TabNum}+"/Sensor_Data/SensorDataT.txt";
    dataTab = readtable(tableID);
    
    outputNameID = data{TabNum}+"/Sensor_Data/output_names.mat";
    outnames = load(outputNameID);
    OPNames=outnames.Output_Names;
    
    plot_series = [1,1,1,1,1,1;20:25];
    ttl = "Plot Variables for Test #"+num2str(i);
    batch{1,iter} = {dataTab,OPNames,plot_series,ttl};
    iter = iter+1;
end
s = plot_multi(batch);

%% Plot result table generator power vs wind speed
expresultID = "Data/Exp3/LARGE2ExperimentResultTable1_210.txt";
exp1Tab = readtable(expresultID);
exp1Tab.AirDensity = exp(10*(exp1Tab.AirDensity-1));
scatter(exp1Tab,"WindSpeed",...
    "GenPwrmean","filled","SizeVariable","AirDensity","ColorVariable","Alpha")
c = colorbar;
c.Label.String = 'Erosion';
title("Generator Power vs Wind Speed")
legend({"Size by AirDensity"})
%% Plot the input points against each other 
f = figure;
f.Position = [50,50,1000,750];
ts = [1,2,10];
sel = ts;
names = ["Wind Direction ($^{\circ}$)","Wind Speed ($ms^{-1}$)","Erosion Level Region 6 (-)"];
% for i = 1:3
%     for j = 1:3
%         subplot(3,3,3*(j-1)+i)
%         scatter(exp1Tab(161:210,ts(i)).Variables,exp1Tab(161:210,ts(j)).Variables,'filled')
% 
%         %xticks([0:.5:1])
% 
%         %yticks([0:.5:1])
% 
%         %xlim([0,1])
%         %ylim([0,1])
% 
%         g = gca();
%         g.FontSize = 15;
%         %g.XTickLabel = [];
%         %g.YTickLabel = [];
%         g.YMinorTick = "on";
%         %g.XMinorTick = "on";
%         g.YMinorGrid = "on";
%         %g.XMinorGrid = "on";
% 
%         if j == 3
%             xlabel(names(i));
% 
%         end
% 
%         if i == 1
%             ylabel(names(j));
% 
%         end
% 
% 
%     end
% end

tiledlayout(numel(sel),numel(sel));

for i = 1:(numel(sel))
    for j = 1:(numel(sel))
        nexttile
        if i == j
            %[fp,xfp] = kde(exp1Tab(161:210,ts(i)).Variables);
            % plot(xfp,fp,'r')
            % hold on
            % [fp,xfp] = kde(X_sim(:,[i]));
            % plot(xfp,fp,'b')
            histogram(exp1Tab(161:210,ts(i)).Variables,'NumBins',8)
            %legend({'Real Density','Estimated Density'},'FontSize',4)
            if i == numel(sel)
                xlabel(sprintf('%s',names(j)),'Interpreter','latex')
            end
            if j == 1
                ylabel(sprintf('%s',names(i)),'Interpreter','latex')
            end
            fontname(gca,'Helvetica')
            g = gca;g.FontSize = 14;
        elseif i > j
            hold on
            scatter(exp1Tab(161:210,ts(j)).Variables,exp1Tab(161:210,ts(i)).Variables,'filled')

            % gm = fitgmdist(X_sim(:,[i,j]), 1);
            % gmPDF = @(x,y) arrayfun(@(x0,y0) pdf(gm,[x0 y0]),x,y);
            % fcontour(gmPDF,[-0.1 0.1])
            
            %legend({'Contour','Real Data'},'FontSize',2)
            if i == numel(sel)
                xlabel(sprintf('%s',names(j)),'Interpreter','latex')
            end
            if j == 1
                ylabel(sprintf('%s',names(i)),'Interpreter','latex')
            end
            % scatter(X_sim(:,[sel(i)]),X_sim(:,[sel(j)]),...
            %     10,'.')
            fontname(gca,'Helvetica')
            g = gca;g.FontSize = 14;
        else
            set(gca,'xtick',[])
            set(gca,'ytick',[])
            fontname(gca,'Helvetica')
            g = gca;g.FontSize = 14;
            axis off
        end
    end
end
%sgtitle("Selected Variables: Latin Hyper Cube Samples: Erosion Severity 1")
saveID = "Plots/UpdatedCoverageLHC.pdf";
ax = gcf;
exportgraphics(ax,saveID,'Resolution',300)
%% Plotting with the Big table
expresultID = "Data/Exp3/LARGE2ExperimentResultTable1_260.txt";
expTab = readtable(expresultID);

expTabstar = expTab(1:20,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'r')
hold on

expTabstar = expTab(21:80,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'b')

expTabstar = expTab(81:140,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'c')

expTabstar = expTab(141:200,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'g')

expTabstar = expTab(201:260,:);
scatter(expTabstar,"WindSpeed","GenPwrmean","filled","MarkerFaceColor",'k')

legend({"Clean","Stage 1","Stage 2","Stage 3","Stage 4"},location="northwest")
title("Plot of Gen Power vs Wind Speed for GP Training Dataset")

%% Index to find where the erosion level was 1.
expresultID = "Data/Exp3/ExperimentResultTable1_260.txt";
exp1Tab = readtable(expresultID);
exp1Tab.order = [1:numel(exp1Tab(:,1))]';

as = unique(exp1Tab.Alpha);
bs = unique(exp1Tab.WindShear);
disp(as)
disp(bs)
rows = find(exp1Tab.Alpha==as(1));
star = exp1Tab(rows,:);
%star = star(find(star.WindShear<.1 & star.WindShear>.05),:);

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
    
    targets = [26,27,28,29,30,31];
    plot_series = [ones(1,numel(targets));targets];
    
    ttl = "Wind Shear = "+num2str(exp1Tab.WindShear(o(i)))+...
        " Wind Speed = "+num2str(exp1Tab.WindSpeed(o(i)))+":";
    batch{1,iter} = {dataTab,OPNames,plot_series,ttl};
    iter = iter+1;
end


s = plot_multi(batch);
