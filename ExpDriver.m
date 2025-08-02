clc;close;clear;
addpath funcs/
addpath Simulate/
addpath Template_IEA-15-240-RWT-Monopile/
%% Experiment Settings

% Experiment Name
expName = "TwBaseDamageMorris";
% TemplateID: set the location for the Template Files
TempID = "Template_IEA-15-240-RWT-Monopile";
% Simulation Bounds (which row to start and stop on)
JobNum = [1, 50];
% Test Duration in seconds
test_dur = 180;%5600;
% Extract Statistics from the last x seconds
trans = 60;%5600;
% Time Step
DT = 1/200;
% Delete .out files
delOut = "false"; %"true" or "false"
% Delete Big TS dataTable
delTab = "false"; %"true" of "false"

% Run Simulation/Clean Up Results

% Input Table ID
inTableID = expName+"_inTable.txt";

% ExperimentID: determines the location of the result folder
ExperimentID = "Data/"+expName;

% StatusFileID: located the StatusFile, which manages the experiment
StatusFileID = expName+"_"+num2str(JobNum(1))+"_"+num2str(JobNum(2))+"_Status.txt";

% Go ahead and make all the prep-folders and files
status = mkdir(ExperimentID);

% Read in the ExpInputTable
M = readtable(inTableID);

% Iterate through Simulation Jobs
for i = JobNum(1):JobNum(2)
    % Define the auxiliary setup inputs
    aux = {expName,test_dur,DT,i,StatusFileID,TempID,JobNum(1)};
    % Simulate Row i of ExpInputTable, according to stated SetUpFunction
    status = setup(M(i,:),aux);
end

% Gather data from StatusFile
data = gather_up(StatusFileID);

% Iterate over StatusFile
for i = 1:numel(data)
    % Make Summary Statistics for each Simulation Job
    disp(data{i})
    line = split(data{i},"/");
    TestID = line{3};
    status = resultfunc(ExperimentID,TestID,trans,i,DT);

    if strcmp("true",delOut) == 1
        % Delete the .out files  
        oldfolder = cd(ExperimentID+"/"+TestID);
        delete *out
        delete *outb
        cd(oldfolder)
        disp("Deleted the Out file: "+TestID)
    end

    if strcmp("true",delTab) == 1
        oldfolder = cd(ExperimentID+"/"+TestID+ "/" +"Sensor_Data");
        delete SensorDataT.txt
        cd(oldfolder)
        message = "deleted table " + TestID;
        disp(message)
    end

end

% Create ExperimentResultTable
variableList = {'mean','sd'};
expTab = combineResults(M,StatusFileID,variableList);

% Save the Table to the Experiment Data Folder, and move the status file
% there as well
saveTabID = ExperimentID+"/ExperimentResultTable.txt";
writetable(expTab,saveTabID);
status = movefile(StatusFileID, ExperimentID);
%%
