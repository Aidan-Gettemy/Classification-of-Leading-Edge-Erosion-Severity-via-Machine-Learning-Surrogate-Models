function status = lay_down(file_cell, file_name)
%LAY_DOWN Write out the modified file cell back into a file
%   Input: 
%       file_cell: cell containing the modified file lines
%       file_name: the location to save the file
%   Output:
%       status: confirm that the file is modified
    fileID = fopen(file_name,'w');
    fprintf(fileID,'%s\n',file_cell{:});
    fclose(fileID);
    status = file_name + " modification complete.";
end

