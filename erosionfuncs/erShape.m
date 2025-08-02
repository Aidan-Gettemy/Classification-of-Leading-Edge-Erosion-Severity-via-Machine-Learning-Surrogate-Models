function erProfile = erShape(type,alpha)
%ERSHAPE Return erosion severity value for each of 6 blade regions
%   Inputs: 
%       type: which of three functions to use
%       alpha: value to scale by
%   Outputs: severity level vector

    % Establish the aerodynamic node locations
    nodeLocs = [0, 2.8667, 5.6, 8.333, 11.75, ...
        15.85, 19.95, 24.05, 28.15, 32.25, 36.35, ...
        40.45, 44.55, 48.65, 52.75, 56.1667, 58.9, 61.633];
    
    % Establish the blade regions
    reg1 = [nodeLocs(4) nodeLocs(6)];
    reg2 = [nodeLocs(6) nodeLocs(8)];
    reg3 = [nodeLocs(8) nodeLocs(10)];
    reg4 = [nodeLocs(10) nodeLocs(12)];
    reg5 = [nodeLocs(12) nodeLocs(14)];
    reg6 = [nodeLocs(14) nodeLocs(18)];

    % Calculate total aerodynamically active length
    total_len = nodeLocs(18) - nodeLocs(4);

    % Calculate the midpoint of each region
    mids = zeros(6,1);
    for i = 1:6
        phrase = "reg"+num2str(i);
        phrase = "("+phrase+"(2)+"+phrase+"(1))/2" +"-nodeLocs(4)";
        phrase = "("+phrase+")/total_len";
        phrase = "mids("+num2str(i)+",1) = "+phrase+";";
        eval(phrase)
    end

    % Establish the shape functions
    f = @(x,alpha) alpha*x;

    g = @(x,alpha) alpha*x.^2;

    h = @(x,alpha) alpha*x.^3;
    
    % Calculate the erosion severity values
    if type == 1
        vals = f(mids,alpha);
    elseif type == 2
        vals = g(mids,alpha);
    elseif type ==3
        vals = h(mids,alpha);
    end
    
    erProfile = vals;
end

