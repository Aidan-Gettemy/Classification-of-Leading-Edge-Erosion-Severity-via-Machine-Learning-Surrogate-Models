clc;close;clear;
% Create the blade erosion distribution 
% The mean value of each region is determined by a function which is
% evaluated at the center of the region.
% 
% The severity factor scales the function.  The mean factor for each region
% will also determine the covariance structure.  The off diagonals will be
% determined using a radial basis kernel with e^-(r*epsilon)^2
% 
% Problem is that we don't know epsilon...but we can say that it is a
% function of the severity factor; over time we would expect the
% correlation to grow stronger.
% 
% The diagonal of the covariance matrix can be a function of the mean
% factor for each region.  Overtime we expect the standard deviation to
% grow.

% Inspired by a Poisson process, we could set the standard deviation to be
% the square root of the mean value 
nodeLocs = [0, 2.8667, 5.6, 8.333, 11.75, ...
    15.85, 19.95, 24.05, 28.15, 32.25, 36.35, ...
    40.45, 44.55, 48.65, 52.75, 56.1667, 58.9, 61.633];

reg1 = [nodeLocs(4) nodeLocs(6)];
reg2 = [nodeLocs(6) nodeLocs(8)];
reg3 = [nodeLocs(8) nodeLocs(10)];
reg4 = [nodeLocs(10) nodeLocs(12)];
reg5 = [nodeLocs(12) nodeLocs(14)];
reg6 = [nodeLocs(14) nodeLocs(18)];

total_len = nodeLocs(18) - nodeLocs(4);

mids = zeros(6,1);

for i = 1:6
    phrase = "reg"+num2str(i);
    phrase = "("+phrase+"(2)+"+phrase+"(1))/2" +"-nodeLocs(4)";
    phrase = "("+phrase+")/total_len";
    phrase = "mids("+num2str(i)+",1) = "+phrase+";";
    eval(phrase)
end

% Different erosion shape functions 
f = @(x,a) a*x;

g = @(x,a) a*x.^2;

h = @(x,a) a/2+a/2*x;

q = @(x,a) sqrt(a*x);

covar = @(x,y,a,l) a*a*exp(-((x-y).^2)/(2*l^2));

a=.3;

% plot(linspace(-2,2,256),covar(linspace(-2,2,256),0,1/a^2))

% Construct the mean vector

mean_er = f(mids,a);

% Construct the covariance matrix

for i = 1:numel(mids)
    for j = i:numel(mids)
        

        l = (mids(i)+mids(j))/2;
        l = sqrt(l);
        m = f(min(mids(i),mids(j)),a);
        

        Cov_er(i,j) = covar(mids(i),mids(j),(m)*1/10,l);
    
        Cov_er(j,i) = Cov_er(i,j);
       
        
    end
end

rng('default')  % For reproducibility
R = mvnrnd(mean_er,Cov_er,100);

for i = 1:numel(R(:,1))
    for j = 1:numel(R(1,:))
        R(i,j) = min(max(R(i,j),0),1);
    end
end
%% Use the function bladeErDist.m to generate samples for .25,.5,.75,1 levels and plot the box plots
% linear value for the mean values
addpath erosionfuncs\
f = figure;
f.Position = [50 50 1000 770];
for i = 1:4
    subplot(2,2,i)
    R = bladeErDist(i/4,100);
    boxplot(R,'Labels',{'1','2','3','4','5','6'},'MedianStyle','line')
    set(findobj(gca,'type','line'),'linew',2)
    ylim([0,1])
    ylabel("Erosion Severity")
    title("Severity Factor = "+num2str(i/4))
    g = gca();g.FontSize=15;
end
sgtitle("Average Blade Erosion Profiles"+newline+" ",'FontSize',20,'FontWeight','bold')

saveID = "Plots/"+"BoxPlots.png";
print('-dpng',saveID)

%% Also plot 3 different example blades from each level in a grid
f = figure;
f.Position = [50 50 1200 770];
iter = 1;

for i = 1:4
    subplot(4,1,i)
    R = bladeErDist(iter/4,1);
    bar(R)
    set(findobj(gca,'type','line'),'linew',2)
    ylim([0,1])
    ylabel("Erosion")
    title("Severity Factor = "+num2str(iter/4))
    if mod(i,1) == 0;iter = iter+1;end
    g = gca();
    g.YGrid = 'on';
    g.FontSize=15;
end
sgtitle("Sample Blade Erosion Profiles"+newline+" ",'FontSize',20,'FontWeight','bold')

saveID = "Plots/"+"SamplePlots.png";
print('-dpng',saveID)

%%
f = figure;
f.Position = [50 50 1000 770];
a = 1;
[S,AX,BigAx,H,HAx] = plotmatrix(R);
title(BigAx,"Region vs Region Erosion Severity = "+num2str(a))
for i = 1:6
    xlabel(AX(6*i),"Region "+num2str(i)+"   ")
    ylabel(AX(i),"Region "+num2str(i)+"   ")
    AX(i).FontSize=15;AX(i*6).FontSize=15;
    xlim(HAx(i),[-.1,1.1])
    
end
for i = 1:numel(AX)
    xlim(AX(i),[-.1,1.1])
    ylim(AX(i),[-.1,1.1])
    AX(i).XGrid = 'on';
    AX(i).YGrid = 'on';
    S(i).MarkerSize = 3;
    S(i).Marker = "o";
    S(i).MarkerFaceColor = '[     0    0.4470    0.7410]';
    S(i).MarkerEdgeColor = 'k';
end
g = gca();
g.FontSize = 18;

saveID = "Plots/"+"BladeErosionDistribution1.png";
print('-dpng',saveID)

%%
figure
for i = 1:9
    subplot(3,3,i)
    ind=3*i;
    xs=["R1","R2","R3","R4","R5","R6"];
    b=bar(xs,R(ind,:));
    xtips1 = b(1).XEndPoints;
    ytips1 = b(1).YEndPoints;
    labels1 = string(R(ind,:));
    text(xtips1,ytips1,labels1,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom')
    title("Blade Profile for Row "+num2str(ind))
    ylabel("Erosion Severity Level")
    ylim([0,1])
end
%%
xs = linspace(0,1,200);
f = @(x) 10+-log(x);
plot(xs,f(xs))
%%
plot([0;mids;1],f([0;mids;1],a),"Color","#0099cc","Marker","o","MarkerFaceColor","#1aff1a",...
    "LineWidth",3,"MarkerEdgeColor","#248f24")
hold on
scatter([0,1],[f(0,a),f(1,a)],100,"blue","filled")

xlim([0,1])
ylim([0,1])