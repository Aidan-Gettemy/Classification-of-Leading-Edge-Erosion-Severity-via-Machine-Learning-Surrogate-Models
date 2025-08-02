function mob = mobility(s)
%MOBILITY Calculates the Mobility Feature of the time series
    mob = sqrt(var(diff(s))/var(s));
end

