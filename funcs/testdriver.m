function status = testdriver(header,expName)
%TESTDRIVER Run the Simulation we set up
%   After setting up everything, we can run the simulation as it is
%   currently set up.  The resulting data will be moved to an appropriate
%   folder, and the test saved to the status file.

% Set the executable
executable = "openfast_x64.exe";
%"/Users/aidangettemy/anaconda3/bin/openfast";

% Write the command
fastFileName = "Simulate/" + header + ".fst";
command = executable + " " + fastFileName;

% Run the simulation
[status,result] = system(command,'-echo');

% Move the results
lookfolder="Simulate/";
ExperimentID = "Data/"+expName+"/";
status = move_clean(lookfolder,ExperimentID,header);

status = "Test complete";
end

