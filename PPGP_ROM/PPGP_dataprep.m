function [In_train,Out_train,In_test,Out_test,targets] = PPGP_dataprep(numvars,Importances,data,percent)
%PPGP_DATAPREP 
    suffixes = {"mean","sd","skew","kurt"};
    names = {"RootMxb1", "TipALxb1", "B1N6Cl", "B1N6Cd", "GenPwr"};
    
    iter = 1;
    for i = 1:numel(suffixes)
        for j = 1:numel(names)
            a = names{j}+suffixes{i};
            varnames(iter) = a;
            iter = iter + 1;
        end
    end
    
    others = {"WindDirection","WindSpeed","AirDensity"};
    for i =1:numel(others)
        a = others{i};
        varnames(iter) = a;
        iter = iter +1;
    end
    
    targets = varnames(Importances(1:numvars));
    
    % Create the Output
    % Select the Output we want 
    output_clean = data(1:10,targets);
    output_class1 = data(11:60,targets);
    output_class2 = data(61:110,targets);
    output_class3 = data(111:160,targets);
    output_class4 = data(161:210,targets);
    
    % Select the training data and testing data (recall the classes)
    In_clean = data(1:10,[1:2,3,5:10]);
    In_class1 = data(11:60,[1:2,3,5:10]);
    In_class2 = data(61:110,[1:2,3,5:10]);
    In_class3 = data(111:160,[1:2,3,5:10]);
    In_class4 = data(161:210,[1:2,3,5:10]);
    
    p = percent;% Testing percent
    cvpartc = cvpartition(numel(output_clean(:,1)),'HoldOut',p);
    cvpart1 = cvpartition(numel(output_class1(:,1)),'HoldOut',p);
    cvpart2 = cvpartition(numel(output_class2(:,1)),'HoldOut',p);
    cvpart3 = cvpartition(numel(output_class3(:,1)),'HoldOut',p);
    cvpart4 = cvpartition(numel(output_class4(:,1)),'HoldOut',p);
    
    In_trainc = In_clean(training(cvpartc),:).Variables;
    Out_trainc = output_clean(training(cvpartc),:).Variables;
    
    In_train1 = In_class1(training(cvpart1),:).Variables;
    Out_train1 = output_class1(training(cvpart1),:).Variables;
    
    In_train2 = In_class2(training(cvpart2),:).Variables;
    Out_train2 = output_class2(training(cvpart2),:).Variables;
    
    In_train3 = In_class3(training(cvpart3),:).Variables;
    Out_train3 = output_class3(training(cvpart3),:).Variables;
    
    In_train4 = In_class4(training(cvpart4),:).Variables;
    Out_train4 = output_class4(training(cvpart4),:).Variables;
    
    In_train = cat(1,In_trainc,In_train1);
    In_train = cat(1,In_train,In_train2);
    In_train = cat(1,In_train,In_train3);
    In_train = cat(1,In_train,In_train4);
    % 
    Out_train = cat(1,Out_trainc,Out_train1);
    Out_train = cat(1,Out_train,Out_train2);
    Out_train = cat(1,Out_train,Out_train3);
    Out_train = cat(1,Out_train,Out_train4);
    
    In_testc = In_clean(test(cvpartc),:).Variables;
    Out_testc = output_clean(test(cvpartc),:).Variables;
    
    In_test1 = In_class1(test(cvpart1),:).Variables;
    Out_test1 = output_class1(test(cvpart1),:).Variables;
    
    In_test2 = In_class2(test(cvpart2),:).Variables;
    Out_test2 = output_class2(test(cvpart2),:).Variables;
    
    In_test3 = In_class3(test(cvpart3),:).Variables;
    Out_test3 = output_class3(test(cvpart3),:).Variables;
    
    In_test4 = In_class4(test(cvpart4),:).Variables;
    Out_test4 = output_class4(test(cvpart4),:).Variables;
    
    In_test = cat(1,In_testc,In_test1);
    In_test = cat(1,In_test,In_test2);
    In_test = cat(1,In_test,In_test3);
    In_test = cat(1,In_test,In_test4);
    % 
    Out_test = cat(1,Out_testc,Out_test1);
    Out_test = cat(1,Out_test,Out_test2);
    Out_test = cat(1,Out_test,Out_test3);
    Out_test = cat(1,Out_test,Out_test4);
end

