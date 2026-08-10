%% Combine Figures into one plot
clc;close all;clear;

option = 'A';% 'B', 'C'

switch option
    case 'A'
        C_emu = load("TEST1star_Results\CMEAN_emu10000.mat");
        C_emu = C_emu.Cmean;
        C_sim = load("TEST1star_Results\CMEAN_sim.mat");
        classes = C_sim.classes;
        C_sim = C_sim.Cmean;

    case 'B'
        C_emu = load("TEST2_Results\CMEAN_emu10000.mat");
        C_emu = C_emu.Cmean;
        C_sim = load("TEST2_Results\CMEAN_sim.mat");
        classes = C_sim.classes;
        C_sim = C_sim.Cmean;

    case 'C'
        C_emu = load("TEST3_Results\CMEAN_em50000.mat");
        C_emu = C_emu.Cmean;
        C_sim = load("TEST3_Results\CMEAN_sim.mat");
        classes = C_sim.classes;
        C_sim = C_sim.Cmean;
end

%%
alpha = 0.75;

f = figure;
f.Position = [100 50 1300 650];

tl = tiledlayout(f,1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

% -----------------------------
% Emulation-trained classifier
% -----------------------------
ax1 = nexttile(tl,1);

imagesc(ax1,C_emu,'AlphaData',alpha)
axis(ax1,'square')
%colorbar(ax1)
drawgridaxis(C_emu,ax1)

xticks(ax1,1:numel(classes))
yticks(ax1,1:numel(classes))
xticklabels(ax1,string(classes))
yticklabels(ax1,string(classes))


%title(ax1,'Emulator-trained')

set(ax1, ...
    'FontName','Helvetica', ...
    'FontSize',24, ...
    'TickLabelInterpreter','none')
xlabel(ax1,'Predicted class','FontSize',30)
ylabel(ax1,'True class','FontSize',30)
addtext(C_emu)

% text(ax1,0.02,0.96,'(a)', ...
%     'Units','normalized', ...
%     'FontWeight','bold', ...
%     'FontSize',18)

% -----------------------------
% Simulation-trained classifier
% -----------------------------
ax2 = nexttile(tl,2);

imagesc(ax2,C_sim,'AlphaData',alpha)
axis(ax2,'square')
%colorbar(ax2)
drawgridaxis(C_emu,ax2)

xticks(ax2,1:numel(classes))
yticks(ax2,1:numel(classes))
xticklabels(ax2,string(classes))
yticklabels(ax2,string(classes))


%title(ax2,'Simulator-trained')

set(ax2, ...
    'FontName','Helvetica', ...
    'FontSize',24, ...
    'TickLabelInterpreter','none')
xlabel(ax2,'Predicted class','FontSize',30)
ylabel(ax2,'True class','FontSize',30)
addtext(C_sim)

% text(ax2,0.02,0.96,'(b)', ...
%     'Units','normalized', ...
%     'FontWeight','bold', ...
%     'FontSize',18)

% Use same colormap
colormap(f,blue_red_white_cmap)

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

% Shared colorbar
cb = colorbar(ax2);
cb.Layout.Tile = 'east';
% cb.Label.String = 'Row-normalized fraction';
cb.FontName = 'Helvetica';
cb.FontSize = 21;

% Use same color scale for both
clim(ax1,[0 1])
clim(ax2,[0 1])

% Match axes across panels
%linkaxes([ax1,ax2],'xy')

% % Shared limits
% xlim(axs(1),[0 0.5])
% ylim(axs(1),[0 1])

% Remove duplicate y-axis label/tick labels from second panel
ylabel(ax2, '')
ax2.YTickLabel = [];
%% Truy HEATMAP
f = figure;
f.Position = [100 100 1300 500];

tl = tiledlayout(f,1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

h1 = heatmap(tl,string(classes),string(classes),C_emu);
h1.Layout.Tile = 1;
h1.Title = 'Emulator-trained';
h1.XLabel = 'Predicted class';
h1.YLabel = 'True class';
%h1.Colormap = mutedbluecmap(256);
h1.ColorLimits = [0 1];

h2 = heatmap(tl,string(classes),string(classes),C_sim);
h2.Layout.Tile = 2;
h2.Title = 'Simulator-trained';
h2.XLabel = 'Predicted class';
h2.YLabel = 'True class';
%h2.Colormap = mutedbluecmap(256);
h2.ColorLimits = [0 1];


%% FUNCTIONS
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
