function status = move_clean(look_folder,Experiment_ID, test_ID)
%MOVE_CLEAN Moves all output files, readme file, and .fst file to a
% subdirectory in the data directory
%   Input:
%       look_folder: the directory that holds simulation runs
%       Experiment_ID: name of the directory containing data for this set
%       of simulations
%       test_ID: name of the test that just ran
%   Output:
%       status: indicates if process was successful
    % Folder Identification
    folder_ID = Experiment_ID + "/" + test_ID;
    stat = mkdir(folder_ID);
    suffixes = {{'.AD.sum'},{'.ech'},{'.ED.sum'},{'.out'},...
    {'.outb'},{'.SrvD.sum'},{'.sum'},{'.UA.sum'},...
    {'.fst'},{'_README.txt'},{'.log'}};
    
    for i = 1:numel(suffixes)
        moving_file = look_folder + test_ID + suffixes{i};
        status(1,i) = movefile(moving_file, folder_ID);
    end
    
end

