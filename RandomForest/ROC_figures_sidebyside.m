% Load saved ROC figures
close all;clear;clc;

fig1 = openfig('TEST1star_Results/roc_curves_em10000.fig','invisible');
fig2 = openfig('TEST1star_Results/roc_curves_sim.fig','invisible');


% Create combined figure
newfig = figure;
newfig.Position = [100 50 1300 650];

tl = tiledlayout(newfig,1,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

% Get the main axes from each figure
axOld1 = findall(fig1,'Type','axes');
axOld2 = findall(fig2,'Type','axes');

% If there are multiple axes, choose the first non-legend axes
axOld1 = axOld1(1);
axOld2 = axOld2(1);

% Panel (a)
axNew1 = nexttile(tl,1);
copyobj(allchild(axOld1),axNew1);

xlabel(axNew1,axOld1.XLabel.String)
ylabel(axNew1,axOld1.YLabel.String)
% title(axNew1,'Emulator-trained')

xlim(axNew1,xlim(axOld1))
ylim(axNew1,ylim(axOld1))

% Panel (b)
axNew2 = nexttile(tl,2);
copyobj(allchild(axOld2),axNew2);

xlabel(axNew2,axOld2.XLabel.String)


% title(axNew2,'Simulator-trained')

xlim(axNew2,xlim(axOld2))
ylim(axNew2,ylim(axOld2))

% Shared formatting
set([axNew1 axNew2], ...
    'FontName','Helvetica', ...
    'FontSize',22, ...
    'Box','on', ...
    'LineWidth',1.2)
ylabel(axNew1,axOld1.YLabel.String,'FontSize',30)
xlabel(axNew1,axOld1.XLabel.String,'FontSize',30)
xlabel(axNew2,axOld2.XLabel.String,'FontSize',30)

grid(axNew1,'on')
grid(axNew2,'on')
yticklabels(axNew2,'')
axis(axNew1,'square')
axis(axNew2,'square')

% Add diagonal reference lines if needed
hold(axNew1,'on')
plot(axNew1,[0 1],[0 1],'k--', ...
    'LineWidth',2.6, ...
    'HandleVisibility','off')

legend(axNew1,'Location','southeast','FontSize',18)
legend(axNew2,'Location','southeast','FontSize',18)

hold(axNew2,'on')
plot(axNew2,[0 1],[0 1],'k--', ...
    'LineWidth',2.6, ...
    'HandleVisibility','off')

text(axNew1, -0.05, 0.99, '(a)', ...
    'Units','normalized', ...
    'FontWeight','bold', ...
    'FontSize',25, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'Clipping','off');

text(axNew2, -0.05, 0.99, '(b)', ...
    'Units','normalized', ...
    'FontWeight','bold', ...
    'FontSize',25, ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','bottom', ...
    'Clipping','off');

% Optional: common axis labels/title
% title(tl,'One-vs-rest ROC curves', ...
%     'FontName','Helvetica', ...
%     'FontSize',18, ...
%     'FontWeight','bold')



% Close original figures
close(fig1)
close(fig2)
