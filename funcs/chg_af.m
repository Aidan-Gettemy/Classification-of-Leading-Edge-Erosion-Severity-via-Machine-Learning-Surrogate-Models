function status = chg_af(readfile_ID,writefile_ID,bladex_vec)
%CHG_AF Changes the Cd and Cl in all the given airfoils
%   Input: 
%       readfile_ID: a cell containing cells: in each cell -
%   {   {airfoil.name, erosion_region}, ...}
%       writefile_ID: a cell containing all the airfoil save locations in
%       order
%       input: the erosion levels for the given blade
%   Outfile:
%       status: message about success
    for i = 1:numel(readfile_ID)
        data = gather_up(readfile_ID{i}{1});
        % Edit the 55 line to the end:
        columns = [3,4];
        for j = 55:numel(data)
            txt = split(data(j));
            if numel(txt) == 1
                break
            end
            txt1 = "   " + txt{2} + "   ";
            txt2 = "   " + txt{5};
            form_vector1 = [txt1,"Cl",...
                    "   ","Cd",txt2];
            formats = {form_vector1,[0,1,0,1,0]};
            Cl_factor = 1 - .53*bladex_vec(readfile_ID{i}{2});% erosion def
            Cd_factor = 1 + 4*bladex_vec(readfile_ID{i}{2});% erosion def
            edit_type = {{"multiply",Cl_factor},{"multiply",Cd_factor}};
            data{j} = editor(formats , columns, edit_type, data{j},0);
        end
        check = lay_down(data, writefile_ID{i});
    end
    status = "Successful air foils update";
end
