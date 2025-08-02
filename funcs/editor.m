function line = editor(formats,columns,edit_type,data,flag)
%EDIT Splits the given line, edits given columns either by multiplying or
%replacing, then fixes line to the original format.
%   Input: 
%       formats: a cell that contains {[text snippets], [positions to put
%       replaced entries]}
%       columns: which columns we will edit
%       edit_type: a cell {{{replace/multiply},{value}},...}
%       data: the original line
%   Output:
%       line: the modified text

    raw = split(data);
    vals = {1,numel(columns)};
    for i = 1:numel(columns)
        % grab the value we want from the split data
        vals{1,i} = str2double(raw(columns(i))); 
        if edit_type{i}{1} == "replace"
            vals{1,i} = edit_type{i}{2};
        elseif edit_type{i}{1} == "int"
            vals{1,i} = num2str(edit_type{i}{2});
        else
            vals{1,i} = vals{1,i}*edit_type{i}{2};
        end
    end
    

    % Now the values have been changed appropriately 

    % We have to reformat the results

    % positions to put replaced entries is a vector of ones and zeros.  We
    % will iterate through this vector (row vector) and if a one is there,
    % we will place a value, and increase the iter, otherwise we will place
    % one of the text entries
    
    line = "";
    iter = 1;
    for i = 1:numel(formats{2})
        if formats{2}(i) == 0
            line = line + formats{1}(i);
        else
            if isnumeric(vals{1,iter})==1
                if flag == 0
                    line = line + num2str(vals{1,iter},'%.4f');
                elseif flag == 2
                    line = line + num2str(vals{1,iter},'%.5f');
                else
                    line = line + num2str(vals{1,iter},'%.15E');
                end
            else
                line = line + vals{1,iter};
            end
            iter = iter + 1;
        end
    end
end

