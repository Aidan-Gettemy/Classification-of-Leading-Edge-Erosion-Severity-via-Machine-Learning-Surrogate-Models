function status = plot_ts(variables,Table)
%PLOT_TS This will plot the time series for a test in an experiment from
%the data folder
%   Input: 
%       variables: what are the name and units { {"name","units"},...}
%       Table: table of the results
%   Output: 
%       status: did it work
    % Print out a table of outputs to look at;
    disp("--------------------------------- Outputs -------------------------------------------")
    disp('--------------------------------------------------------------------------------------')
    name1 = 'variable';
    units1 = 'unit';
    name2 = 'variable';
    units2 = 'unit';
    name3 = 'variable';
    units3 = 'unit';
    vec = ['#','----',name1,'--------',units1,'-----',...
        '#','----',name2,'--------',units2,'-----',...
        '#','----',name3,'--------',units3];
    disp(vec)
    stop = 0;
    i = 1;
    if 3*i-2 > numel(variables)
        name1 = '***';
        units1 = '***';
        stop = 1;
    else
        name1 = variables{3*i-2}{1,1};
        units1 = variables{3*i-2}{1,2};
    end
    
    if 3*i-1 > numel(variables)
        name2 = '***';
        units2 = '***';
        stop = 1;
    else
        name2 = variables{3*i-1}{1,1};
        units2 = variables{3*i-1}{1,2};
    end
    
    if 3*i > numel(variables)
        name3 = '***';
        units3 = '***';
        stop = 1;
    else
        name3 = variables{3*i}{1,1};
        units3 = variables{3*i}{1,2}; 
    end
    for i = 2:1000
        a = 15-length(name1);
        aa = '-';
        for j = 1:a
            aa = strcat(aa,'-');
        end
        b = 15-length(name2);
        ba = '-';
        for j = 1:b
            ba = strcat(ba,'-');
        end
        c = 15-length(name3);
        ca = '-';
        for j = 1:c
            ca = strcat(ca,'-');
        end
        
        ab = 8-length(units1);
        aab = '-';
        for j = 1:ab
            aab = strcat(aab,'-');
        end
        bb = 8-length(units2);
        bab = '-';
        for j = 1:bb
            bab = strcat(bab,'-');
        end
        cb = 8-length(units3);
        cab = '-';
        for j = 1:cb
            cab = strcat(cab,'-');
        end
        s1 = 4-length(num2str(3*i-2-3));
        s2 = 4-length(num2str(3*i-1-3));
        s3 = 4-length(num2str(3*i-3));
        ss1 = '-';
        for j = 1:s1
            ss1 = strcat(ss1,'-');
        end
        
        ss2 = '-';
        for j = 1:s2
            ss2 = strcat(ss2,'-');
        end
       
        ss3 = '-';
        for j = 1:s3
            ss3 = strcat(ss3,'-');
        end

        vec = [num2str(3*i-2-3),ss1,name1,aa,units1,aab,...
        num2str(3*i-1-3),ss2,name2,ba,units2,bab,...
        num2str(3*i-3),ss3,name3,ca,units3];
        disp(vec)
        if stop == 1
            break
        end
        if 3*i-2 > numel(variables)
            name1 = '***';
            units1 = '***';
            stop = 1;
        else
            name1 = variables{3*i-2}{1,1};
            units1 = variables{3*i-2}{1,2};
        end
        
        if 3*i-1 > numel(variables)
            name2 = '***';
            units2 = '***';
            stop = 1;
        else
            name2 = variables{3*i-1}{1,1};
            units2 = variables{3*i-1}{1,2};
        end
        
        if 3*i > numel(variables)
            name3 = '***';
            units3 = '***';
            stop = 1;
        else
            name3 = variables{3*i}{1,1};
            units3 = variables{3*i}{1,2}; 
        end
    end
    disp('--------------------------------------------------------------------------------------')
    ex = 0;
    iter = 1;
    legnd = cell(1);
    while ex == 0
        x_value = input('Enter the number of the variable for the x axis:  ');
        y_value = input('Enter the number of the variable for the y axis:  ');

        % Extract vectors from the table
        x = Table(:,x_value);
        x = x.Variables;
        y = Table(:,y_value);
        y = y.Variables;
       
        % Grab corresponding names and units
        xname = variables{x_value}{1,1};
        xun = variables{x_value}{1,2};
        yname = variables{y_value}{1,1};
        yun = variables{y_value}{1,2};

        % Last 30 seconds or 4800 rows of the table is past the transient
        % area
        % (hopefully)

        a = 1;
        after_trans = "";
        if input('Avoid transients? enter 1: ') == 1
            a = numel(x)-4800;
            after_trans = after_trans + ": After Transients";
        end

        % Form the title;
        ttl = yname + " vs " + xname + after_trans;

        % Now we will plot x vs y
        if iter > 1
            r = input('Would you like to close the figure, if yes type 1: ');
            if r == 1
                close
                legnd = cell(1); %reset the cell
                figure
                iter = 1;
            else
                hold on
                ttl = "Plot of Various Outputs";
            end
        end
        if iter == 1
            figure
        end
        
        plot(x(a:end),y(a:end),LineWidth=2);
        title(ttl)
        xla = strcat(xname , xun);
        yla = strcat(yname , yun);
        xlabel(xla)
        ylabel(yla)
        legnd{iter} = strcat(strcat(xname,' vs '),yname);
        legend(legnd)

        grid on
        
        ex = input('When finish enter 1: ');
        iter = iter + 1;
    end
    

    status = " Finished Plotting ";
end

