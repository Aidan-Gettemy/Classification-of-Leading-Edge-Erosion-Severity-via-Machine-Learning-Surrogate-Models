% This Script will Test the GP fitting from Berger and Gu

addpath('RobustGaSP_matlab/functions');
addpath('RobustGaSP_matlab/data');

nonpolynomial = @(x) ((30 + 5*x(:,1).*sin(5*x(:,1))).*(4 + exp(-5*x(:,2)))-100)/6;
n= 50;
% We generate input by uniform deisng. A better design is the latin hypercube design. See lhsdesign().
x=[rand(n,1) rand(n,1)];
y=nonpolynomial(x);

model=ppgasp(x,y);


% test output
[x1_testing_mat, x2_testing_mat]=meshgrid(0:0.02:1,0:0.02:1);

num_testing=length(0:0.02:1)^2;
x_testing=zeros(num_testing,2);
x_testing(:,1)=reshape(x1_testing_mat,[num_testing,1]);
x_testing(:,2)=reshape(x2_testing_mat,[num_testing,1]);

pred_model=predict_ppgasp(model,x_testing);

y_testing=nonpolynomial(x_testing);

scatter(pred_model.mean,y_testing,30,'filled')
bds = [min(y_testing),max(y_testing)];
hold on
plot(bds,bds,'LineWidth',3)

%% Nice, nice

subplot(2,1,1)
sizex =numel(x1_testing_mat(1,:));
sizey = numel(x1_testing_mat(1,:));

surf(x1_testing_mat,x2_testing_mat,reshape(pred_model.mean,[sizex,sizey]))
title("GP")
subplot(2,1,2)
surf(x1_testing_mat,x2_testing_mat,reshape(y_testing,[sizex,sizey]))
title("True")