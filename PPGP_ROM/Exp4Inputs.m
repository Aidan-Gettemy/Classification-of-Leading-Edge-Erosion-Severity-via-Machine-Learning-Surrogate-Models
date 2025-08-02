clc;close;clear;
addpath ..\funcs\
addpath ..\erosionfuncs\

%% Run this code to generate a table of inputs for experiment 4

% Experiment 4: Inputs for PPGP Emulation
expName = "Exp4";

% Input Table ID
inTableID = expName+"_inTable.txt";

% The input column names
invarNames = ["WindDirection","WindSpeed","AirDensity","WindShear",...
    "B1Er1","B1Er2","B1Er3","B1Er4","B1Er5","B1Er6",...
    "B2Er1","B2Er2","B2Er3","B2Er4","B2Er5","B2Er6",...
    "B3Er1","B3Er2","B3Er3","B3Er4","B3Er5","B3Er6"...
    "Alpha","Style"];

% Build the matrix of input values/names
%% Build the matrix of input values/names

% We will build the inputs using the latin hyper cube and the erosion
% distribution

% Number of Classes 
classes = 5; 
% Number of samples per Class
samples = 1000;
% Total number of rows
num = classes*samples;
% Erosion Severity Values
Er_classes = linspace(0,1,classes);
% Holding Matrix
I = zeros(num,numel(invarNames));

% Use a latin-hyper cube to choose wind direction, wind speeed, and shear
% values

dim = 3;
p = lhsdesign(num,dim,'Criterion','correlation','iterations',10);

% Wind Direction
I(:,1) = -15+30*p(:,1);
% Wind Speed 
I(:,2) = 3+22*p(:,2);
% Air Density
I(:,3) = 1.10+(1.42-1.10)*p(:,3);
% Wind Shear
I(:,4) = ones(num,1)*.2;
% Set the blade shape type
I(:,end) = ones(num,1)*1; % Shape is linear

% Draw samples from the erosion distribution
for i = 1:classes
    erprofile = bladeErDist(Er_classes(i),samples);
    I((i-1)*samples+1:i*samples,5:end-2) = [erprofile,erprofile,erprofile];
    I((i-1)*samples+1:i*samples,end-1) = Er_classes(i)*ones(samples,1);
end

%% Check the erosion data Distribution
for j = 1:5
    figure
    [S,AX,BigAx,H,HAx] = plotmatrix(I((j-1)*samples+1:j*samples,5:10));
    title(BigAx,"Scatter Plots of Erosion Level Region vs Region for Severity = "+num2str(Er_classes(j)))
    for i = 1:6
        title(HAx(i),"Histogram Region "+num2str(i))
        xlabel(AX(6*i),"Region "+num2str(i))
        ylabel(AX(i),"Region "+num2str(i))
        for k = 1:6
            xlim(AX(i+(k-1)*6),[0,1])
            ylim(AX(i+(k-1)*6),[0,1])
        end
    end
end

%%
% Build the table and save it
inputDesignTab = array2table(I,"VariableNames",invarNames);
writetable(inputDesignTab,inTableID)


