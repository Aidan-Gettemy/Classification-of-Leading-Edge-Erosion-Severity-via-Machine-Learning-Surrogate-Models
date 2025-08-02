function cmp = complexity(s)
%COMPLEXITY Calculates the Complexity score of the time series
 cmp = mobility(diff(s))/mobility(s);
end

