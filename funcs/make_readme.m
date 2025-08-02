function header = make_readme(tableRow,readmeTempID,testNum,testDur,DT)
%MAKE_README This function makes the readme to document this specific test
    %       input_vector: this holds the following in this order:
    
    % [wind direction, wind speed, air density, wind shear, 
    % blade_1_erosion_1,blade_1_erosion_2, blade_1_erosion_3,
    % blade_1_erosion_4, blade_1_erosion_5, blade_1_erosion_6,
    % blade_2_erosion_1, blade_2_erosion_2, blade_2_erosion_3,
    % blade_2_erosion_4,blade_2_erosion_5, blade_2_erosion_6, 
    % blade_3_erosion_1,blade_3_erosion_2, blade_3_erosion_3,
    % blade_3_erosion_4, blade_3_erosion_5, blade_3_erosion_6]

    %   Output:
    %        header: this is the name for the test

    % Grab the inputs from the table
    inputs = tableRow(1,:).Variables;

    % Make the header
    name = "";
    for i = 1:3
        var = num2str(inputs(1,i));
        name = name + "_" + var;
    end
    
    header = "Test" + num2str(testNum) + name;

    % Use gather_up to put the template ReadMe lines into a cell
    data = gather_up(readmeTempID);
    
    % Change the lines
    formats = {["READ ME: ","entry"],[0,1]};
    columns = [2];
    edit_type = {{"replace",header}};
    data{2} = editor(formats,columns,edit_type,data{2},0);
    for i = 4:7
        ttle = split(data{i});
        formats = {[ttle(1),"entry"],[0,1]};
        columns = [2];
        edit_type = {{"replace",inputs(1,i-3)}};
        data{i} = editor(formats,columns,edit_type,data{i},0);
    end

    for i = 13:18
        ttle = split(data{i});
        formats = {[ttle(1),"entry"],[0,1]};
        columns = [2];
        edit_type = {{"replace",inputs(1,i-8)}};
        data{i} = editor(formats,columns,edit_type,data{i},0);
    end

    for i = 21:26
        ttle = split(data{i});
        formats = {[ttle(1),"entry"],[0,1]};
        columns = [2];
        edit_type = {{"replace",inputs(1,i-10)}};
        data{i} = editor(formats,columns,edit_type,data{i},0);
    end


    for i = 29:34
        ttle = split(data{i});
        formats = {[ttle(1),"entry"],[0,1]};
        columns = [2];
        edit_type = {{"replace",inputs(1,i-12)}};
        data{i} = editor(formats,columns,edit_type,data{i},0);
    end

    % Change the lines at the end
    formats = {["Simulation_time: ","entry"],[0,1]};
    columns = [2];
    edit_type = {{"replace",testDur}};
    data{37} = editor(formats,columns,edit_type,data{37},0);

    formats = {["DT: ","entry"],[0,1]};
    columns = [2];
    edit_type = {{"replace",DT}};
    data{38} = editor(formats,columns,edit_type,data{38},2);
    
    % Save the results out
    showthis = ['Test Header ', header, ' --- Test Duration: ',testDur];
    disp(showthis)
    save_name = "Simulate/" + header + "_README.txt";
    lay_down(data,save_name)

end

