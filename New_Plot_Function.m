clc; close all; clear;
%%
erosion_profile = [0.01, 0.02, 0.1, 0.2, 0.5, 1];

useSeverityColor = false;   % false = fixed region colors, true = color by severity
showLegend       = true;

f = figure;
f.Position = [50 50 1250 650];

plot_blade(erosion_profile, useSeverityColor, showLegend);

function status = plot_blade(erosion_profile, useSeverityColor, showLegend)

    % Aerodynamic node locations and chord lengths
    nodeLocs = (1/61.5)*[0, 2.8667, 5.6, 8.333, 11.75, ...
        15.85, 19.95, 24.05, 28.15, 32.25, 36.35, ...
        40.45, 44.55, 48.65, 52.75, 56.1667, 58.9, 61.633];

    nodeHeights = [3.542, 3.542, 3.854, 4.167, 4.557, 4.652, ...
        4.458, 4.249, 4.007, 3.748, 3.502, 3.256, 3.010, ...
        2.764, 2.518, 2.313, 2.086, 1.419];

    hold on

    % Plot aerodynamic node lines
    for i = 1:numel(nodeLocs)
        plot([nodeLocs(i), nodeLocs(i)], ...
             [-0.25*nodeHeights(i), 0.75*nodeHeights(i)], ...
             'Color', [0.25 0.25 0.25], ...
             'LineWidth', 1.0, ...
             'HandleVisibility', 'off');
    end

    % Airfoil families / background regions
    regionBounds = [
        nodeLocs(2),  nodeLocs(4)
        nodeLocs(4),  nodeLocs(5)
        nodeLocs(5),  nodeLocs(6)
        nodeLocs(6),  nodeLocs(8)
        nodeLocs(8),  nodeLocs(9)
        nodeLocs(9),  nodeLocs(11)
        nodeLocs(11), nodeLocs(13)
        nodeLocs(13), nodeLocs(18)
    ];

    regionLabels = ["Cyl. 1", "Cyl. 2", "DU40", "DU35", ...
                    "DU30", "DU25", "DU21", "NACA 64"];

    regionColors = [
        0.75 0.75 0.75
        0.80 0.80 0.80
        1.00 0.60 0.60
        0.60 1.00 0.60
        0.60 0.60 1.00
        0.60 1.00 1.00
        1.00 0.60 1.00
        1.00 1.00 0.60
    ];

    for k = 1:size(regionBounds,1)
        h = xregion(regionBounds(k,1), regionBounds(k,2), ...
            'FaceColor', regionColors(k,:), ...
            'EdgeColor', 'k');
        h.FaceAlpha = 0.15;
        h.HandleVisibility = 'off';

        xmid = mean(regionBounds(k,:));
        ytxt = 5.0;

        text(xmid, ytxt, regionLabels(k), ...
            'Rotation', 90, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontName', 'Helvetica', ...
            'FontSize', 24, ...
            'FontWeight', 'normal');
    end

    % Erosion regions
    setcol = [
        0.90 0.10 0.10
        0.10 0.90 0.10
        0.10 0.20 0.90
        0.10 0.85 0.85
        0.90 0.10 0.90
        0.95 0.95 0.10
    ];

    setshape = ["h", "o", "diamond", "^", "pentagram", "square"];

    rstart = [5, 7, 9, 11, 13, 15];
    rend   = [6, 8, 10, 12, 14, 17];

    cmp = colormap("parula");

    % Plot the base cylinder airfoils in gray
    for i = 1:4
        regX = [nodeLocs(i:i+1)'; flip(nodeLocs(i:i+1)')];
        regY = [0.75*nodeHeights(i:i+1)'; flip(-0.25*nodeHeights(i:i+1)')];
    
        fill(regX, regY, [0.70 0.70 0.70], ...
            'FaceAlpha', 0.50, ...
            'EdgeColor', 'k', ...
            'LineWidth', 0.75, ...
            'HandleVisibility', 'off');
    end

    for j = 1:6

        if useSeverityColor
            idx = max(1, min(256, round(erosion_profile(j)*256)));
            c = cmp(idx,:);
        else
            c = setcol(j,:);
        end

        for i = rstart(j):rend(j)

            regX = [nodeLocs(i:i+1)'; flip(nodeLocs(i:i+1)')];
            regY = [0.75*nodeHeights(i:i+1)'; flip(-0.25*nodeHeights(i:i+1)')];

            fill(regX, regY, c, ...
                'FaceAlpha', 0.50, ...
                'EdgeColor', 'k', ...
                'LineWidth', 0.75, ...
                'HandleVisibility', 'off');

            [dotsX, dotsY] = meshgrid(min(regX):0.025:max(regX), ...
                                      min(regY):0.25:max(regY));

            in = inpolygon(dotsX, dotsY, regX, regY);

            if i == rstart(j)
                displayName = sprintf('Region %d', j);
                handleVis = 'on';
            else
                displayName = '';
                handleVis = 'off';
            end

            scatter(dotsX(in), dotsY(in), 30, ...
                'Marker', setshape(j), ...
                'MarkerFaceColor', c, ...
                'MarkerEdgeColor', 'k', ...
                'LineWidth', 1.0, ...
                'DisplayName', displayName, ...
                'HandleVisibility', handleVis);
        end
    end

    % Sensor location
    sens = 17;
    scatter(nodeLocs(sens), -0.125*nodeHeights(sens), 300, ...
        's', ...
        'MarkerFaceColor', 'r', ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Sensor');

    % Axes formatting
    xlim([0, 1.001])
    ylim([-2, 8])

    ax = gca;
    ax.FontName = 'Helvetica';
    ax.FontSize = 18;
    ax.FontWeight = 'normal';
    ax.LineWidth = 1.0;
    ax.Box = 'on';

    xlabel('r/R', ...
        'FontSize', 22, ...
        'FontWeight', 'normal', ...
        'FontName', 'Helvetica');

    ylabel('blade chord (m)', ...
        'FontSize', 22, ...
        'FontWeight', 'normal', ...
        'FontName', 'Helvetica');
    
    if showLegend

        hLeg = gobjects(1,7);
    
        for j = 1:6
            hLeg(j) = plot(nan, nan, ...
                'LineStyle', 'none', ...
                'Marker', setshape(j), ...
                'MarkerSize', 10, ...      % this controls legend marker size
                'MarkerFaceColor', setcol(j,:), ...
                'MarkerEdgeColor', 'k', ...
                'LineWidth', 1.2, ...
                'DisplayName', sprintf('Region %d', j));
        end
    
        hLeg(7) = plot(nan, nan, ...
            'LineStyle', 'none', ...
            'Marker', 's', ...
            'MarkerSize', 16, ...          % sensor legend marker size
            'MarkerFaceColor', 'r', ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 1.5, ...
            'DisplayName', 'Sensor');
    
        lgd = legend(hLeg, ...
            {'Region 1','Region 2','Region 3','Region 4','Region 5','Region 6','Sensor'}, ...
            'Location', 'northoutside');
    
        lgd.Orientation = 'horizontal';
        lgd.NumColumns = 4;
        lgd.FontName = 'Helvetica';
        lgd.FontSize = 18;
        lgd.FontWeight = 'normal';
        lgd.ItemTokenSize = [45, 24];
    
    end

    % Legend formatting
    % if showLegend
    %     lgd = legend('Location', 'northoutside');
    %     lgd.Orientation = 'horizontal';
    %     lgd.NumColumns = 4;
    %     lgd.FontName = 'Helvetica';
    %     lgd.FontSize = 18;
    %     lgd.FontWeight = 'normal';
    %     lgd.ItemTokenSize = [35, 18];
    % end

    if useSeverityColor
        cb = colorbar;
        cb.Label.String = 'Erosion severity';
        cb.Label.FontWeight = 'normal';
        cb.FontName = 'Helvetica';
        cb.FontSize = 16;
    end

    status = "Plotting complete";
end