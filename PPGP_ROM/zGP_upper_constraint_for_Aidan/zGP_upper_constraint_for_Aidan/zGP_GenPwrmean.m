clc;close;clear;
%% Use a zGP to fit the wind turbine power output:
addpath('../../RobustGaSP_matlab/functions/');
addpath('zGP_upper_constraint_for_Aidan/');

% Goal: predict the mean generator power
dataId = '../../../Data/Exp3/LARGE2ExperimentResultTable1_430.txt';
data = readtable(dataId);
% What percent of the data to train on?
percent = .7; % <- Percent tested on

% Return the data for testing and training 
[In_train,Out_train,In_test,Out_test] = GenPwrmeanData(data, percent);

%% Preprocess the power data so that its maximum is 1
Out_train_star = Out_train./5000;

% Set the upper bound for the zGP
UB = 1;

% Reconfigure the Starting Data
yimp = Out_train_star;
inds=find(yimp>UB);
yimp(inds)=UB;

ystart=yimp;

% Define how many samples to take to estimate the non-limited data
Ngibbs=2000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This is where we start the negative samples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if UB~=0 %shift and flip to have >=0 as the constraint
    ystart=-(ystart-UB);
end

% Define X
X = In_train;
%% This does "batch sampling" to get an intitial set of negative sampleings
output=RLW_init_impute(X,ystart); 
yimputesave=output{1};
sigsp=output{2};
yimp=median(yimputesave,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This next  bit is all to arrange order of the design to have [positive
%outpus, closest zeros in design  space]; This is what gets fed into
%zGP_gibbs_nrz_optmean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y=yimp;
N=length(y);
indsp=find(y>0);
indsz=find(y<0);
yp=y(indsp);
Np=length(indsp);
xdp=X(indsp,:);
yn=y(indsz);
Nz=length(indsz);
xdn=X(indsz,:);
yRL=median(yimputesave,2);
distnp=zeros(Nz,Np);
%%%%%%%%%%%%%%%%%%%%%%%%
%extra snip to calculate probs of zeros
%%%%%%%%%%%%%%%%%%%%%%%%%
mat52 = @(d) (1+sqrt(5)*d+(5/3)*d.^2).*exp(-sqrt(5)*d); 
Np=length(indsp);
B=zeros(Nz); %correlation matrix of xp points
Btemp=zeros(Nz);

options.trend=[ones(Np,1)  xdp];
options.zero_mean  = false;
options.nugget_est = false;

modelp=ppgasp(xdp,yp,options);

options.testing_trend=[ones(Nz,1)  xdn];
options.mean_only  = false;

pred_model=predict_ppgasp(modelp,xdn,options);
pmean=pred_model.mean;
% figure(1)
% plot(pmean,'*')
psd=pred_model.sd;
%hold on
for k=1:length(pmean)
    %line([k k],[pmean(k)-2*psd(k) pmean(k)+2*psd(k)])
    Pn(k)=1/2*(1+erf(-pmean(k)/(psd(k)*sqrt(2))));
end
%line([0 100],[0 0],'linewidth',3)
  
for j=1:Nz
    for k=1:Np
        distnp(j,k)=sqrt((xdn(j,1)-xdp(k,1)).^2+(xdn(j,2)-xdp(k,2)).^2);
    end
end
mindist=min(distnp');
[valsmd  indsmd]=sort(mindist);
[valspn  indspn]=sort(Pn);
Ntemp=round(.66*length(indspn));%.66
indsadd=intersect(indspn(1:Ntemp), indsmd(1:Ntemp));

Ninclude=length(indsadd);
indsrest=setdiff(1:1:Nz,indsadd);
xzs=[xdn(indsadd,:); xdn(indsrest,:)];
xall=[xdp; xzs];
yall=[yRL(indsp); yRL(indsz(indsadd)); yRL(indsz(indsrest))];
xp_zp=[xdp; xdn(indsadd,:)];
yp_zp=[yRL(indsp); yRL(indsz(indsadd))];

options.trend=[ones(Np+Ninclude,1)  xp_zp];
options.zero_mean  = false;
options.nugget_est = false;
model=ppgasp(xp_zp,yp_zp,options);

% figure(2)
% plot(mindist,Pn,'*')
% hold on
% plot(mindist(indsadd),Pn(indsadd),'r*')

%% Imputation 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Imputing negative responses to design points that have zero outputs via zGP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
locs=[0 0]; % specific for another problem, leave as zeros for now
output=zGP_gibbs_nrz_optmean(xall,yall,Ngibbs,locs, Ninclude); %This takes the initial set of negative samples and refines them with Gibbs sampling
                %output{1} is set of Gibbs samplings for all y
                %output{2} are (square of) range parameter

                %samples          
temp=output{1};

for kk=1:size(X,1)  %rearrange response back to original design
    inds(kk)=find(X(kk,2)==xall(:,2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This is the main output of the zGP algorithm. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Return the estimated values
yzgp=mean(temp(inds,1001:5:end),2);

%% Now that we have the zGP ready data, we can train the GP
if UB~=0
    yzgp=-yzgp+UB;
    ystart=-ystart+UB;
end
options.trend=[ones(N,1)  X];
options.zero_mean  = false; %these two probably don't need repeated
options.nugget_est = false;

% At last, the model
modelzgp=ppgasp(X,yzgp,options);
%% Test the model
xyr = In_test;

options.testing_trend=[ones(numel(xyr(:,1)),1)  xyr];
options.mean_only  = false; 

pred_model=predict_ppgasp(modelzgp,xyr,options);
pmean=min(5000*pred_model.mean,5000);
pstd = 5000*pred_model.sd;
truemean = Out_test;

% First Plot
figure
scatter(pmean,Out_test,30,"cyan","filled",MarkerEdgeColor="k")
hold on
plot([0,5000],[0,5000],LineWidth=4)
xlabel('Predicted Generator Power')
ylabel("True Generator Power")
title("Scatter Plot of Generator Power zGP")

% Second Plot
[B,I] = sort(truemean);

% Number of Points to show
points = 50;
p = points/numel(Out_test);
cvpart = cvpartition(numel(Out_test),'HoldOut',p);

figure
errorbar(1:points,pmean(I(test(cvpart))),...
    2*pstd(I(test(cvpart))),"o","MarkerSize",5,...
    "MarkerEdgeColor","blue","MarkerFaceColor",[0.65 0.85 0.90])
hold on
scatter(1:points,Out_test(I(test(cvpart))),10,'filled')
legend(["Predictions","True Values"],fontsize=10,Location="southeast")
xlabel("True Generator Power (kW)",fontsize=10)
ylabel("Predicted Generator Power (kW)",fontsize=10)
title("Range Limited GP for Generator Power",fontsize=10)

% Count the number of points that land in the predicted intervals 
count = 0;
for i = 1:numel(pmean)
    if Out_test(i) > pmean(i)-2*pstd(i)
        if Out_test(i) < pmean(i)+2*pstd(i)
            count = count+1;
        end
    end
end
disp(['Percent of True Power within Predicted Interval is ',num2str(100*count/numel(Out_test))])

%% Prepare to do some more complex plotting
expX = zeros(100,9);
a = linspace(-25,25)';
expX(:,1) = a; % Wind Direction
ws = 9;
expX(:,2) = ws*ones(100,1); % Wind Speed
expX(:,3) = 1.225*ones(100,1); % Air Density

options.testing_trend=[ones(numel(expX(:,1)),1)  expX];
options.mean_only  = false; 
figure
pred_model=predict_ppgasp(modelzgp,expX,options);
pmean=min(5000*pred_model.mean,5000);
pstd = 5000*pred_model.sd;
errorbar(a,pmean,2*pstd,"o","MarkerSize",10,...
    "MarkerEdgeColor","blue","MarkerFaceColor",[0.65 0.85 0.90])
legend("Wind Speed = "+num2str(ws))
xlabel("Wind Direction (degrees")
ylabel("Generator Power (kW)")
title("Predicted Generator Power vs Wind Direction")

%% Now make a surface plot
addpath('../../../erosionfuncs/')
% Make a Grid for plotting
[xx,yy] = meshgrid(3:.2:25, 0:.01:1.1);

Ngrid=length(xx);
NN=Ngrid*Ngrid;
BOsurf=zeros(numel(xx(:,1)));

yyr=reshape(yy,NN,1);
xxr=reshape(xx,NN,1);

expX = zeros(NN,9);
expX(:,2) = xxr; % Wind Speed
expX(:,1) = 0*ones(NN,1); % Wind Direction
expX(:,3) = 1.225*ones(NN,1); % Air Density 

% Fill in the erosion information according to the linear erosion shape
% function
for i = 1:numel(yyr)
    expX(i,4:9) = erShape(1,yyr(i));
end

options.testing_trend=[ones(numel(expX(:,1)),1)  expX];
options.mean_only  = false; 
pred_model=predict_ppgasp(modelzgp,expX,options);
pmean=min(5000*pred_model.mean,5000);
pstd = 5000*pred_model.sd;

pmean=reshape(pmean,Ngrid,Ngrid);
%% Plot the Predicted Surface
zgpmean=BOsurf;
for k=1:numel(xx(:,1))
    for j=1:numel(xx(:,1))
        zgpmean(k,j)=pmean(k,j);
    end
end

figure
surf(xx,yy,zgpmean,'facealpha',0.75)
hold on
colorbar
shading flat
colormap cool
xlabel('Wind Speed')
ylabel('Erosion')
ah=gca;
set(ah,'fontsize',16)
title("Generator Power Surface via Wind Speed and Erosion")
%% Now plot it as a Countour Plot
figure
colormap('turbo')
s = pcolor(zgpmean);
s.EdgeAlpha = 0;
s.FaceColor = 'interp';

ax = gca;       
xlabel("Wind Speed")
ylabel("Erosion Level")
colorbar
ax.XTick = [11:11:121];
ax.XTickLabel = linspace(3,25,10);
ax.YTick = [0:110/4:110];
ax.YTickLabel = {'1','.25','.5','.75'};
title("Power as a Function of Wind Speed and Erosion Severity")
%% Now plot it as a contour plot
psd = reshape(pstd,Ngrid,Ngrid);
zgpsd=BOsurf;
for k=1:numel(xx(:,1))
    for j=1:numel(xx(:,1))
        zgpsd(k,j)=psd(k,j);
    end
end

figure
surf(xx,yy,zgpsd,'facealpha',0.5)
hold on
shading interp
xlabel('Wind Speed')
ylabel('Erosion Severity')
ah=gca;
colorbar
set(ah,'fontsize',16)
title("Generator Power Prediction SD via Erosion and Wind Speed")
%% Save_results

GenPwrzGp_obj.mdl = modelzgp;
GenPwrzGp_obj.data = {In_train,Out_train,In_test,Out_test};
save("GenPwrzGP"+num2str(percent)+".mat","GenPwrzGp_obj",'-mat')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [In_train,Out_train,In_test,Out_test] = GenPwrmeanData(data, percent)
    % Select the Output we want 
    output_clean = data.GenPwrmean(1:30);
    output_class1 = data.GenPwrmean(31:130);
    output_class2 = data.GenPwrmean(131:230);
    output_class3 = data.GenPwrmean(231:330);
    output_class4 = data.GenPwrmean(331:430);
    
    % Select the training data and testing data (recall the classes)
    In_clean = data(1:30,[1:2,4,5:10]);
    In_class1 = data(31:130,[1:2,3,5:10]);
    In_class2 = data(131:230,[1:2,3,5:10]);
    In_class3 = data(231:330,[1:2,3,5:10]);
    In_class4 = data(331:430,[1:2,3,5:10]);
    
    p = percent;% Testing percent
    cvpartc = cvpartition(numel(output_clean),'HoldOut',p);
    cvpart1 = cvpartition(numel(output_class1),'HoldOut',p);
    cvpart2 = cvpartition(numel(output_class2),'HoldOut',p);
    cvpart3 = cvpartition(numel(output_class3),'HoldOut',p);
    cvpart4 = cvpartition(numel(output_class4),'HoldOut',p);
    
    In_trainc = In_clean(training(cvpartc),:).Variables;
    Out_trainc = output_clean(training(cvpartc));
    
    In_train1 = In_class1(training(cvpart1),:).Variables;
    Out_train1 = output_class1(training(cvpart1));
    
    In_train2 = In_class2(training(cvpart2),:).Variables;
    Out_train2 = output_class2(training(cvpart2));
    
    In_train3 = In_class3(training(cvpart3),:).Variables;
    Out_train3 = output_class3(training(cvpart3));
    
    In_train4 = In_class4(training(cvpart4),:).Variables;
    Out_train4 = output_class4(training(cvpart4));
    
    
    In_train = cat(1,In_trainc,In_train1);
    In_train = cat(1,In_train,In_train2);
    In_train = cat(1,In_train,In_train3);
    In_train = cat(1,In_train,In_train4);
    
    Out_train = cat(1,Out_trainc,Out_train1);
    Out_train = cat(1,Out_train,Out_train2);
    Out_train = cat(1,Out_train,Out_train3);
    Out_train = cat(1,Out_train,Out_train4);
    
    In_testc = In_clean(test(cvpartc),:).Variables;
    Out_testc = output_clean(test(cvpartc));
    
    In_test1 = In_class1(test(cvpart1),:).Variables;
    Out_test1 = output_class1(test(cvpart1));
    
    In_test2 = In_class2(test(cvpart2),:).Variables;
    Out_test2 = output_class2(test(cvpart2));
    
    In_test3 = In_class3(test(cvpart3),:).Variables;
    Out_test3 = output_class3(test(cvpart3));
    
    In_test4 = In_class4(test(cvpart4),:).Variables;
    Out_test4 = output_class4(test(cvpart4));
    
    In_test = cat(1,In_testc,In_test1);
    In_test = cat(1,In_test,In_test2);
    In_test = cat(1,In_test,In_test3);
    In_test = cat(1,In_test,In_test4);
    
    Out_test = cat(1,Out_testc,Out_test1);
    Out_test = cat(1,Out_test,Out_test2);
    Out_test = cat(1,Out_test,Out_test3);
    Out_test = cat(1,Out_test,Out_test4);
end