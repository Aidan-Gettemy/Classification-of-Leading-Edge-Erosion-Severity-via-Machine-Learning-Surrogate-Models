function [outputs,status] = create_mat_files(read_file)
%CREATE_MAT_FILES Turns the .out results into easily parsed tables
%   Inputs:
%      read_file: where to look for data files for each output
%   Ouput:
%       status: lets us know it worked
%       outputs: a cell that holds the name of each variable
    %   Create a new data folder in the test folder
    extracted_folder = split(read_file,"/");
    save_out = "";
    for i = 1:(numel(extracted_folder)-1)
        save_out = save_out + extracted_folder{i} + "/";
    end
    % Now we can do some work.
    save_out = save_out + "Sensor_Data";
    stat = mkdir(save_out);
%   Read the lines that give us all the variables and their
%   corresponding units.
    var_line = 7;
    units_line = 8;
%   cell = { {"variable", "unit"}, ...}
%   save that cell as a .mat file.
    outputs = cell(1);

    fileID = fopen(read_file,'r');
    
    data = cell(1);
    
    x = 0;
    iter = 1;
    while(x == 0)
        line = fgetl(fileID);
        if line == -1
            x = 1;
        end
        if iter == var_line
            names = split(line);
            for i = 1:numel(names)
                pair = cell(1,2);
                pair{1,1} = names{i};
                outputs{i} = pair;
            end
        end
        if iter == units_line
            units = split(line);
            for i = 1:numel(units)
                outputs{i}{1,2} = units{i};
            end
        end
        if iter > units_line
            x = 1;
        end
        iter = iter + 1;
    end
    fclose(fileID);
    Output_Names = outputs;
    output_ID = save_out + "/output_names.mat";
    save(output_ID,"Output_Names",'-mat')
    
    % Now we create a table
    SensorDataT = readtable(read_file,"FileType",'text',"NumHeaderLines",8);
    for i = 1:numel(outputs)
        %disp(outputs{i}{1,1});
        columnnames{i} = outputs{i}{1,1};
    end
    SensorDataT.Properties.VariableNames = columnnames;
    

    output_ID = save_out + "/SensorDataT.txt";
    writetable(SensorDataT,output_ID)

    status = "matfiles created";

%       read through the whole file line by line and split each line
%       add each value to a different array, each array is named by the
%       variable it represents.

%       save each variable array is its own ;mat file two d array, first
%       entry is time, second is values
end

