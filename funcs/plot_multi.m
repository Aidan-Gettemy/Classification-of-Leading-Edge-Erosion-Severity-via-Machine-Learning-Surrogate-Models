function [f,status] = plot_multi(batch_cells)
%PLOT_MULTI Each batch will have the data table, the list of output names, and the
%outputs we want to be plotted as a 2xn table with the first row the x axis
%and the second row the y axis.
    for i = 1:numel(batch_cells)
        data_cell = batch_cells{1,i};
        dataTable = data_cell{1};
        output_names = data_cell{2};
        plotpairs = data_cell{3};

        
        f = figure(Visible="on");
        hold on

        
        for j = 1:numel(plotpairs(1,:))
            % Extract vectors from the table
            x = dataTable(:,plotpairs(1,j));
            x = x.Variables;
            y = dataTable(:,plotpairs(2,j));
            y = y.Variables;
           
            % Grab corresponding names and units
            xname = output_names{plotpairs(1,j)}{1,1};
            xun = output_names{plotpairs(1,j)}{1,2};
            yname = output_names{plotpairs(2,j)}{1,1};
            yun = output_names{plotpairs(2,j)}{1,2};

            plot(x,y,LineWidth=2);
        
            legnd{j} = strcat(strcat(strcat(xname,xun)," vs "),strcat(yname,yun));

        end
        
        ttl = "Plot of "+data_cell{4}+" Variables";
        title(ttl)
        legend(legnd)
        xlabel('time (s)')
        ylabel('Output')
        % Set the color order



        
        
        colororder(parula(j))
    end

    status = " Finished Plotting";
end

