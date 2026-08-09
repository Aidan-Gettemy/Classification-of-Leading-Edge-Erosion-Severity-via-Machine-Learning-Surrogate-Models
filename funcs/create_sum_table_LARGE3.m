function [status, length, stats] = create_sum_table_LARGE3(directory,in_table,loc,DT)
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

    RMSVals = zeros(1,numel(variablenames));
    NormFirstDiffs = zeros(1,numel(variablenames));
    BandPowers1P = zeros(1,numel(variablenames));
    BandPowers3P = zeros(1,numel(variablenames));
    Lag1Diffs = zeros(1,numel(variablenames));
    Lag1AutoCorrs = zeros(1,numel(variablenames));

    Fs = 1/DT;                 % sampling frequency
    freqBand = [0.104 .222];      % Hz, choose based min and max rotor speeds +-10%
    for i = 1:numel(variablenames)
        x = Table(:,variablenames{i});
        x = x.Variables;
      

        if i == 1
            length = numel(x); % Add this for detection of errors
        end
        trans = numel(x) - loc*(1/DT);

        xwin = x(trans:end);
    
        Means(1,i) = mean(xwin);
        Stds(1,i) = std(xwin);
        Skewness(1,i) = skewness(xwin);
        Kurtosis(1,i) = kurtosis(xwin);
    
        % New features
        dx = diff(xwin);
    
        RMSVals(1,i) = rms(xwin);
    
        % Normalized first difference
        % This measures the relative step-to-step variation in the signal.
        NormFirstDiffs(1,i) = rms(dx) / rms(xwin);
    
        % Band power in selected frequency band
        BandPowers1P(1,i) = simpleBandPower(xwin, Fs, freqBand);
        BandPowers3P(1,i) = simpleBandPower(xwin, Fs, 3*freqBand);
    
        % Lag-1 difference
        % Mean absolute difference between consecutive samples.
        Lag1Diffs(1,i) = mean(abs(dx));
    
        name = variablenames{i};
        names(i) = string(name);

        Lag1AutoCorrs(1,i) = corr(xwin(1:end-1), xwin(2:end));
    end
    Means = Means';
    Stds = Stds';
    Skewness = Skewness';
    Kurtosis = Kurtosis';
    
    RMSVals = RMSVals';
    NormFirstDiffs = NormFirstDiffs';
    BandPowers1P = BandPowers1P';
    BandPowers3P = BandPowers3P';
    Lag1Diffs = Lag1Diffs';
    Lag1AutoCorrs = Lag1AutoCorrs';
    
    T = table(Means,Stds,Skewness,Kurtosis,RMSVals,NormFirstDiffs, ...
        BandPowers1P, BandPowers3P,Lag1Diffs,Lag1AutoCorrs);
    T.Properties.RowNames = names;
    output_ID = directory + "/SensorData_SumLarge3.txt";
    writetable(T,output_ID,'WriteRowNames',true)
    status = "New Table made";
    stats = {"mean","sd","skew","kurt","rms","nfd","bp1","bp3p","l1d",'l1ac'};
end

