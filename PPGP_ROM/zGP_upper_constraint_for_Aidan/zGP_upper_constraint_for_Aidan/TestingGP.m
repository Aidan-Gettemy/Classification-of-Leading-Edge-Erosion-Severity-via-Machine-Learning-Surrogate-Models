% This Script will Test the GP fitting from Berger and Gu

addpath('RobustGaSP_matlab/functions');
addpath('RobustGaSP_matlab/data');

nonpolynomial = @(x) ((30 + 5*x(:,1).*sin(5*x(:,1))).*(4 + exp(-5*x(:,2)))-100)/6;
n= 60;
% We generate input by uniform deisng. A better design is the latin hypercube design. See lhsdesign().
x=[rand(n,1) rand(n,1)];
y=nonpolynomial(x);

model=ppgasp(x,y);


% test output
[x1_testing_mat x2_testing_mat]=meshgrid(0:0.02:1,0:0.02:1);

num_testing=length(0:0.02:1)^2;
x_testing=zeros(num_testing,2);
x_testing(:,1)=reshape(x1_testing_mat,[num_testing,1]);
x_testing(:,2)=reshape(x2_testing_mat,[num_testing,1]);

pred_model=predict_ppgasp(model,x_testing);
%%
X = pred_model.mean;
X = reshape(X,sqrt(num_testing),sqrt(num_testing));
surface(x1_testing_mat,x2_testing_mat,X)

figure
y_testing=nonpolynomial(x_testing);
Xstar = reshape(y_testing,sqrt(num_testing),sqrt(num_testing));
surface(x1_testing_mat,x2_testing_mat,Xstar)

figure
surface(x1_testing_mat,x2_testing_mat,abs(Xstar-X))

figure

scatter(pred_model.mean,y_testing,30,'filled')
bds = [min(y_testing),max(y_testing)];
hold on
plot(bds,bds,'LineWidth',3)

% Nice, nice