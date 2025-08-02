function status = resultfunc(ExperimentID,TestID,trans,i,DT)
%RESULTFUNC Save results of each simulation
%   This will convert the .out file to a data table, and save summary
%   statistics according to functions that we include here.

% Make big table
test_out = ExperimentID + "/" + TestID + "/" + TestID + ".out";
[test1outs,stat1] = create_mat_files(test_out);

 % Now make the summary files
SumID = ExperimentID + "/" + TestID + "/" +"Sensor_Data";
tablename = "SensorDataT.txt";
[status,len] = create_sum_table(SumID,tablename,trans,DT);
disp("Simulation "+num2str(i)+" summary is done.")

status = "Data Tables constructed.";
end

