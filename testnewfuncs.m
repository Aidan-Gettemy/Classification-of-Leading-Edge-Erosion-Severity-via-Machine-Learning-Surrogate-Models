clc;close;clear
addpath funcs/
% Grab the experiment name
expName = "Exp1";

% Job Numbers
JobNum = [1, 450];

% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;

% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = ExperimentID+"/"+...
    expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Gather data from StatusFile
data = gather_up(StatusFileID);

% Choose a time series table to grab
i = 41;
disp(data{i})
line = split(data{i},"/");
TestID = line{3};

% Now make the summary files
SumID = ExperimentID + "/" + TestID + "/" +"Sensor_Data";
tablename = "SensorDataT.txt";

tsTable = readtable(SumID+"/"+tablename);

%% Now try some new functions on that data:

% Plot the rotor speed
plot(tsTable.Time,tsTable.YawBrTDxt)
%%
% We know that the frequncy of the data is 160 samples/second
signal = tsTable.B1N6Cd;
s = signal(numel(signal)-160*30:numel(signal));
% Try something related to power of the signal
[bw,flo,flh,pw]=obw(s,160);

power=pw/.99;
% I think power and bandwidth might be good things to keep
%% Mobility of the signal
% defined as the square root of the variance of the derivative of the
% signal over the variance of the signal 

mob = mobility(s)

% Complexity of the signal:
% defined as the mobility of the derivative of s over mobility of s
cp = complexity(s)

%% Nonstationary index 
% divide the time series into time increments.  Calculate the mean for each
% increment.  Find the standard deviation of those means

n=40; % Number of segments to find
[nonsi,conLoc,maxrat,firstrat,difloc] = nonstationaryInd(s,n);

% f = @(n) nonstationaryInd(s,n);
% 
% y = zeros(1,1000);
% for i = 1:numel(y)
%     y(1,i) = f(i);
% end
% plot(1:1000,y);
% 
% % We could find the location of the peaks of this curve
% 
% [peaks,locs] = findpeaks(y);
% hold on
% scatter(locs,peaks)
% max(peaks)
% % return the location of the max peak
% i = find(peaks==max(peaks));
% 
% scatter(locs(peaks==max(peaks)),peaks(i),'filled')
% scatter(locs(1),peaks(1),'filled')
% std(s)
% 
% % Some ideas of how to turn this into a statistic...
% %1) Look at the peaks.  Fit those to a logistic curve.  Report the location
% %of the inflection point of that logistic curve.  That could be an
% %indicator
% %2) What number of subdivisions does it take to be within epsilon of the
% %overall standard deviation.  Say epsilon = 5% of full standard deviation
% figure
% plot(1:1000,y-std(s))
% ydif = y-std(s);
% [peaks2,locs2] = findpeaks(y-std(s));
% z = find(peaks2>-0.05*std(s));
% locs2(z(1))
% hold on 
% scatter(locs2(z(1)),peaks2(z(1)))
% plot(1:1000,zeros(1,1000))
% g = find(ydif>-.05*std(s));
% scatter(g(1),ydif(g(1)))
%% Find the number of crossings

x = linspace(-3,3,10000);

f = @(x) sin(20*x);


s = f(x);

plot(x,s)
hold on
plot([-3,3],[0,0])

[num,mdif,stdfif] = crossings(s,160)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%