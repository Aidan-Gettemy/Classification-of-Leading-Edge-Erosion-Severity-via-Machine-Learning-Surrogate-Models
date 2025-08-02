%zGP code that goes with Spiller,Wolpert, Tierz, Gasher (2023+) 
clear all
close all
addpath('../functions')
addpath('../../../RobustGaSP_matlab/functions/');

load BO_toy_design.mat % you could pick these random -- typically that happens with Latin Hypercube sampling, which you can basically thinking of as uniform sampling
% Toy function adapted from Bastos O'Hagan 2012
BO_toy = @(x,y) (1-exp(-1./(2*y))).*(2300*x.^3+199*x.^2+2092*x+60)./(100*x.^3+500*x.^2+4*x+20)-6;
y=BO_toy(xdsave(:,1),xdsave(:,2));
xd=xdsave;
ytrue=y;

%% Carefully modify code to use simulation data
addpath('../../../../Data/Exp3/')

data = readtable("LARGE2ExperimentResultTable1_130.txt");
inputs = data(:,[1:3,5:10]);
output = data(:,"B1N6Clsd");
p=0.15;
cvpart = cvpartition(numel(output),'Holdout',p);
In_train = inputs(training(cvpart),:).Variables;
In_test = inputs(test(cvpart),:).Variables;

Out_train = output(training(cvpart),:).Variables;
Out_test = output(test(cvpart),:).Variables;

y = Out_train;
ytrue = Out_train;
xd = In_train;
%%
Nd=size(xd,1);
Npars=size(xd,2);

yimp=y;
%inds=find(y<0.5); % Any x value <0.5 in we'll call 0 -- this should be modified dependent on output under consideration.
LB = min(yimp);
yimp = yimp-LB;
% Scale to the range 0-1
MLB = max(yimp);
yimp = yimp./max(yimp);
inds=find(y<0);
yimp(inds)=0;
ystart=yimp; % <- Starting Place
Ngibbs=2000;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This is where we start the negative samples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This does "batch sampling" to get an intitial set of negative samplings
output=RLW_init_impute(xd,ystart); 
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
xdp=xd(indsp,:);
yn=y(indsz);
Nz=length(indsz);
xdn=xd(indsz,:);
yRL=median(yimputesave,2);
distnp=zeros(Nz,Np);

%%%%%%%%%%%%%%%%%%%%%%%%
%extra snip to calculate probs of zeros
%%%%%%%%%%%%%%%%%%%%%%%%%
mat52 = @(d) (1+sqrt(5)*d+(5/3)*d.^2).*exp(-sqrt(5)*d); 
Np=length(indsp);
B=zeros(Nz); %correlation matrix of xp points
Btemp=zeros(Nz);

H=@(xd)[ones(size(xd,1),1) xd];

B=H(xd)\yRL;
mu = @(x) H(x)*B;  
 
modelp=ppgasp(xdp,yp-mu(xdp));
%options.trend=linear;
pred_model=predict_ppgasp(modelp,xdn);
pmean=pred_model.mean+mu(xdn);
plot(pmean,'*')
psd=pred_model.sd;
hold on
for k=1:length(pmean)
 line([k k],[pmean(k)-2*psd(k) pmean(k)+2*psd(k)])
 Pn(k)=1/2*(1+erf(-pmean(k)/(psd(k)*sqrt(2))));
end
line([0 100],[0 0],'linewidth',3)
  
for j=1:Nz
    for k=1:Np
        distnp(j,k)=sqrt((xdn(j,1)-xdp(k,1)).^2+(xdn(j,2)-xdp(k,2)).^2);
    end
end
mindist=min(distnp');
[valsmd  indsmd]=sort(mindist);
[valspn  indspn]=sort(Pn);
 Ntemp=round(.66*length(indspn));
indsadd=intersect(indspn(1:Ntemp), indsmd(1:Ntemp));

Ninclude=length(indsadd);
indsrest=setdiff(1:1:Nz,indsadd);
xzs=[xdn(indsadd,:); xdn(indsrest,:)];
xall=[xdp; xzs];
yall=[yRL(indsp); yRL(indsz(indsadd)); yRL(indsz(indsrest))];
xp_zp=[xdp; xdn(indsadd,:)];
yp_zp=[yRL(indsp); yRL(indsz(indsadd))];
model=ppgasp(xp_zp,yp_zp-mu(xp_zp));

figure(2)
plot(mindist,Pn,'*')
hold on
plot(mindist(indsadd),Pn(indsadd),'r*')

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Imputing negative responses to design points that have zero outputs via zGP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
locs=[0 0]; % specific for another problem, leave as zeros for now
output=zGP_gibbs_nrz_optmean(xall,yall,Ngibbs,locs, Ninclude); %This takes the initial set of negative samples and refines them with Gibbs sampling
                          %output{1} is set of Gibbs samplings for all y
                          %output{2} are (square of) range parameter
                          %samples
temp=output{1};
for kk=1:size(xd,1)  %rearrange response back to original design
    inds(kk)=find(xd(kk,2)==xall(:,2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This is the main output of the zGP algorithm. Figure(11) is a
%demonstration of how I imagine it will be used in most cases.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yzgp=mean(temp(inds,1001:5:end),2);
%%%%%%%%%%%%%%%%%%%%%%%%
 %options.trend=linear;
 %here is a "by-hand" linear trend because of hiccups with ppgasp()
 H=@(xd)[ones(size(xd,1),1) xd];%
 B=H(xd)\yRL;
 mu = @(x) H(x)*B;  
 
 modelzgp=ppgasp(xd,yzgp-mu(xd));
%% New plotting;

pred_model=predict_ppgasp(modelzgp,In_test);

pmean =pred_model.mean+mu(In_test);


pmean = max(MLB*pmean+LB,LB);

[SS,I] = sort(Out_test);
errorbar(1:numel(pmean),pmean(I),2*MLB*pred_model.sd(I),'Marker','*','LineStyle','none')
hold on
scatter(1:numel(Out_test),Out_test(I),'filled')
title("Node 6 Cl Standard Deviation of Time Series")
xlabel("Generator Power")
ylabel("True Index")
legend({"Predicted","True"},'Location','southeast')


 %% For plotting
[xx,yy] = meshgrid(0:.01:1, 0:.01:1);
Ngrid=length(xx);
NN=Ngrid*Ngrid;
%xd=lhsdesign(20,2);
BOsurf=zeros(101);
xd=xdsave;
for k=1:101
    for j=1:101
        BOsurf(k,j)=max(BO_toy(xx(k,j),yy(k,j)),0);
    end
end
figure(10) %True surface
surf(xx,yy,BOsurf,'facealpha',0.5)
shading flat
hold on
plot3(xd(:,1),xd(:,2),ystart,'k*')
xlabel('x_1')
ylabel('x_2')
ah=gca;
set(ah,'fontsize',16)

yyr=reshape(yy,NN,1);
xxr=reshape(xx,NN,1);
xyr=[xxr yyr];

pred_model=predict_ppgasp(modelzgp,xyr);
pmean=pred_model.mean+mu(xyr);

inds=find(pmean)<0;
pmean(inds)=0;
pmean=reshape(pmean,Ngrid,Ngrid);
zgpmean=BOsurf;
for k=1:101
    for j=1:101
        zgpmean(k,j)=max(pmean(k,j),0);
    end
end

figure(12)
surf(xx,yy,zgpmean,'facealpha',0.5)
hold on
plot3(xd(:,1),xd(:,2),ystart,'k*')
shading flat
xlabel('x_1')
ylabel('x_2')
ah=gca;
set(ah,'fontsize',16)

figure(14)
pcolor(xx,yy,BOsurf-zgpmean)
colorbar
shading flat
xlabel('x_1')
ylabel('x_2')
hold on
plot(xd(:,1),xd(:,2),'k*')
shading flat
ah=gca;
set(ah,'fontsize',16)

