function [num,meandif,stddif] = crossings(s,freq)
%CROSSINGS Returns statistics related to how often the signal crosses its
% median value
% Calculates the number of times that the signal crosses its 
    % median value.  Then it returns that count, as well as the mean
    % time between crossings, and the standard deviation of that crossing 
    % time

    % first locate the function's mean value
    m = median(s);
    % create a function which has a maximum whenever it crosses the mean
    f = @(x,m) exp(-(x-m).^2);
    
    [peaks,locs] = findpeaks(f(s,m),freq);
    
    dif_locs = diff(locs);
    
    num = numel(locs);
    meandif = mean(dif_locs);
    stddif = std(dif_locs);
end

