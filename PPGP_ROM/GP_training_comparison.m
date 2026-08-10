%% Compare Gaussian Process Emulators

% Workflow 1: Scalar GP
% Workflow 2: Scalar GP and zGP
% Workflow 3: PP GP
% Workflow 4: PP GP and zGP

% Inputs: Target Output Variables, Original Output Data, zGP transformed
% Output Data and zGP parameters


%% Step 1.) Load the datasets
clc;close;clear

% Load the original dataset
data_original = readtable("../Data/Exp3/LARGE2ExperimentResultTable1_210.txt");

% Load the zGP transformed dataset
data_zgp = readtable("GP_Modeling\zGP_all_data\LARGE2ExperimentResultTable1_zGP.txt");

% Load the parameters for the zGP reconstruction
zGP_params = load("GP_Modeling\zGP_all_data\zGP_params.mat");

%% Step 2.) Cross-Validation Set
% Make r k_fold CV splits to compare approaches
r       = 5;
k_folds = 5;
FOLDS   = cell(1,r);
% Set a random number:
rng(400)
for i = 1:r
    % Use a stratification variable, alpha,
    % to ensure that training in is balanced
    FOLDS{i} = cvpartition(data_original.Alpha,'KFold',k_folds); 
end
save(sprintf('%d_x_%d_GP_training_rkfolds.mat',r,k_folds),"FOLDS")

%% Step 2.) GP Training
% Add paths
addpath('../PPGP_ROM/RobustGaSP_matlab/functions');
addpath('../PPGP_ROM/RobustGaSP_matlab/data');
addpath('../PPGP_ROM/')

% Set folds
k_folds = 5;
% Set repeats
r       = 5;
% Load folds
FOLDS = load(sprintf("%d_x_%d_GP_training_rkfolds.mat",r,k_folds));FOLDS = FOLDS.FOLDS;

% Set the variable names
varnames = ["B1N6Cdmean","B1N6Cdsd","B1N6Clmean","TipALxb1skew","RootMxb1mean",...
    "B1N6Clsd","TipALxb1sd","GenPwrmean"];

%% Step 3.a-1) Scalar GP training

% Save training time and trained models
scalar_GPs = cell(1,k_folds);
scalar_GPs_tr_time = zeros(1,k_folds);

% Repeats
for j = 1:r
    % Folds
    gpcv   = FOLDS{j};
    for k = 1:k_folds
        % Start timer
        timer1 = tic;
        
        TRAIN = data_original(gpcv.training(k),:);
        scalar_GPs{j,k} = vGP_process1(TRAIN,varnames);
    
        % Store the training time for the current fold
        time1 = toc(timer1);
        scalar_GPs_tr_time(j,k) = time1; 
    end
end

%% Step 3.a-2) Save results
outdir = 'GP_Modeling/FullWorkflow_Comparison';

% Standard GP Timing
save([outdir '/standardGP_' num2str(r) '_x_' num2str(k_folds) '_time.mat'],'scalar_GPs_tr_time');

% Save the Standard GP models
save([outdir '/standardGP_' num2str(r) '_x_' num2str(k_folds) '_mdls.mat'],'scalar_GPs');

%% Step 3.b-1) Scalar GP training with zGP data

% Save training time and trained models
scalar_zGPs = cell(1,k_folds);
scalar_zGPs_tr_time = zeros(1,k_folds);

% Repeats
for j = 1:r
    % Folds
    gpcv   = FOLDS{j};
    for k = 1:k_folds
        % Start timer
        timer1 = tic;
        
        IN_TRAIN  = data_original(gpcv.training(k),:);
        OUT_TRAIN = data_zgp(gpcv.training(k),:);
        scalar_zGPs{j,k} = vGP_process2(IN_TRAIN,varnames,OUT_TRAIN);
    
        % Store the training time for the current fold
        time1 = toc(timer1);
        scalar_zGPs_tr_time(j,k) = time1; 
    end
end

%% Step 3.b-2) Save results
outdir = 'GP_Modeling/FullWorkflow_Comparison';

% Standard GP Timing
save([outdir '/standardzGP_' num2str(r) '_x_' num2str(k_folds) '_time.mat'],'scalar_zGPs_tr_time');

% Save the Standard GP models
save([outdir '/standardzGP_' num2str(r) '_x_' num2str(k_folds) '_mdls.mat'],'scalar_zGPs');

%% Step 3.c-1) PP GP training

pp_GP = cell(1,k_folds);
pp_GP_tr_time = zeros(1,k_folds);

% Repeats
for j = 1:r
    % Folds
    gpcv   = FOLDS{j};
    for k = 1:k_folds
        % start time
        timer1 = tic;
    
        IN_TRAIN  = data_original(gpcv.training(k),:);
        OUT_TRAIN = data_original(gpcv.training(k),:);
        pp_GP{j,k}  = ppGP_process1(IN_TRAIN, varnames, OUT_TRAIN);
    
         % Store the training time for the current fold
        time1 = toc(timer1);
        pp_GP_tr_time(j,k) = time1;
    end
end
%% Step 3.c-2) Save results

outdir = 'GP_Modeling/FullWorkflow_Comparison';

% Standard GP Timing
save([outdir '/ppGP_' num2str(r) '_x_' num2str(k_folds) '_time.mat'],'pp_GP_tr_time');

% Save the Standard GP models
save([outdir '/ppGP_' num2str(r) '_x_' num2str(k_folds) '_mdls.mat'],'pp_GP');

%% Step 3.d-1) PP GP training with zGP data

pp_zGP = cell(j,k_folds);
pp_zGP_tr_time = zeros(j,k_folds);

% Repeats
for j = 1:r
    % Folds
    gpcv   = FOLDS{j};
    for k = 1:k_folds
        % start time
        timer1 = tic;
    
        IN_TRAIN  = data_original(gpcv.training(k),:);
        OUT_TRAIN = data_zgp(gpcv.training(k),:);
        pp_zGP{j,k}  = ppGP_process2(IN_TRAIN, OUT_TRAIN);
    
         % Store the training time for the current fold
        time1 = toc(timer1);
        pp_zGP_tr_time(j,k) = time1;
    end
end

%% Step 3.d-2) Save results

outdir = 'GP_Modeling/FullWorkflow_Comparison';

% Standard GP Timing
save([outdir '/ppzGP_' num2str(r) '_x_' num2str(k_folds) '_time.mat'],'pp_zGP_tr_time');

% Save the Standard GP models
save([outdir '/ppzGP_' num2str(r) '_x_' num2str(k_folds) '_mdls.mat'],'pp_zGP');

%% Step 4.a) Compare Timing

% Target Directory
outdir = "GP_Modeling/FullWorkFlow_Comparison/";
% repeats
r = 5;
% k-folds
k_folds = 5;
% names
noms = {"standardGP","standardzGP","ppGP","ppzGP"};
sets = cell(1,numel(noms));
for i =1:numel(noms)
    sets{i} = load(sprintf("%s/%s_%d_x_%d_time.mat",outdir, noms{i}, r, k_folds),"-mat");
end
% Step 4.a-ii) Run timing
TRAIN_TIMING = zeros(r*k_folds,numel(noms));
for k = 1:numel(noms)
    SET = sets{k};
    stct_nom = fieldnames(SET)
    for i = 1:r
        for j = 1:k_folds
            TRAIN_TIMING((i-1)*k_folds + j,k) = SET.(stct_nom{1})(i,j);
        end
    end
end

t_means = mean(TRAIN_TIMING,1);
t_sds   = std(TRAIN_TIMING,[],1);
% SE = std/sqrt(n)
t_se    = t_sds./sqrt(r*k_folds);
% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, r*k_folds - 1);

% now load one example of each of the models. 
addpath ../erosionfuncs/
num_points = 10000;

% % ppGP settings 
zGP_scale = zGP_params.zGP_scale;
zGP_cols = [2,6,7,8];
lim_types = ["lower","lower","lower","upper"];
zGP_shift = zGP_params.zGP_shift;
yRLs      = zGP_params.yRLs;
% - Original Data Table
original_input = data_original(:,[1,2,3,5:10]).Variables;
% Number of Outputs
numvars = 8;
p_reps  = 25;
PRED_TIMING = zeros(p_reps,numel(noms));
%% Step 4.b) Report Timing
for i = 1:numel(noms)
    model = load(sprintf("%s%s_%d_x_%d_mdls.mat",outdir, noms{i}, r, k_folds))
    % Generate training input
    IN_TEST = prediction_test(num_points);
    switch i
            case 1
                model = model.scalar_GPs{1,1};
            case 2
                model = model.scalar_zGPs{1,1};
            case 3
                model = model.pp_GP{1,1};
            otherwise
                model = model.pp_zGP{1,1};
        end
    for k = 1:p_reps
        timer1 = tic;
        switch i
            case 1
                pred  = wrkflow_predict_scalarGP(model,IN_TEST(:,[1,2,3,5:10]).Variables,numvars);
            case 2
                pred  = wrkflow_predict_scalarzGP(model, IN_TEST(:,[1,2,3,5:10]).Variables, numvars, ...
                            zGP_scale, zGP_cols, lim_types, zGP_shift, ...
                            yRLs, original_input);
            case 3
                pred  = wrkflow_predict_ppGP(model, IN_TEST(:,[1,2,3,5:10]).Variables);
            otherwise
                pred  = wrkflow_predict_ppzGP(model, IN_TEST(:,[1,2,3,5:10]).Variables, ...
                            zGP_scale, zGP_cols, lim_types, zGP_shift, ...
                            yRLs, original_input);
        end
        PRED_TIMING(k,i) = toc(timer1);
    end
end
%% Step 4.c) Print Results of Timing Tests
clc;
fmt = '%-20s %-20s \n';   % left‑aligned text columns (10 chars wide)

fprintf(fmt, 'Name', 'Training Time Credible Interval');

for i = 1:numel(noms)
    fprintf(fmt,noms{i},sprintf('%.3f +- %.3f \n',t_means(i),tcrit*t_se(i)))
end

fprintf(fmt, 'Name', sprintf('Prediction Time (%d)',num_points));

pred_time_means = mean(PRED_TIMING,1);
pred_time_se   = std(PRED_TIMING,0,1)./sqrt(size(PRED_TIMING,1));


for i = 1:numel(noms)
    fprintf(fmt,noms{i},sprintf('%.3f +- %.3f \n',pred_time_means(i),tcrit*pred_time_se(i)));
end

%% Step 5.) Load all GPs and do predictions

% load all the models: 
GP_MDLS = cell(numel(noms),r,k_folds);

for k = 1:numel(noms)
    models = load(sprintf("%s%s_%d_x_%d_mdls.mat",outdir, noms{k}, r, k_folds));
    stct_nom = fieldnames(models);
    MDLS = models.(stct_nom{1});
    for j = 1:r
        for i = 1:k_folds
            GP_MDLS{k,j,i} = MDLS{j,i};
        end
    end
end

% Perform all of the predictions at once
MEANS = cell(numel(noms),r,k_folds);
LOW95 = cell(numel(noms),r,k_folds);
UP95  = cell(numel(noms),r,k_folds);
SD    = cell(numel(noms),r,k_folds);
for i = 1:numel(noms)
    fprintf("Starting: %s%s_%d_x_%d Predictions \n",outdir, noms{i}, r, k_folds)
    % iterate over the repeats
    for j = 1:r
        gpcv   = FOLDS{j};
        % Iterate over the folds
        for k = 1:k_folds

            IN_TEST = data_original(gpcv.test(k),:);
            model   = GP_MDLS{i,j,k};
        
            switch i
                case 1
                    pred  = wrkflow_predict_scalarGP(model,IN_TEST(:,[1,2,3,5:10]).Variables,numvars);
                case 2
                    pred  = wrkflow_predict_scalarzGP(model, IN_TEST(:,[1,2,3,5:10]).Variables, numvars, ...
                                zGP_scale, zGP_cols, lim_types, zGP_shift, ...
                                yRLs, original_input);
                case 3
                    pred  = wrkflow_predict_ppGP(model, IN_TEST(:,[1,2,3,5:10]).Variables);
                otherwise
                    pred  = wrkflow_predict_ppzGP(model, IN_TEST(:,[1,2,3,5:10]).Variables, ...
                                zGP_scale, zGP_cols, lim_types, zGP_shift, ...
                                yRLs, original_input);
            end
            MEANS{i,j,k} = pred.mean;
            LOW95{i,j,k} = pred.lower95;
            UP95{i,j,k} = pred.upper95;
            SD{i,j,k}   = pred.sd;
        end
    end
    
end

%% Step 6.) NRMSE Prediction, Coverage, and Credible Interval Length

NRMSE = zeros(numel(noms),r,k_folds,numvars);
COV   = zeros(numel(noms),r,k_folds,numvars);
CI_L  = zeros(numel(noms),r,k_folds,numvars);
for i = 1:numel(noms)
    for j = 1:r
        gpcv   = FOLDS{j};
        for k = 1:k_folds
            pred = MEANS{i,j,k};
            lower    = LOW95{i,j,k};
            upper    = UP95{i,j,k};
            for u = 1:numvars
                x = data_original(gpcv.test(k),varnames(u)).Variables;
                y = pred(:,u);
                l = lower(:,u);
                up = upper(:,u);
                NRMSE(i,j,k,u) = normalized_rmse(x,y);
                COV(i,j,k,u)   = credible_interval_coverage(x, l, up);
                CI_L(i,j,k,u)  = mean(up-l)/(max(x)- min(x));
            end
        end
    end
end

%% Step 7.a) Statistical Comparison of NRMSE, 
fprintf('%-10s \n','NRMSE')
fmt = ['%-20s'];aux=[''];
for i = 1:numel(varnames)
    fmt = [fmt ' %-20s '];
    aux = [aux varnames(i)];
end
fmt = [fmt ' \n'];
fprintf(fmt,aux)

% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, r*k_folds - 1);

for j = 1:numel(noms)
    aux_means = zeros(1,numel(varnames));
    aux_se    = zeros(1,numel(varnames));
    AUX = [noms{j}];
    for u = 1:numel(varnames)
        vals = reshape(squeeze(NRMSE(j,:,:,u)),[],1);
        aux_means(u) = mean(vals);
        aux_se(u)    = std(vals)/sqrt(r*k_folds);
        txt          = sprintf(' %.3f +- %.3f ',aux_means(u),tcrit*aux_se(u));
        AUX          = [AUX txt];
    end
    fprintf(fmt,AUX)
end
%% Step 7.b) Cov. 
fprintf('%-10s \n','Coverage (95%)')
fmt = ['%-20s'];aux=[''];
for i = 1:numel(varnames)
    fmt = [fmt ' %-20s '];
    aux = [aux varnames(i)];
end
fmt = [fmt ' \n'];
fprintf(fmt,aux)

% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, r*k_folds - 1);

for j = 1:numel(noms)
    aux_means = zeros(1,numel(varnames));
    aux_se    = zeros(1,numel(varnames));
    AUX = [noms{j}];
    for u = 1:numel(varnames)
        vals = reshape(squeeze(COV(j,:,:,u)),[],1);
        aux_means(u) = mean(vals);
        aux_se(u)    = std(vals)/sqrt(r*k_folds);
        txt          = sprintf(' %.3f +- %.3f ',aux_means(u),tcrit*aux_se(u));
        AUX          = [AUX txt];
    end
    fprintf(fmt,AUX)
end

%% Step 7.c) Cred Int. Length.

fprintf('%-10s \n','Coverage (95%)')
fmt = ['%-20s'];aux=[''];
for i = 1:numel(varnames)
    fmt = [fmt ' %-20s '];
    aux = [aux varnames(i)];
end
fmt = [fmt ' \n'];
fprintf(fmt,aux)

% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, r*k_folds - 1);

for j = 1:numel(noms)
    aux_means = zeros(1,numel(varnames));
    aux_se    = zeros(1,numel(varnames));
    AUX = [noms{j}];
    for u = 1:numel(varnames)
        vals = reshape(squeeze(CI_L(j,:,:,u)),[],1);
        aux_means(u) = mean(vals);
        aux_se(u)    = std(vals)/sqrt(r*k_folds);
        txt          = sprintf(' %.3f +- %.3f ',aux_means(u),tcrit*aux_se(u));
        AUX          = [AUX txt];
    end
    fprintf(fmt,AUX)
end
%% Step 7.d-1) Compare Differences: NRMSE
clc;

j1 = 1;
j2 = 4;

fprintf('%-20s \n','NRMSE Difference (95%) Confidence Interval')
fmt = ['%-20s'];aux=[''];
for i = 1:numel(varnames)
    fmt = [fmt ' %-20s '];
    aux = [aux varnames(i)];
end
fmt = [fmt ' \n'];
fprintf(fmt,aux)

% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, r*k_folds - 1);

AUX = [sprintf('%s - %s :',noms{j1},noms{j2})];
aux_means = zeros(1,numel(varnames));
aux_se    = zeros(1,numel(varnames));
for u = 1:numel(varnames)
    vals = reshape(squeeze(NRMSE(j1,:,:,u)),[],1) - reshape(squeeze(NRMSE(j2,:,:,u)),[],1);
    aux_means(u) = mean(vals);
    aux_se(u)    = std(vals)/sqrt(r*k_folds);
    txt          = sprintf('[%.2e, %.2e] ',aux_means(u)-tcrit*aux_se(u),aux_means(u)+tcrit*aux_se(u));
    AUX          = [AUX txt];
end
fprintf(fmt,AUX)

%% Step 7.d-2) Compare Differences: Coverage
clc;

j1 = 1;
j2 = 4;

fprintf('%-20s \n','Coverage Difference (95%) Confidence Interval')

fmt = ['%-20s'];aux=[''];
for i = 1:numel(varnames)
    fmt = [fmt ' %-20s '];
    aux = [aux varnames(i)];
end
%aux
fmt = [fmt ' \n'];
fprintf(fmt,aux)

% critical value:
alpha = 0.05;  % 95% CI
tcrit = tinv(1 - alpha/2, r*k_folds - 1);

AUX = [sprintf('%s - %s : ',noms{j1},noms{j2})];
aux_means = zeros(1,numel(varnames));
aux_se    = zeros(1,numel(varnames));
for u = 1:numel(varnames)
    vals = reshape(squeeze(COV(j1,:,:,u)),[],1) - reshape(squeeze(COV(j2,:,:,u)),[],1);
    aux_means(u) = mean(vals);
    aux_se(u)    = std(vals)/sqrt(r*k_folds);
    txt          = sprintf("[%.2f, %.2f] ",aux_means(u)-tcrit*aux_se(u),aux_means(u)+tcrit*aux_se(u));
    AUX          = [AUX txt];
end
fprintf(fmt,AUX)

%% Step 8.a) Plot the True vs Predicted Plots

% Select one fold:

gpcv = FOLDS{1};
k = 4; % Select the ppzGP model
Out_test = data_original(gpcv.test(1),varnames).Variables;
Out_predict.mean = MEANS{k,1,1};
Out_predict.sd   = SD{k,1,1};

targets1 = ["Drag coefficient mean","Drag coefficient standard deviation",...
    "Lift coefficient mean",...
    "Tip acceleration skew","Root moment mean","Lift coefficient standard deviation",...
    "Tip acceleration standard deviation",...
    "Generator power mean"];

targets2 = {'(-)','(-)','(-)','(ms^{-2})','(kN-m)','(-)','(m{\fontsize{1}\color[rgb]{1,1,1},}s^{-2})','(MW)'};

targets3 = {'\mu-C_D', '\sigma-C_D',...
    '\mu-C_L','\gamma-a_{tip}','\mu-M_{root}',...
    '\sigma-C_L','\sigma-a_{tip}', '\mu-P_{gen}'};

plotVars = [1, 7, 5, 8];
subLabels = ["(a)", "(b)", "(c)", "(d)"];

f = figure;
f.Position = [50 50 1050 750];

axisFontSize = 20;
labelFontSize = 16;
legendFontSize = 14;
subFigFontSize = 18;

scatterSize = 32;
markerSize = 6.5;
lineWidth = 1.15;

tl = tiledlayout(2,2);
tl.TileSpacing = "compact";
tl.Padding = "compact";

points = 37;
rng(1)

for ii = 1:numel(plotVars)

    j = plotVars(ii);
    nexttile

    [Outsort, predictInd] = sort(Out_test(:,j));
    predict = Out_predict.mean(predictInd,j);
    pred_sd = Out_predict.sd(predictInd,j);

    nTotal = numel(Outsort);
    nShow = min(points,nTotal);

    % Use evenly spaced points so the figure is reproducible and readable
    showInd = unique(round(linspace(1,nTotal,nShow)));

    % Unit conversion for generator power
    m = 1;
    if j == 8
        m = 1/1000;
    end

    xVals = showInd;
    yPred = m * predict(showInd);
    yTrue = m * Outsort(showInd);
    yErr  = m * 2 * pred_sd(showInd);

    hold on

    hPred = errorbar(xVals, yPred, yErr, ...
        'LineStyle','none', ...
        'Marker','o', ...
        'LineWidth',lineWidth, ...
        'MarkerSize',markerSize, ...
        'MarkerFaceColor',"#0072BD", ...
        'MarkerEdgeColor','k', ...
        'DisplayName','Predicted');

    hTrue = scatter(xVals, yTrue, scatterSize, ...
        'filled', ...
        'MarkerEdgeColor','k', ...
        'LineWidth',lineWidth, ...
        'DisplayName','True');

    % Subfigure letter
    text(0.03, 0.93, subLabels(ii), ...
        'Units','normalized', ...
        'FontSize',subFigFontSize, ...
        'FontWeight','bold', ...
        'FontName','Helvetica');

    % Axis labels
    if ii > 2
        xlabel("Index sorted by true QoI", ...
            'FontSize',axisFontSize, ...
            'FontWeight','normal', ...
            'FontName','Helvetica');
    else
        xlabel("");
        xticklabels("")
    end

    ylabel(sprintf('%s%s%s',targets3{j},"{\fontsize{3}\color[rgb]{1,1,1}.......}",targets2{j}), ...
        'Interpreter','tex', ...
        'FontSize',axisFontSize, ...
        'FontWeight','normal', ...
        'FontName','Helvetica');

    % Only show legend on last subplot
    if ii == 4
        legend([hPred,hTrue], {"Predicted","True"}, ...
            "Location","best", ...
            'FontSize',legendFontSize, ...
            'FontWeight','normal', ...
            'FontName','Helvetica');
    end
    xlim([0, numel(yTrue)+1])
    ax = gca;
    ax.FontSize = axisFontSize;
    ax.FontName = 'Helvetica';
    box(ax,'on')
    grid on
    grid minor

end

%% Step 8.b) Train

% For this plot, train with ALL the available data! 

for k = 1%:25
    timer1 = tic;
    IN_TRAIN  = data_original(:,:);
    OUT_TRAIN = data_zgp(:,:);
    pp_zGP_all  = ppGP_process2(IN_TRAIN, OUT_TRAIN);
    full_time(k) = toc(timer1);
end

mf = mean(full_time);
se = std(full_time)./sqrt(k);
[mf - tcrit*se, mf + tcrit *se]
%% Step 8.c) Plot the Inference plots 
addpath("..\erosionfuncs\")

% -----------------------------
% Figure settings
% -----------------------------
fig = figure;
fig.Position = [100 100 1050 650];

tl = tiledlayout(fig,1,5, ...
    'TileSpacing','compact', ...
    'Padding','compact');

fontSizeAxes   = 20;
fontSizeLabels = 18;
fontSizeLegend = 18;
lineWidth      = 1.5;
markerSize     = 6;
capSize        = 8;

mkrs = ["o","s","d","^","v"];
lsty = ["-","--",":","-.","-"];

% ============================================================
% (a) Generator power vs wind speed
% ============================================================
ax1 = nexttile(tl,[1 3]);
hold(ax1,'on')

s = 5;
n = 17;
x = linspace(5,18,n);
lgd1 = strings(s,1);

for i = 1:s
    In_test = zeros(n,9);
    In_test(:,2) = x;
    In_test(:,1) = 0;
    In_test(:,3) = 1.225;
    In_test(:,4:9) = (erShape(1,(i-1)/(s-1))*ones(1,n))';

    Out_predict = wrkflow_predict_ppzGP( ...
        pp_zGP_all, In_test, zGP_scale, zGP_cols, ...
        lim_types, zGP_shift, yRLs, original_input);

    severity = (i-1)/(s-1);
    lgd1(i) = sprintf('$\\alpha = %.2f$',severity);

    errorbar(ax1, x, Out_predict.mean(:,8)/1000, ...
        2*Out_predict.sd(:,8)/1000, ...
        'LineWidth',lineWidth, ...
        'MarkerSize',markerSize, ...
        'Marker',mkrs(i), ...
        'MarkerFaceColor','auto', ...
        'LineStyle',lsty(i), ...
        'CapSize',capSize);
end

xlabel(ax1,sprintf('wind speed (m\x2009s^{-1})'), ...
    'Interpreter','tex', ...
    'FontSize',fontSizeLabels)
ylabel(ax1,'$\mu$-$P_{\mathrm{gen}}$ (MW)','FontSize',fontSizeLabels,'Interpreter','latex')
xlim(ax1,[5 18])
ylim(ax1,[-0.5 6])
grid(ax1,'on')
box(ax1,'on')

legend(ax1,lgd1, ...
    'Location','southeast', ...
    'Interpreter','latex', ...
    'FontSize',fontSizeLegend)

text(ax1,0.02,0.96,'(a)', ...
    'Units','normalized', ...
    'FontSize',fontSizeLabels, ...
    'FontWeight','bold')

set(ax1, ...
    'FontSize',fontSizeAxes, ...
    'FontName','Helvetica', ...
    'LineWidth',1.0)

% ============================================================
% (b) Generator power vs wind direction
% ============================================================
ax2 = nexttile(tl,[1 2]);
hold(ax2,'on')

s = 5;
n = 9;
x = linspace(-15,15,n);
airdens = linspace(1.1,1.4,s);
lgd2 = strings(s,1);

for i = 1:s
    In_test = ones(n,9);
    In_test(:,1) = x;
    In_test(:,2) = 10.5;
    In_test(:,3) = airdens(i);
    In_test(:,4:9) = (erShape(1,0)*ones(1,n))';

    Out_predict = predicted_outputs2( ...
        pp_zGP_all, In_test, numvars, zGP_scale, ...
        zGP_cols, lim_types, zGP_shift, yRLs, original_input);

    lgd2(i) = sprintf('\\rho = %.2f kg\x2009m^{-3}',airdens(i));

    errorbar(ax2, x, Out_predict.mean(:,8)/1000, ...
        2*Out_predict.sd(:,8)/1000, ...
        'LineWidth',lineWidth, ...
        'MarkerSize',markerSize, ...
        'Marker',mkrs(i), ...
        'MarkerFaceColor','auto', ...
        'LineStyle',lsty(i), ...
        'CapSize',capSize);
end

xlabel(ax2,sprintf('wind direction (deg.)'), ...
    'Interpreter','tex', ...
    'FontSize',fontSizeLabels)

xlim(ax2,[-16 16])
ylim(ax2,[-0.5 6])
grid(ax2,'on')
box(ax2,'on')

% Shared y-axis style: remove duplicate tick labels, not the axis itself
yticklabels(ax2,[])

legend(ax2,lgd2, ...
    'Location','southeast', ...
    'Interpreter','tex', ...
    'FontSize',fontSizeLegend)

text(ax2,0.04,0.96,'(b)', ...
    'Units','normalized', ...
    'FontSize',fontSizeLabels, ...
    'FontWeight','bold')

set(ax2, ...
    'FontSize',fontSizeAxes, ...
    'FontName','Helvetica', ...
    'LineWidth',1.0)

% Link y-axes so both panels use identical scaling
linkaxes([ax1 ax2],'y')

%% FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Training Functions
function gp_set = vGP_process1(IN_TRAIN,varnames)
    % SUMMARY: Given a set of input data (table)
    %       return the trained GP for each output
    
    gp_set = cell(1,numel(varnames));
    for i = 1:numel(varnames)
        % Set the input variable for training
        In_train = IN_TRAIN(:,[1,2,3,5:10]).Variables;
        % Extract the output variable for training
        Out_train = IN_TRAIN(:,varnames(i)).Variables; 
        % Fit the model
        gp_set{i} = ppgasp(In_train, Out_train);
    end
end

function gp_set = vGP_process2(IN_TRAIN,varnames,OUT_TRAIN)
    % SUMMARY: Given a set of input data (table)
    %       return the trained GP for each output
    
    gp_set = cell(1,numel(varnames));
    for i = 1:numel(varnames)
        % Set the input variable for training
        In_train = IN_TRAIN(:,[1,2,3,5:10]).Variables;
        % Extract the output variable for training
        Out_train = OUT_TRAIN(:,i).Variables; 
        % Fit the model
        gp_set{i} = ppgasp(In_train, Out_train);
    end
end

function ppzgp = ppGP_process1(IN_TRAIN, varnames, OUT_TRAIN)
    % Summary: given a set of zero-transformed data (table)
    %           return the trained GP 
    % Set the variable names = varnames
    In_train = IN_TRAIN(:,[1,2,3,5:10]).Variables;
    ppzgp   = ppgasp(In_train, OUT_TRAIN(:,varnames).Variables);
end

function ppzgp = ppGP_process2(IN_TRAIN, OUT_TRAIN)
    % Summary: given a set of zero-transformed data (table)
    %           return the trained GP 
    In_train = IN_TRAIN(:,[1,2,3,5:10]).Variables;
    ppzgp   = ppgasp(In_train, OUT_TRAIN.Variables);
end

% Prediction Functions
function TABLE = prediction_test(num_points)
    % The input column names
    invarNames = ["WindDirection","WindSpeed","AirDensity","WindShear",...
        "B1Er1","B1Er2","B1Er3","B1Er4","B1Er5","B1Er6",...
        "B2Er1","B2Er2","B2Er3","B2Er4","B2Er5","B2Er6",...
        "B3Er1","B3Er2","B3Er3","B3Er4","B3Er5","B3Er6"...
        "Alpha","Style"];
    
    % Build the matrix of input values/names
    
    % We will build the inputs using the latin hyper cube and the erosion
    % distribution
    
    % Number of Classes 
    classes = 5; 
    % Number of samples per Class
    samples = num_points/classes;
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
    I(:,3) = 1.10+(1.42-1.10)*p(:,3);%ones(num,1)*1.225;
    % Wind Shear
    I(:,4) = ones(num,1)*0.2;%.5*p(:,3);
    % Set the blade shape type
    I(:,end) = ones(num,1)*1; % Shape is linear
    
    % Draw samples from the erosion distribution
    for i = 1:classes
        erprofile = bladeErDist(Er_classes(i),samples);
        I((i-1)*samples+1:i*samples,5:end-2) = [erprofile,erprofile,erprofile];
        I((i-1)*samples+1:i*samples,end-1) = Er_classes(i)*ones(samples,1);
    end
    
    % Build the table and save it
    TABLE = array2table(I,"VariableNames",invarNames);
end

function predicted_outputs = wrkflow_predict_scalarGP(model, Input, numvars)
    % PREDICTED_OUTPUTS
    pred_model = [];
    pred_model.mean = zeros(size(Input,1),numvars);
    pred_model.sd = zeros(size(Input,1),numvars);
    pred_model.lower95 = zeros(size(Input,1),numvars);
    pred_model.upper95 = zeros(size(Input,1),numvars);

    for j = 1:numvars
        temp_mdl = model{j};
        predicted1 = predict_ppgasp(temp_mdl,Input);
        pred_model.mean(:, j) = predicted1.mean(:, 1);
        pred_model.sd(:,j)    = predicted1.sd(:,1);
        pred_model.lower95(:, j) = predicted1.lower95(:, 1);
        pred_model.upper95(:, j) = predicted1.upper95(:, 1);

    end

   predicted_outputs = pred_model;
end

function predicted_outputs = wrkflow_predict_scalarzGP(model, Input, numvars, ...
    scaling_factors, zGP_index, lim_types, shifts, yRLs, original_input)
    % PREDICTED_OUTPUTS
    pred_model = [];
    pred_model.mean = zeros(size(Input,1),numvars);
    pred_model.sd = zeros(size(Input,1),numvars);
    pred_model.lower95 = zeros(size(Input,1),numvars);
    pred_model.upper95 = zeros(size(Input,1),numvars);

    for j = 1:numvars
        temp_mdl = model{j};
        predicted1 = predict_ppgasp(temp_mdl,Input);
        pred_model.mean(:, j) = predicted1.mean(:, 1);
        pred_model.sd(:,j)    = predicted1.sd(:,1);
        pred_model.lower95(:, j) = predicted1.lower95(:, 1);
        pred_model.upper95(:, j) = predicted1.upper95(:, 1);

    end

    for i = 1:numel(zGP_index)
        yRL = yRLs(:,i);
        H=@(xd)[ones(size(xd,1),1) xd];%
        B=H(original_input)\yRL;
        mu = @(x) H(x)*B;

        type = lim_types(i);
        scaling_factor = scaling_factors(i);
        shift = shifts(i);

        if strcmp("upper",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + min(-scaling_factor*pmean+scaling_factor,scaling_factor);
            pred_model.mean(:,zGP_index(i)) = pmean;

            plower = pred_model.lower95(:,zGP_index(i))+mu(Input);
            plower = shift + min(-scaling_factor*plower+scaling_factor,scaling_factor);
            

            pupper = pred_model.upper95(:,zGP_index(i))+mu(Input);
            pupper = shift + min(-scaling_factor*pupper+scaling_factor,scaling_factor);

            pred_model.lower95(:,zGP_index(i)) = pupper;
            pred_model.upper95(:,zGP_index(i)) = plower;
        end
        
        if strcmp("lower",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + max(scaling_factor*pmean,0);
            pred_model.mean(:,zGP_index(i)) = pmean;

            plower = pred_model.lower95(:,zGP_index(i))+mu(Input);
            plower = shift + max(scaling_factor*plower,0);
            pred_model.lower95(:,zGP_index(i)) = plower;

            pupper = pred_model.upper95(:,zGP_index(i))+mu(Input);
            pupper = shift + max(scaling_factor*pupper,0);
            pred_model.upper95(:,zGP_index(i)) = pupper;
        end

        pred_model.sd(:,zGP_index(i)) = scaling_factor*pred_model.sd(:,zGP_index(i));
    end
    
   predicted_outputs = pred_model;
end

function predicted_outputs = wrkflow_predict_ppGP(model, Input)
    % PREDICTED_OUTPUTS
    % There might be an issue with the testing trend, which requires a new
    % approach
        %options.testing_trend=[ones(numel(Input(:,1)),out_dim)  Input];
        %options.mean_only  = false; 
   pred_model=predict_ppgasp(model,Input);
   predicted_outputs = pred_model;
end

function predicted_outputs = wrkflow_predict_ppzGP(model, Input, ...
    scaling_factors, zGP_index, lim_types, shifts, yRLs, original_input)
    % PREDICTED_OUTPUTS
    % There might be an issue with the testing trend, which requires a new
    % approach
        %options.testing_trend=[ones(numel(Input(:,1)),out_dim)  Input];
        %options.mean_only  = false; 
    

    pred_model=predict_ppgasp(model,Input);

    for i = 1:numel(zGP_index)
        yRL = yRLs(:,i);
        H=@(xd)[ones(size(xd,1),1) xd];%
        B=H(original_input)\yRL;
        mu = @(x) H(x)*B;

        type = lim_types(i);
        scaling_factor = scaling_factors(i);
        shift = shifts(i);

        if strcmp("upper",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + min(-scaling_factor*pmean+scaling_factor,scaling_factor);
            pred_model.mean(:,zGP_index(i)) = pmean;

            plower = pred_model.lower95(:,zGP_index(i))+mu(Input);
            plower = shift + min(-scaling_factor*plower+scaling_factor,scaling_factor);
            

            pupper = pred_model.upper95(:,zGP_index(i))+mu(Input);
            pupper = shift + min(-scaling_factor*pupper+scaling_factor,scaling_factor);

            pred_model.lower95(:,zGP_index(i)) = pupper;
            pred_model.upper95(:,zGP_index(i)) = plower;
        end
        
        if strcmp("lower",type) == 1
            pmean = pred_model.mean(:,zGP_index(i))+mu(Input);
            pmean = shift + max(scaling_factor*pmean,0);
            pred_model.mean(:,zGP_index(i)) = pmean;

            plower = pred_model.lower95(:,zGP_index(i))+mu(Input);
            plower = shift + max(scaling_factor*plower,0);
            pred_model.lower95(:,zGP_index(i)) = plower;

            pupper = pred_model.upper95(:,zGP_index(i))+mu(Input);
            pupper = shift + max(scaling_factor*pupper,0);
            pred_model.upper95(:,zGP_index(i)) = pupper;
        end

        pred_model.sd(:,zGP_index(i)) = scaling_factor*pred_model.sd(:,zGP_index(i));
    end
   predicted_outputs = pred_model;
end

% Evaluation Functions
function nrmse = normalized_rmse(x, y)
    % Range Normalized Version

    x = x(:);
    y = y(:);

    rmse = sqrt(mean((x - y).^2));
    nrmse = rmse / (max(x) - min(x));%mean(abs(x));%
    % Could also use mean abs value: nrmse = rmse / mean(abs(x));
    % Or could divide by the standard deviation. (check the paper)

end

function coverage = credible_interval_coverage(x, l, u)

    x = x(:);
    l = l(:);
    u = u(:);

    if numel(x) ~= numel(l) || numel(x) ~= numel(u)
        error('x, l, and u must have the same number of entries.');
    end

    inside = (x >= l) & (x <= u);

    coverage = 100 * mean(inside);

end

% Statistics Functions