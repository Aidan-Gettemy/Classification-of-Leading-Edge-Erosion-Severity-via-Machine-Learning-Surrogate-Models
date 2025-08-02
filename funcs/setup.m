function status = setup(tableRow, auxiliary)
    %SETUP This function drives all of the helper functions. 
    % After the files are changed, the output channels are selected.  Finally,
    % this function calls the testdriver function to do the simulation.

    TempID = auxiliary{6};
    testNum = auxiliary{4};
    testDur = auxiliary{2};
    DT = auxiliary{3};
    
    % ******************************
    % Section One: Simulation set up
    % ******************************
    
    % Make the README file
    
    readmeTempID = TempID+"/README_TEMPLATE.txt";
    header = make_readme(tableRow,readmeTempID,testNum,testDur,DT);

    % Specify the wind conditions
    wind_input = tableRow(1,[1,2,4]).Variables;
    readfile_ID = TempID + "/modules/wind/steady_wind.wnd";
    writefile_ID = "Simulate" + "/modules/wind/steady_wind.wnd";
    status = chg_wnd(readfile_ID,writefile_ID,wind_input,testDur);
    
    % Prime the blade pitch and the rotor speed

    startPitch = fix_init_bldptch(wind_input(2));
    startRTSpeed = fix_in_rt_speed(wind_input(2));
    
    % Let off on the blade pitch 
    if wind_input(2)<18
        startPitch = max(startPitch-7,0);
    end

    readfile_ID = TempID + "/modules/NRELOffshrBsline5MW_Onshore_ElastoDyn.dat";
    writefile_ID = "Simulate" + "/modules/NRELOffshrBsline5MW_Onshore_ElastoDyn.dat";
    status = chg_pitch(readfile_ID,writefile_ID,startPitch,startRTSpeed);
    
    % Change the main .fst file
    expName = auxiliary{1};
    airdens = tableRow(1,3).Variables;
    readfile_ID = TempID + "/5MW_Land_DLL_WTurb.fst";
    writefile_ID = "Simulate" + "/" + header + ".fst";
    status = chg_fst(readfile_ID,writefile_ID,airdens,header,testDur,DT,expName,testNum);
    
    % Iterate through each blade to change Airfoils
    input_vector = tableRow.Variables;
    for i = 1:3
        folder = "blade" + num2str(i);
        %   Change all the airfoils
        
        % here is a cell that contains all of the airfoils we need and the
        % erosion region linked to them {airfoil,erosion region}
        airfoils = {
            {"DU40_A17.dat",1},{"DU35_A17_1.dat",1},...
            {"DU35_A17_2.dat",2},{"DU30_A17.dat",2},...
            {"DU25_A17_1.dat",3},{"DU25_A17_2.dat",3},...
            {"DU21_A17_1.dat",4},{"DU21_A17_2.dat",4},...
            {"NACA64_A17_1.dat",5},{"NACA64_A17_2.dat",5},...
            {"NACA64_A17_3.dat",6},...
            {"NACA64_A17_4.dat",6},{"NACA64_A17_5.dat",6},...
            {"NACA64_A17_6.dat",6},{"NACA64_A17_7.dat",6}};
        readfile_ID = cell(1,15);
        writefile_ID = cell(1,15);
        for j = 1:15
            aircell{1} = TempID + ...
                "/modules/" + folder + "/airfoils/" + airfoils{1,j}{1};
            aircell{2} = airfoils{1,j}{2};
            readfile_ID{1,j} = aircell;
            writefile_ID{1,j} = "Simulate" + ...
                "/modules/" + folder + "/airfoils/" + airfoils{1,j}{1};
        end
        er_ind = 5 + (i-1)*6;
        erosion = input_vector(er_ind:er_ind+5);
        status = chg_af(readfile_ID,writefile_ID,erosion);
    end
    status = "All files updated";

    % ******************************
    % Section Two: Outputs
    % ******************************
    
    % Now we have to set up the output channels
    structure = "Simulate/modules/NRELOffshrBsline5MW_Onshore_";
    fileIDs = {"AeroDyn15.dat","ElastoDyn.dat","InflowWind.dat","ServoDyn.dat"};
    OutChanID = "OutputChannels.txt";
    startlines = [131,116,67,107];
    status = chg_outchan(structure,fileIDs,OutChanID,startlines);

    % ******************************
    % Section Three: Run and Clean-Up
    % ******************************

    % Now we are ready to run the simulation 
    StatusFileID = auxiliary{5};
    status = testdriver(header,expName);

    % As we go, write down the result folder of each completed test to status file:
    ExperimentID = "Data/"+expName;
    if testNum==auxiliary{7}
        test_cell{1,1} = ExperimentID+"/"+header;
    else
        data = gather_up(StatusFileID);
        for j = 1:numel(data)
            test_cell{1,j} = data{1,j};
        end
        test_cell{1,j+1} = ExperimentID+"/"+header;
    end
    fileID = fopen(StatusFileID,'w');
    fprintf(fileID,'%s\n',test_cell{:});
    fclose(fileID);
    % Indicate the progress:
    display = ['Currently finished with test ',num2str(testNum)];
    disp(display)
    status = header + " simulation is complete";
end

