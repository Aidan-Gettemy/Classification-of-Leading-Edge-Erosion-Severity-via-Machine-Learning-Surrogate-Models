function [status, length, stats] = create_sum_table_LARGE2(directory,in_table,loc,DT)
%CREATE_SUM_TABLE go to the directory and make the summary table
%   We will read the in table and save a table of the following form: 
% Row names     mean        stardard deviation
%   var1        ----            --------    
%
    table_fileIN = directory + "/" + in_table;
    % Read the data
    Table = readtable(table_fileIN);
    % Now we have all of the data, grab the column names
    variablenames = Table.Properties.VariableNames;

    Means = zeros(1,numel(variablenames));
    Stds = zeros(1,numel(variablenames));
    Skewness = zeros(1,numel(variablenames));
    Kurtosis = zeros(1,numel(variablenames));

    for i = 1:numel(variablenames)
        x = Table(:,variablenames{i});
        x = x.Variables;
        if i == 1
            length = numel(x); % Add this for detection of errors
        end
        trans = numel(x)-loc*(1/DT);
        Means(1,i) = mean(x(trans:end));
        Stds(1,i) = std(x(trans:end));
        Skewness(1,i) = skewness(x(trans:end));
        Kurtosis(1,i) = kurtosis(x(trans:end));
        

        name = variablenames{i};
        names(i) = string(name) ;
    end
    Means = Means';
    Stds = Stds';
    Skewness = Skewness';
    Kurtosis = Kurtosis';
    
    T = table(Means,Stds,Skewness,Kurtosis);
    T.Properties.RowNames = names;
    output_ID = directory + "/SensorData_SumLarge.txt";
    writetable(T,output_ID,'WriteRowNames',true)
    status = "New Table made";
    stats = {"mean","sd","skew","kurt"};
end

