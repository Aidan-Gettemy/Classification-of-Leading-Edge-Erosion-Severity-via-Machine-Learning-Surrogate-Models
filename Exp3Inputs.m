clc;close;clear;
addpath funcs\
addpath erosionfuncs\
%% Run this code to generate a table of inputs for experiment 3

% Experiment 3: Guassian Process Training Set

% We have determined that the effect of wind shear appears to be minimal

% We will use the linear blade erosion distribution since it is most
% likely 

expName = "Exp3";

% Input Table ID
inTableID = expName+"_inTable.txt";

% The input column names
invarNames = ["WindDirection","WindSpeed","AirDensity","WindShear",...
    "B1Er1","B1Er2","B1Er3","B1Er4","B1Er5","B1Er6",...
    "B2Er1","B2Er2","B2Er3","B2Er4","B2Er5","B2Er6",...
    "B3Er1","B3Er2","B3Er3","B3Er4","B3Er5","B3Er6"...
    "Alpha","Shape"];
%%
% After the latin hyper-cube, we have to map those values between 0 and 1
% into the experimental ranges.  These have been set for the environmental
% variables as the same as in the Morris Method Experiment

% Now, to determine the erosion regions, we will map the latin hyper-cube
% into relevant regions for each erosion severity class.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Severity data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Number of Classes 
classes = 5; 
% Number of samples per Class
samples = 100;
% Total number of rows
num = classes*samples;
% Erosion Severity Values
severities = linspace(0,1,classes);
storage = zeros(num,6);
for i = 1:5
    severity = severities(i);
    storage((i-1)*samples+1:i*samples,:)=bladeErDist(severity,samples);
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Latin Hyper Cube 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dim = 9;
% Now we set the number of generated samples for training
gensamples = 50;
num = gensamples*classes;
p = lhsdesign(num,dim,'Criterion','correlation','iterations',10);
blade_coverages = zeros(5,6,2);
for i = 1:classes
    % Find the maximum and minimum of each region for each class
    for j = 1:6
        blade_coverages(i,j,1) = min(storage((i-1)*samples+1:i*samples,j));
        blade_coverages(i,j,2) = max(storage((i-1)*samples+1:i*samples,j));
        blade_coverages(i,j,3) = mean(storage((i-1)*samples+1:i*samples,j));
        blade_coverages(i,j,4) = std(storage((i-1)*samples+1:i*samples,j));
    end
end

for i = 1:classes
    for j = 4:9
        a = 2;
        p((i-1)*gensamples+1:i*gensamples,j) = min(max(blade_coverages(i,j-3,3) -...
            a * blade_coverages(i,j-3,4) + ...
            p((i-1)*gensamples+1:i*gensamples,j)*2*a*blade_coverages(i,j-3,4),...
            0),1);
    end
end

results = p(:,4:9);

% Check if the GP training points have good coverage 
%figure
%subplot(1,2,1)
%plotmatrix(results)
%hold on
%subplot(1,2,2)
%plotmatrix(storage)
%title("Plotting Samples from the Distribution vs Samples from LHC Mapped Points")

% You should see 4 distinct clusters and the origin
figure
scatter3(storage(:,1),storage(:,2),storage(:,6),10,'filled')
hold on
scatter3(results(:,1),results(:,2),results(:,6),10,'filled')
legend({"Correlated Samples","LHC Points"})
%% Overlap
f = figure;
f.Position = [50,50,1000,750];
for i = 1:6
    for j = 1:6
        subplot(6,6,6*(j-1)+i)
        scatter(storage(:,i),storage(:,j),6,'b','filled')
        hold on
        scatter(results(:,i),results(:,j),6,'r','filled')
        xticks([0:.5:1])
        
        yticks([0:.5:1])
        
        xlim([0,1])
        ylim([0,1])
        
        g = gca();
        g.FontSize = 15;
        g.XTickLabel = [];
        g.YTickLabel = [];
        g.YMinorTick = "on";
        g.XMinorTick = "on";
        g.YMinorGrid = "on";
        g.XMinorGrid = "on";

        if j == 6
            xlabel("Region "+num2str(i));
            g.XTickLabel = ["0",".5","1"];
            
        end
        if j == 1
            if i == 6
                
                legend(["Test Data","LHC"],"Location","southeast")
                g.FontSize = 18;
            end
        end
        if i == 1
            ylabel("Region "+num2str(j));
            g.YTickLabel = ["0",".5","1"];
            
        end
        
        
    end
end
sgtitle("Coverage of Latin Hyper Cube Samples")
saveID = "Plots/CoverageLHC.png";
print('-dpng',saveID)
%% Make the Input Table
% Number of inputs
dim = numel(invarNames);
M = zeros(num,dim);
class = 0;
% Build the matrix of input values/names
for i = 1:numel(M(:,1))
    % Environmental Variables
    M(i,1) = -15+30*p(i,1); % Wind Direction [-15, 15]
    M(i,2) = 3+22*p(i,2); % Wind Speed [3, 25]
    M(i,3) = 1.10+(1.42-1.10)*p(i,3);% Air Density [1.10, 1.42]
    M(i,4) = .2; % Set the wind shear level
    % Erosion Levels for Blade Regions
    erprofile = results(i,:);
    M(i,5:end-2) = [erprofile,erprofile,erprofile];
    M(i,end-1) = class/4;
    if mod(i,gensamples)==0
        class = class+1;
    end
    M(i,end) = 1;
end
%% Build the table and save it
% We only need ~1/3 as many of the clean samples
inputDesignTab = array2table(M(gensamples-9:end,:),"VariableNames",invarNames);
writetable(inputDesignTab,inTableID)

