function file_cell = gather_up(file_name)
%GATHER_UP Reads all the lines of the file into a cell -> returns the cell
%   Input: 
%         file_name: the character that holds the location of the file
%   Output: 
%          file_cell: a (1,num_lines) cell with each cell a copy of line i
    fileID = fopen(file_name,'r');
    file_cell = cell(1);
    for k = 1:1000
        x = fgetl(fileID);
        if x == -1
            break
        end
        file_cell{k} = x;
    end
    fclose(fileID);
end

