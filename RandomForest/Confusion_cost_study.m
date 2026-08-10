% weighted confusion study
clc;close;clear;

emu_summary = load("TEST1star_Results/emu_thresholdSummary.mat");
emu_summary = emu_summary.thresholdSummary;

sim_summary = load("TEST1star_Results/sim_thresholdSummary.mat");
sim_summary = sim_summary.thresholdSummary;

%% Select the optimal setting for classifier
% If only the fully eroded class is considered severe:
tau = zeros(2,31);
rec = zeros(2, 31);
fnr = zeros(2, 31);
far = zeros(2, 31);
avgCost = zeros(2, 31);
for g = 1:2
    if g == 1;thresholdSummary = sim_summary;else;thresholdSummary = emu_summary;end
    aux = ["Simulation","Emulation"];
    fprintf('Results for %s\n',aux(g))
    fprintf('\nThreshold   Severe Recall   Severe FNR   False Alarm Rate      Conf. Cost\n');
    fprintf('---------------------------------------------------------------------------\n');

    for t = 1:numel(thresholdSummary.thresholds)
    
        tau(g,t) = thresholdSummary.threshold(t).tau;
        rec(g,t) = thresholdSummary.threshold(t).severeRecallMean;
        fnr(g,t) = thresholdSummary.threshold(t).severeFNRMean;
        far(g,t) = thresholdSummary.threshold(t).falseAlarmMean;
    
        [avgCost(g,t), totalCost, costMatrix] = asymmetric_confusion_cost(thresholdSummary.threshold(t).Csum, 4, 1);
    
        % disp(costMatrix)
        %fprintf('Average asymmetric confusion cost: %.4f\n', avgCost);
    
        fprintf('%8.2f   %13.3f   %10.3f   %16.3f %16.3f\n', tau(g,t), rec(g,t), fnr(g,t), far(g,t), avgCost(g,t));
    
    end
end
%% Glimpse the matrix for the bestr version

[i,ks] = min(avgCost(1,:)); % for example, thresholds(3) = 0.3

figure;tiledlayout;nexttile
confusionchart( ...
    sim_summary.threshold(ks).Csum, ...
    string(thresholdSummary.classes), ...
    'Normalization','row-normalized');

title(sprintf('Simulation: Severe threshold = %.2f', thresholdSummary.threshold(ks).tau));
nexttile

confusionchart( ...
    sim_summary.threshold(1).Csum, ...
    string(thresholdSummary.classes), ...
    'Normalization','row-normalized');

title(sprintf('Simulation: Severe threshold = %.2f', thresholdSummary.threshold(1).tau));

[i,ke] = min(avgCost(2,:)); % for example, thresholds(3) = 0.3

figure;
tiledlayout
nexttile
confusionchart( ...
    emu_summary.threshold(ke).Csum, ...
    string(thresholdSummary.classes), ...
    'Normalization','row-normalized');

title(sprintf('Emulation: Severe threshold = %.2f', thresholdSummary.threshold(ke).tau));
nexttile

confusionchart( ...
    emu_summary.threshold(1).Csum, ...
    string(thresholdSummary.classes), ...
    'Normalization','row-normalized');

title(sprintf('Emulation: Severe threshold = %.2f', thresholdSummary.threshold(1).tau));

%% Make a four tile plot:


f = figure;
f.Position = [100 100 1100 500];
classes = categorical([0:4]/4);
alpha = 0.75;
C_norm_emu = emu_summary.threshold(ke).Csum ./ sum(emu_summary.threshold(ke).Csum, 2);
C_norm_sim = sim_summary.threshold(ks).Csum ./ sum(sim_summary.threshold(ks).Csum, 2);

tl = tiledlayout(f,2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');
% first tile: optimal confusion matrix emulation trained
ax1 = nexttile(tl,1);

imagesc(ax1,C_norm_emu,'AlphaData',alpha)
axis(ax1,'square')
%colorbar(ax1)
drawgridaxis(C_norm_emu,ax1)

xticks(ax1,1:numel(classes))
yticks(ax1,1:numel(classes))
xticklabels(ax1,string(classes))
yticklabels(ax1,string(classes))

xlabel(ax1,'Predicted class')
ylabel(ax1,'True class')
%title(ax1,'Emulator-trained')

set(ax1, ...
    'FontName','Helvetica', ...
    'FontSize',18, ...
    'TickLabelInterpreter','none')

addtext(C_norm_emu)

text(ax1,0.02,0.96,'(a)', ...
    'Units','normalized', ...
    'FontWeight','bold', ...
    'FontSize',18)
% second tile: optimal confusion matrix simulation trained
ax2 = nexttile(tl,2);

imagesc(ax2,C_norm_sim,'AlphaData',alpha)
axis(ax2,'square')
%colorbar(ax1)
drawgridaxis(C_norm_sim,ax2)

xticks(ax2,1:numel(classes))
yticks(ax2,1:numel(classes))
xticklabels(ax2,string(classes))
yticklabels(ax2,string(classes))

xlabel(ax2,'Predicted class')
ylabel(ax2,'True class')
%title(ax1,'Emulator-trained')

set(ax2, ...
    'FontName','Helvetica', ...
    'FontSize',18, ...
    'TickLabelInterpreter','none')

addtext(C_norm_sim)

text(ax2,0.02,0.96,'(b)', ...
    'Units','normalized', ...
    'FontWeight','bold', ...
    'FontSize',18)

% Use same colormap
colormap(f,professionalbluecmap)

% Shared colorbar
cb = colorbar(ax2);
cb.Layout.Tile = 'east';
% cb.Label.String = 'Row-normalized fraction';
cb.FontName = 'Helvetica';
cb.FontSize = 14;

% Use same color scale for both
clim(ax1,[0 1])
clim(ax2,[0 1])
% FNR, weighted conf. etc. emulation trained
ax3 = nexttile(tl,3);
% Find optimal threshold by minimum weighted confusion cost
[minCost, idxOpt] = min(avgCost(2,:));
tauOpt = tau(2,idxOpt)
hold(ax3,'on');

plot(ax3, tau(2,:), rec(2,:), '-o', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6);

plot(ax3, tau(2,:), fnr(2,:), '-s', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6);

plot(ax3, tau(2,:), far(2,:), '-^', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6);

plot(ax3, tau(2,:), avgCost(2,:), '-d', ...
    'LineWidth', 1.8, ...
    'MarkerSize', 6);

% Highlight optimal cost point
plot(ax3, tauOpt, minCost, 'p', ...
    'MarkerSize', 14, ...
    'LineWidth', 1.8, ...
    'MarkerFaceColor', 'k');

% Optional vertical reference line at optimal threshold
xline(ax3, tauOpt, '--', ...
    sprintf('\\tau^* = %.2f', tauOpt), ...
    'LabelOrientation','horizontal', ...
    'LabelVerticalAlignment','bottom', ...
    'LineWidth', 1.2);

% Annotation near the optimal point
text(ax3, tauOpt, minCost + 0.045, ...
    sprintf('min cost = %.3f', minCost), ...
    'HorizontalAlignment','center', ...
    'FontSize', 11);

xlabel(ax3, 'Severe-damage threshold, \tau');
ylabel(ax3, 'Metric value');
%title(ax3, 'Threshold tradeoff for severe-damage detection');

% legend(ax3, ...
%     {'Severe recall', ...
%      'Severe false-negative rate', ...
%      'False alarm rate', ...
%      'Weighted confusion cost', ...
%      'Minimum cost'}, ...
%     'Location','best');

grid(ax3,'on');
box(ax3,'on');

ylim(ax3, [0 1]);

% Reverse x-axis so moving right means "more conservative"
set(ax3, 'XDir', 'reverse');

% Make the plotting box square
axis(ax3,'square');

hold(ax3,'off');
% FNR, weigthed conf. etc. simulation trained

ax4 = nexttile(tl,4);
% Find optimal threshold by minimum weighted confusion cost
[minCost, idxOpt] = min(avgCost(1,:));
tauOpt = tau(1,idxOpt)
hold(ax4,'on');

plot(ax4, tau(1,:), rec(1,:), '-o', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6);

plot(ax4, tau(1,:), fnr(1,:), '-s', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6);

plot(ax4, tau(1,:), far(1,:), '-^', ...
    'LineWidth', 1.6, ...
    'MarkerSize', 6);

plot(ax4, tau(1,:), avgCost(1,:), '-d', ...
    'LineWidth', 1.8, ...
    'MarkerSize', 6);

% Highlight optimal cost point
plot(ax4, tauOpt, minCost, 'p', ...
    'MarkerSize', 14, ...
    'LineWidth', 1.8, ...
    'MarkerFaceColor', 'k');

% Optional vertical reference line at optimal threshold
xline(ax4, tauOpt, '--', ...
    sprintf('\\tau^* = %.2f', tauOpt), ...
    'LabelOrientation','horizontal', ...
    'LabelVerticalAlignment','bottom', ...
    'LineWidth', 1.2);

% Annotation near the optimal point
text(ax4, tauOpt, minCost + 0.045, ...
    sprintf('min cost = %.3f', minCost), ...
    'HorizontalAlignment','center', ...
    'FontSize', 11);

xlabel(ax4, 'Severe-damage threshold, \tau');
ylabel(ax4, 'Metric value');
%title(ax4, 'Threshold tradeoff for severe-damage detection');

legend(ax4, ...
    {'Severe recall', ...
     'Severe false-negative rate', ...
     'False alarm rate', ...
     'Weighted confusion cost', ...
     'Minimum cost'}, ...
    'Location','best');

grid(ax4,'on');
box(ax4,'on');

ylim(ax4, [0 1]);

% Reverse x-axis so moving right means "more conservative"
set(ax4, 'XDir', 'reverse');

% Make the plotting box square
axis(ax4,'square');

hold(ax4,'off');
%% Two Plot Version
%% ============================================================
% Figure 1: Optimal confusion matrices only
% ============================================================

f1 = figure;
f1.Position = [100 50 1300 650];
% f1 = figure;
% f1.Position = [100 100 1050 500];

classes = categorical([0:4]/4);
alpha = 0.75;

C_norm_emu = emu_summary.threshold(ke).Csum ./ sum(emu_summary.threshold(ke).Csum, 2);
C_norm_sim = sim_summary.threshold(ks).Csum ./ sum(sim_summary.threshold(ks).Csum, 2);

tl1 = tiledlayout(f1,1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

% ------------------------------------------------------------
% first tile: optimal confusion matrix emulation trained
% ------------------------------------------------------------
ax1 = nexttile(tl1,1);

imagesc(ax1,C_norm_emu,'AlphaData',alpha)
axis(ax1,'square')
drawgridaxis(C_norm_emu,ax1)

xticks(ax1,1:numel(classes))
yticks(ax1,1:numel(classes))
xticklabels(ax1,string(classes))
yticklabels(ax1,string(classes))

xlabel(ax1,'Predicted class')
ylabel(ax1,'True class')

set(ax1, ...
    'FontName','Helvetica', ...
    'FontSize',24, ...
    'TickLabelInterpreter','none')
xlabel(ax1,'Predicted class','FontSize',30)
ylabel(ax1,'True class','FontSize',30)

addtext(C_norm_emu)

% ------------------------------------------------------------
% second tile: optimal confusion matrix simulation trained
% ------------------------------------------------------------
ax2 = nexttile(tl1,2);

imagesc(ax2,C_norm_sim,'AlphaData',alpha)
axis(ax2,'square')
drawgridaxis(C_norm_sim,ax2)

xticks(ax2,1:numel(classes))
yticks(ax2,1:numel(classes))
xticklabels(ax2,string(classes))
yticklabels(ax2,string(classes))

xlabel(ax2,'Predicted class')
ylabel(ax2,'True class')

set(ax2, ...
    'FontName','Helvetica', ...
    'FontSize',24, ...
    'TickLabelInterpreter','none')
xlabel(ax2,'Predicted class','FontSize',30)
ylabel(ax2,'True class','FontSize',30)

addtext(C_norm_sim)

text(ax1, -0.05, 0.99, '(a)', ...
    'Units','normalized', ...
    'FontWeight','bold', ...
    'FontSize',25, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'Clipping','off');

text(ax2, -0.05, 0.99, '(b)', ...
    'Units','normalized', ...
    'FontWeight','bold', ...
    'FontSize',25, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'Clipping','off');

% Use same colormap and color scale
colormap(f1,blue_red_white_cmap)
clim(ax1,[0 1])
clim(ax2,[0 1])

% Shared colorbar
cb = colorbar(ax2);
cb.Layout.Tile = 'east';
cb.FontName = 'Helvetica';
cb.FontSize = 20;
cb.Position(3) = 0.5;
% Match axes across panels
%linkaxes(axs,'xy')

% Shared limits
%xlim(axs(1),[0 0.5])
%ylim(axs(1),[0 1])

% Remove duplicate y-axis label/tick labels from second panel
ylabel(ax2, '')
ax2.YTickLabel = [];
%% Second plot
%% ============================================================
% Figure 2: Threshold tradeoff curves only
% ============================================================

f2 = figure;
f2.Position = [150 150 1150 575];

tl2 = tiledlayout(f2,1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

axs = gobjects(2,1);

% ------------------------------------------------------------
% left tile: emulation trained threshold curves
% ------------------------------------------------------------
axs(1) = nexttile(tl2,1);

plot_threshold_tradeoff_panel( ...
    axs(1), ...
    tau(2,:), ...
    rec(2,:), ...
    fnr(2,:), ...
    far(2,:), ...
    avgCost(2,:), ...
    '(a)');

% ------------------------------------------------------------
% right tile: simulation trained threshold curves
% ------------------------------------------------------------
axs(2) = nexttile(tl2,2);

plot_threshold_tradeoff_panel( ...
    axs(2), ...
    tau(1,:), ...
    rec(1,:), ...
    fnr(1,:), ...
    far(1,:), ...
    avgCost(1,:), ...
    '(b)');

% Match axes across panels
linkaxes(axs,'xy')

% Shared limits
xlim(axs(1),[0 0.5])
ylim(axs(1),[0 1])

% Shared legend outside the right panel
% lgd = legend(axs(2), ...
%     {
%      'Severe false-negative rate', ...
%      'False alarm rate', ...
%      'Weighted confusion cost', ...
%      'Minimum cost'}, ...
%     'Location','eastoutside');
% 
% lgd.FontName = 'Helvetica';
% lgd.FontSize = 18;
% lgd.Box = 'off';
% Shared horizontal legend above both panels
lgd = legend(axs(2), ...
    {'Severe FNR', ...
     'False alarm rate', ...
     'Weighted cost', ...
     'Minimum cost'}, ...
    'Orientation','horizontal', ...
    'Location','northoutside');

lgd.Layout.Tile = 'north';
lgd.FontName = 'Helvetica';
lgd.FontSize = 18;
lgd.Box = 'off';
% Match axes across panels
linkaxes(axs,'xy')

% Shared limits
xlim(axs(1),[0 0.5])
ylim(axs(1),[0 1])

% Remove duplicate y-axis label/tick labels from second panel
ylabel(axs(2), '')
axs(2).YTickLabel = [];
%% FUNCTIONS
function [avgCost, totalCost, costMatrix] = asymmetric_confusion_cost(C, underWeight, overWeight)
%ASYMMETRIC_CONFUSION_COST Compute weighted misclassification cost.
%
% Inputs:
%   C            Confusion matrix, rows = true classes, columns = predicted classes
%   underWeight  Penalty multiplier for underprediction, e.g. 2
%   overWeight   Penalty multiplier for overprediction, e.g. 1
%
% Outputs:
%   avgCost      Average cost per sample
%   totalCost    Total weighted confusion cost
%   costMatrix   Matrix of costs for each true/predicted class pair
%
% Assumes classes are ordered from least severe to most severe.

    if nargin < 2
        underWeight = 2;
    end

    if nargin < 3
        overWeight = 1;
    end

    nClasses = size(C,1);

    if size(C,1) ~= size(C,2)
        error('Confusion matrix must be square.');
    end

    costMatrix = zeros(nClasses,nClasses);

    for i = 1:nClasses          % true class
        for j = 1:nClasses      % predicted class

            classDistance = abs(i - j);

            if j < i
                % Predicted less damage than true damage
                costMatrix(i,j) = underWeight * classDistance;
            elseif j > i
                % Predicted more damage than true damage
                costMatrix(i,j) = overWeight * classDistance;
            else
                % Correct classification
                costMatrix(i,j) = 0;
            end

        end
    end

    totalCost = sum(C .* costMatrix, 'all');
    avgCost = totalCost / sum(C, 'all');

end

function cmap = professionalbluecmap(n)

    if nargin < 1
        n = 256;
    end

    % A smooth, muted sequential palette:
    % near-white -> pale blue -> medium blue -> muted navy
    anchors = [ ...
        0.97 0.98 1.00;   % nearly white
        0.82 0.90 0.97;   % pale blue
        0.45 0.68 0.86;   % medium blue
        0.16 0.38 0.61];  % muted navy

    x  = linspace(0,1,size(anchors,1));
    xi = linspace(0,1,n);

    cmap = [ ...
        interp1(x,anchors(:,1),xi)', ...
        interp1(x,anchors(:,2),xi)', ...
        interp1(x,anchors(:,3),xi)'];

end

function drawgridaxis(C_norm,ax)
    
    hold(ax,"on")

    nRows = size(C_norm,1);
    nCols = size(C_norm,2);
    
    % Draw vertical grid lines
    for x = 0.5:1:nCols+0.5
        plot(ax,[x x],[0.5 nRows+0.5], ...
            'k-', ...
            'LineWidth',1.0, ...
            'HandleVisibility','off');
    end
    
    % Draw horizontal grid lines
    for y = 0.5:1:nRows+0.5
        plot(ax,[0.5 nCols+0.5],[y y], ...
            'k-', ...
            'LineWidth',1.0, ...
            'HandleVisibility','off');
    end
    
    hold(ax,'off')

end

function addtext(C_norm)
    for i = 1:size(C_norm,1)
        for j = 1:size(C_norm,2)
    
            if C_norm(i,j) > 0.75
                txtColor = 'w';
            else
                txtColor = 'k';
            end
    
            text(j,i,sprintf('%.2f',C_norm(i,j)), ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontSize',22, ...
                'FontWeight','bold', ...
                'Color',txtColor);
        end
    end
end

function plot_threshold_tradeoff_panel(ax, tauVals, recVals, fnrVals, farVals, avgCostVals, panelLabel)

    hold(ax,'on');

    % Find optimal threshold by minimum weighted confusion cost
    [minCost, idxOpt] = min(avgCostVals);
    tauOpt = tauVals(idxOpt);

    % Use fewer visible markers to reduce clutter
    nPts = numel(tauVals);
    markerIdx = unique([1:3:nPts, idxOpt, nPts]);

    % plot(ax, tauVals, recVals, '-o', ...
    %     'LineWidth', 1.8, ...
    %     'MarkerSize', 6, ...
    %     'MarkerIndices', markerIdx);

    plot(ax, tauVals, fnrVals, '-s', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'MarkerIndices', markerIdx);

    plot(ax, tauVals, farVals, '-^', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 6, ...
        'MarkerIndices', markerIdx);

    plot(ax, tauVals, avgCostVals, '-d', ...
        'LineWidth', 2.2, ...
        'MarkerSize', 6, ...
        'MarkerIndices', markerIdx);

    % Highlight optimal cost point
    plot(ax, tauOpt, minCost, 'p', ...
        'MarkerSize', 16, ...
        'LineWidth', 1.8, ...
        'MarkerFaceColor', 'k', ...
        'MarkerEdgeColor', 'k');

    % Vertical reference line at optimal threshold
    % xline(ax, tauOpt, '--', ...
    %     sprintf('\\tau^* = %.2f', tauOpt), ...
    %     'LabelOrientation','horizontal', ...
    %     'LabelVerticalAlignment','bottom', ...
    %     'LineWidth', 1.3, ...
    %     'FontSize', 18);
    % 
    % % Place annotation slightly away from the marker
    % text(ax, tauOpt + 0.035, minCost + 0.060, ...
    %     sprintf('min cost = %.3f', minCost), ...
    %     'HorizontalAlignment','center', ...
    %     'FontSize', 18, ...
    %     'FontName','Helvetica');
    % Vertical reference line at optimal threshold
    xline(ax, tauOpt, '--', ...
        'LineWidth', 1.3, ...
        'Color', [0.35 0.35 0.35]);
    
    % Add tau* label manually
    text(ax, tauOpt, 0.5, ...
    sprintf('$\\tau^* = %.2f$', tauOpt), ...
        'Interpreter','latex', ...
        'FontSize', 15, ...
        'FontName','Helvetica', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'BackgroundColor','w', ...
        'Margin',2);

    xlabel(ax, 'Severe-damage threshold, \tau');
    ylabel(ax, 'Metric value');

    grid(ax,'on');
    box(ax,'on');

    % Reverse x-axis so moving right means more conservative
    set(ax, 'XDir', 'reverse');

    % Larger, cleaner axis formatting
    set(ax, ...
        'FontName','Helvetica', ...
        'FontSize',18, ...
        'LineWidth',1.1, ...
        'TickDir','out');

    % Square plotting box
    axis(ax,'square');

    % Subplot label
    text(ax,0.02,0.96,panelLabel, ...
        'Units','normalized', ...
        'FontWeight','bold', ...
        'FontSize',22, ...
        'FontName','Helvetica');

    hold(ax,'off');

end

function cmap = blue_red_white_cmap(n)

    if nargin < 1
        n = 256;
    end

    % Sequential/diverging-style palette:
    % blue -> red -> white
    anchors = [ ...
        0.12 0.35 0.65;   % muted blue
        0.40 0.62 0.82;   % lighter blue
        %0.60 0.12 0.12;   % darker red
        0.75 0.18 0.18;   % muted red
        1.00 1.00 1.00];  % white

    x  = linspace(0,1,size(anchors,1));
    xi = linspace(0,1,n);

    cmap = [ ...
        interp1(x,anchors(:,1),xi)', ...
        interp1(x,anchors(:,2),xi)', ...
        interp1(x,anchors(:,3),xi)'];cmap = cmap(end:-1:1,:);

end