function status = chg_pitch(readfile_ID,writefile_ID,bldPitch,rts)
    %CHG_PITCH Changes the blade pitch (note, that the blade pitch controller
    %is OFF)

    data = gather_up(readfile_ID);
    % Edit the 28 - 29 - 30 lines
    form_vector1 = ["          ","entry_one",...
        "   BlPitch(1)  - Blade 1 initial pitch (degrees)"];
    form_vector2 = ["          ","entry_one",...
        "   BlPitch(2)  - Blade 2 initial pitch (degrees)"];
    form_vector3 = ["          ","entry_one",...
        "   BlPitch(3)  - Blade 3 initial pitch (degrees)"];
    formats = {form_vector1,[0,1,0]};
    columns = [1];
    edit_type = {{"replace",bldPitch}};
    data{28} = editor(formats, columns, edit_type, data{28},0);
    formats = {form_vector2,[0,1,0]};
    data{29} = editor(formats, columns, edit_type, data{29},0);
    formats = {form_vector3,[0,1,0]};
    data{30} = editor(formats, columns, edit_type, data{30},0);

    form_vector = ["          ","entry_one",...
        "   RotSpeed  - Initial or fixed rotor speed (rpm)"];
    formats = {form_vector,[0,1,0]};
    columns = [1];
    
    edit_type = {{"replace",rts}};
    data{33} = editor(formats,columns,edit_type,data{33},0);

    check = lay_down(data, writefile_ID);
    status = "Successful blade-pitch update";
end

