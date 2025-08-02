function expTab = combineResults(M,StatusFileID,variableList)
%COMBINERESULTS Assemble one table of inputs and outputs
%   The inputs, from table M, will be the first columns, and the outputs,
%   from each experiment that were gathered in the summary table of each
%   simulation, will makeup the rest of the columns.

% Gather the names of the tests from the Statusfile
data = gather_up(StatusFileID);

% Grab the output channel names:
nameID = data{1,1} + "/Sensor_Data/output_names.mat";
names = load(nameID);
names = names.Output_Names;

% Now we will create all of the column names for the outputs from the
% experiment
iter = 1;
for i = 1:numel(variableList)
    for j = 1:numel(names)
        varnames(iter) = string(names{1,j}{1})+variableList{i};
        iter = iter+1;
    end
end

% Now we will put the summary data for each output channel variable for each 
% statistic together
resultMat = zeros(numel(data),numel(varnames));
for i = 1:numel(data) % Each simulation is its own row
    % Grab that table of data
    tableID = data{1,i}+"/Sensor_Data/SensorData_Sum.txt";
    SumTab = readtable(tableID,"ReadRowNames",true);
    for j = 1:numel(variableList) % Then we cycle over each summary statistic
        for k = 1:numel(names) % And we do that for each output channel
            resultMat(i,(j-1)*numel(names)+k) = SumTab{k,j};
        end
    end
end

% Now we turn that matrix into a table
resultTable = array2table(resultMat,"VariableNames",varnames);

% Now we concatenate the outputs and the inputs
expTab = cat(2,M,resultTable);
end

