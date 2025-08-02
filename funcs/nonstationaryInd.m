function [nonsi,conLoc,maxrat,firstrat,difloc] = nonstationaryInd(s,n)
%NONSTATIONARYIND Returns properties related to the stationarity of the
%time series.
%   nsi: returns the index given the input n subdivisions
%   conLoc: returns the number of subdivisions it takes for the nonstat
%   score to be less than 5% below the overall standard deviation
%   maxrat: returns the ratio of the maximum score to the standard
%   deviation
%   firstrat: returns the ratio of the first relative maximum to the
%   standard deviation
%   difloc: find the difference in location from max and first peak
    nonsi = nsi(s,n);

    f = @(x) nsi(s,x);

    y = zeros(1,1000);
    for i = 1:numel(y)
        y(1,i) = f(i);
    end

    limit = std(s);
    ydif = y-limit;
    g = find(ydif>-.05*limit);
    

    if numel(g) == 0
        conLoc = 1000;
    else
        conLoc = g(1);
    end

    
    [peaks,locs] = findpeaks(y);
    
    try
        maxrat = max(peaks)/limit;
    catch
        maxrat = 0;
    end

    d=size(maxrat);
    if d(1,2)==0
        maxrat = 0;
    end
    try
        firstrat = peaks(1)/limit;
    catch
        firstrat = 0;
    end

    try
        difloc = locs(peaks==max(peaks))-locs(1);
    catch
        difloc = 0;
    end

end

