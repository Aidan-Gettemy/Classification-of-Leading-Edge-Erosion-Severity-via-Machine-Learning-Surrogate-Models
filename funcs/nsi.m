function n_si = nsi(s,n)
%NSI Subfunction for nonstationaryInd
    x=linspace(1,numel(s),n+1);
    submeans = zeros(1,n-2);
    for i = 1:n-2
        submeans(1,i) = mean(s(round(x(i)):round(x(i+1))));
    end
    n_si = std(submeans);
end

