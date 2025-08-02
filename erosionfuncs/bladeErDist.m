function samps = bladeErDist(severity,num)
    a = severity;
    
    nodeLocs = [0, 2.8667, 5.6, 8.333, 11.75, ...
        15.85, 19.95, 24.05, 28.15, 32.25, 36.35, ...
        40.45, 44.55, 48.65, 52.75, 56.1667, 58.9, 61.633];
    
    reg1 = [nodeLocs(4) nodeLocs(6)];
    reg2 = [nodeLocs(6) nodeLocs(8)];
    reg3 = [nodeLocs(8) nodeLocs(10)];
    reg4 = [nodeLocs(10) nodeLocs(12)];
    reg5 = [nodeLocs(12) nodeLocs(14)];
    reg6 = [nodeLocs(14) nodeLocs(18)];
    
    total_len = nodeLocs(18) - nodeLocs(4);
    
    mids = zeros(6,1);
    
    for i = 1:6
        phrase = "reg"+num2str(i);
        phrase = "("+phrase+"(2)+"+phrase+"(1))/2" +"-nodeLocs(4)";
        phrase = "("+phrase+")/total_len";
        phrase = "mids("+num2str(i)+",1) = "+phrase+";";
        eval(phrase)
    end
    
    % erosion shape functions 
    f = @(x,a) a*x;
    
    covar = @(x,y,a,l) a*a*exp(-((x-y).^2)/(2*l^2));
    
    % Construct the mean vector
    
    mean_er = f(mids,a);
    
    % Construct the covariance matrix
    Cov_er = eye(6);
    for i = 1:numel(mids)
        for j = i:numel(mids)
    
            l = (mids(i)+mids(j))/2;
            l = sqrt(l);
            m = f(min(mids(i),mids(j)),a);
            
            Cov_er(i,j) = covar(mids(i),mids(j),(m)*1/10,l);
        
            Cov_er(j,i) = Cov_er(i,j);  
        end
    end
    
    %rng('default')  % For reproducibility
    R = mvnrnd(mean_er,Cov_er,num);
    for i = 1:numel(R(:,1))
        for j = 1:numel(R(1,:))
            R(i,j) = min(max(R(i,j),0),1);
        end
    end
    samps=R;
end

