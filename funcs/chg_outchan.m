function stat = chg_outchan(structure,fileIDs,OutChanID,startLines)
%CHG_OUTCHAN Adjust output channels
%   We take in the locations of the files to update in the simulate
%   folder.  Then we read in the output channels requested, and append them
%   to the end of the module files.
    fileID = fopen(OutChanID,'r');
    file_cell = cell(1);
    iter = 0;
    for k = 1:1000
        x = fgetl(fileID);
        if x == -1
            indices(iter+1) = k;
            break
        end
        y = split(x);
        a = str2double(y{1});
        if isnan(a) == 0
           iter = iter + 1;
           subiter = 1;
           indices(iter) = k;
           continue
        end  
        storage{iter,subiter} = x;
        subiter = subiter+1;
    end 
    fclose(fileID);
    for h =1:numel(fileIDs)
        data = gather_up(structure+fileIDs{h});
        b = startLines(h)-1;
        % Append the output Channels to the bottom of the file
        for i = 1:(indices(h+1)-indices(h)-1)
            data{b+i} = storage{h,i};
        end
        status = lay_down(data,structure+fileIDs{h});
    end
    stat = "Outputs appended to module files.";
end

