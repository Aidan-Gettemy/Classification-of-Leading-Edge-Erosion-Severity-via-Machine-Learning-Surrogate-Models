function inv = kdeInvSamp(alpha,storage)
    [fp,xfp] = kde(storage,ProbabilityFcn="cdf",Bandwidth="plug-in",Support="nonnegative",EvaluationPoints=linspace(0,1,10000));
    a = alpha;
    [mini, miniInd] = min((fp-a).^2);
    inv = xfp(miniInd);
end