clc;close;clear
%% Define a function with a plateau or lower bound
BO_toy = @(x,y) (1-exp(-1./(2*y))).*(2300*x.^3+199*x.^2+2092*x+60)./(100*x.^3+500*x.^2+4*x+20)-6;
%BO_toy = @(x,y) (1 - x/2 + x.^5 + y.^3) .* exp(-x.^2 - y.^2);
%BO_toy = @(x,y) (cos(5*x)-2*(sin(2*y))) .* exp(1/2.*(-x.^2-y.^2));
UB = 1;
% Plot the (surface of the) function
[xx,yy] = meshgrid(-3:.01:3, -3:.01:3);
for i = 1:601
    for j = 1:601
        z(i,j) = min(BO_toy(xx(i,j),yy(i,j)),UB);
    end
end

surf(xx,yy,z,'facealpha',0.5)
shading flat
hold on
xlabel('x_1')
ylabel('x_2')
zlim([-2,2])
ah=gca;
set(ah,'fontsize',16)

%% Now, we will try to fit the zGP
addpath('RobustGaSP_matlab/functions');
addpath('zGP_upper_constraint_for_Aidan/');
% Set the number of sample points
n = 20;

% Set the upper bound
UB = 1;

% Use LHC
X = 6*lhsdesign(n,2)-3;

% Gather the outputs from the function on our samples
y=BO_toy(X(:,1),X(:,2));

% Set the upper bound at UB
yimp = y;
inds=find(y>UB);
yimp(inds)=UB;
ystart=yimp;

Ngibbs=2000;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This is where we start the negative samples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if UB~=0 %shift and flip to have >=0 as the constraint
    ystart=-(ystart-UB);
end
output=RLW_init_impute(X,ystart); %This does "batch sampling" to get an intitially set of negative sampleings
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
Ntemp=round(.66*length(indspn));
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
%This is the main output of the zGP algorithm. Figure(11) is a
%demonstration of how I imagine it will be used in most cases.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yzgp=mean(temp(inds,1001:5:end),2);
if UB~=0
    yzgp=-yzgp+UB;
    ystart=-ystart+UB;
end

options.trend=[ones(N,1)  X];
options.zero_mean  = false; %these two probably don't need repeated
options.nugget_est = false;

% At last, the model
modelzgp=ppgasp(X,yzgp,options);


%% For plotting
[xx,yy] = meshgrid(-3:.01:3, -3:.01:3);
Ngrid=length(xx);
NN=Ngrid*Ngrid;
BOsurf=zeros(101);
for k=1:601
    for j=1:601
        %BOsurf(k,j)=max(BO_toy(xx(k,j),yy(k,j)),0);
        BOsurf(k,j)=min(BO_toy(xx(k,j),yy(k,j)),UB);
    end
end
figure(3) 
surf(xx,yy,BOsurf,'facealpha',0.5)
shading flat
hold on
plot3(X(:,1),X(:,2),ystart,'k*')
xlabel('x_1')
ylabel('x_2')
ah=gca;
set(ah,'fontsize',16)
title("True surface");

yyr=reshape(yy,NN,1);
xxr=reshape(xx,NN,1);
xyr=[xxr yyr];

options.testing_trend=[ones(NN,1)  xyr];
options.mean_only  = false; 

pred_model=predict_ppgasp(modelzgp,xyr,options);
pmean=pred_model.mean;

pmean=reshape(pmean,Ngrid,Ngrid);
zgpmean=BOsurf;
for k=1:601
    for j=1:601
        zgpmean(k,j)=min(pmean(k,j),UB);
    end
end

figure(4)
surf(xx,yy,zgpmean,'facealpha',0.5)
hold on
plot3(X(:,1),X(:,2),ystart,'k*')
shading flat
xlabel('x_1')
ylabel('x_2')
ah=gca;
set(ah,'fontsize',16)
title("zGP")
%% Look at the error
figure(5)
surf(xx,yy,BOsurf-zgpmean,'facealpha',0.5)
hold on
plot3(X(:,1),X(:,2),ystart,'k*')
shading flat
xlabel('x_1')
ylabel('x_2')
ah=gca;
set(ah,'fontsize',16)
title("Error")



