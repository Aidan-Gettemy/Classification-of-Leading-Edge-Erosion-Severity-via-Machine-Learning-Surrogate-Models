function status = chg_wnd(readfile_ID,writefile_ID,input,testdur)
    %CHG_WND Changes the wind directio, wind speed, shear
    
    data = gather_up(readfile_ID);
    % Edit the 5th and 6th lines
    form_vector1 = ["0.000	 ","windspeed","   ","winddirection",...
        "	 0.000	 0.000	 ","windshear","	 0.000	 0.000	"];
    form_vector2 = ["testdur","	 ","windspeed","   ","winddirection",...
        "	 0.000	 0.000	 ","windshear","	 0.000	 0.000"];
    formats = {form_vector1,[0,1,0,1,0,1,0]};
    columns = [2,3,6];
    edit_type1 = {{"replace",input(2)},{"replace",input(1)},{"replace",input(3)}};
    data{5} = editor(formats, columns, edit_type1, data{5},0);
    columns = [1,2,3,6];
    edit_type2 = {{"replace",testdur},{"replace",input(2)},{"replace",input(1)},{"replace",input(3)}};
    formats = {form_vector2,[1,0,1,0,1,0,1,0]};
    data{6} = editor(formats, columns, edit_type2, data{6},0);

    check = lay_down(data, writefile_ID);
    status = "Successful wind update";
end

