function [status, length, stats] = create_sum_table_LARGE1(directory,in_table,loc,DT)
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
    Max = zeros(1,numel(variablenames));
    Min = zeros(1,numel(variablenames));
    Median = zeros(1,numel(variablenames));

    Power = zeros(1,numel(variablenames));
    BandWidth = zeros(1,numel(variablenames));
    Mobility = zeros(1,numel(variablenames));
    Complexity = zeros(1,numel(variablenames));
    NonSI = zeros(1,numel(variablenames));
    ConLoc = zeros(1,numel(variablenames));
    MaxRat = zeros(1,numel(variablenames));
    FirstRat = zeros(1,numel(variablenames));
    DifLoc = zeros(1,numel(variablenames));
    NumCrossing = zeros(1,numel(variablenames));
    MeanDif = zeros(1,numel(variablenames));
    StdDif = zeros(1,numel(variablenames));    

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
        Max(1,i) = max(x(trans:end));
        Min(1,i) = min(x(trans:end));
        Median(1,i) = median(x(trans:end));

        % Calculate More complex Statistics
        [bw,flo,flh,pw]=obw(x(trans:end),1/DT);
        Power(1,i) = pw;
        BandWidth(1,i) = bw;
        Mobility(1,i) = mobility(x(trans:end));
        Complexity(1,i) = complexity(x(trans:end));

        % Non-Stationary Index Related
        n=30; % Number of segments to find
        [nonsi,conLoc,maxrat,firstrat,difloc] = nonstationaryInd(x(trans:end),n);
        NonSI(1,i) = nonsi;
        ConLoc(1,i) = conLoc;
        MaxRat(1,i) = maxrat;
        FirstRat(1,i) = firstrat;
        DifLoc(1,i) = difloc;

        % Crossing Scores
        [num,mdif,stdif] = crossings(x(trans:end),1/DT);
        NumCrossing(1,i) = num;
        MeanDif(1,i) = mdif;
        StdDif(1,i) = stdif;

        name = variablenames{i};
        names(i) = string(name) ;
    end
    Means = Means';
    Stds = Stds';
    Skewness = Skewness';
    Kurtosis = Kurtosis';
    Max = Max';
    Min = Min';
    Median = Median';

    Power = Power';
    BandWidth = BandWidth';
    Mobility = Mobility';
    Complexity = Complexity';
    NonSI = NonSI';
    ConLoc = ConLoc';
    MaxRat =MaxRat';
    FirstRat = FirstRat';
    DifLoc = DifLoc';
    NumCrossing = NumCrossing';
    MeanDif = MeanDif';
    StdDif = StdDif';

    T = table(Means,Stds,Skewness,Kurtosis,Max,Min,Median,Power,BandWidth,Mobility,Complexity,NonSI,ConLoc,MaxRat,FirstRat,DifLoc,NumCrossing,MeanDif,StdDif);
    T.Properties.RowNames = names;
    output_ID = directory + "/SensorData_SumLarge.txt";
    writetable(T,output_ID,'WriteRowNames',true)
    status = "New Table made";
    stats = {"mean","sd","skew","kurt","max","min","med","pow","BD","mob","com","nonsi","conloc","mrat","frat","dfloc","numcross","mdif","stdif"};
end

