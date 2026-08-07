# README
Contained in this repository are the (1) files and (2) data for the article "Classification of Leading Edge Erosion Severity via Machine Learning Surrogate Models" by Aidan Gettemy, Susan Minkoff, John Zweck, and Elaine Spiller. The input and driver files can be adapted for general OpenFAST experiments using MATLAB to read, write, and run .fst files.   

# Scripts and data
In the main folder, scripts are titled *Inputs, *Driver, *PlotData, *AnalysisFeatures. The first type of script assembles a table to run a batch of experiments. The next script runs the experiment itself, generating a file to keep track of the progress. The final two types of scripts plot the data from an experiment or do other post-processing and visualization tasks. The majority of the studies can be performed within MATLAB. 

Only the Global sensitivity analysis (Section 2.3 and 4.1) requires Python. 

# Paper Experiments 
In the article, Table 5 in Section 3 includes 5 main experiments. The data to reproduce those results are shared here, as well as the code for analysis and figure reproduction.

In order to run the scripts, a version of the OpenFAST driver must be placed in the main folder. The current projects developed by NREL as part of the OpenFAST software package can be found [here](https://github.com/openfast). A version of the driver code must be placed in the main folder. The reference wind turbine can be found [here](https://github.com/OpenFAST/r-test/tree/main/glue-codes/openfast). A version of the ROBUSTGASP code for Matlab needs to be placed in the PPGP_ROM folder, this can be found at [RobustGasp](https://github.com/mengyanggu/robustgasp-in-matlab). Also, a version of zGP is required in the same folder. The version included in this script is simply a slightly modified version of the one found at [zGP](https://github.com/SideofMan/zGP)[^1]. Finally, Reference Wind Turbine files (such as NREL5MW RWT) are found [here](https://github.com/OpenFAST/r-test/tree/main/glue-codes/openfast).

## Reproducing results from the paper
1. Experiment 1: Global sensitivity analysis (Morris Method analysis).
    - Run code: For Morris Method, run `ElementaryEffects_Analysis.ipynb` to generate **Morris_Inputs.txt** (in **Data/Exp1**)
    - Run code: `Exp1Inputs.m` (runs 3 different erosion profiles, only the 1st is studied here)
    - Run code: `Exp1Driver.m`, which will create the simulator result table found in **Data/Exp1/LARGE2ExperimentResultTable1.txt**. Results found in Table2 and Table3 are not used. Use **Data/Exp1/LARGE2ExperimentResultTable1.txt** as input to `ElementaryEffects_Analysis.ipynb` to generate the **MorrisResultsAnalysisTable1.parquet**. `Exp1ReportResults.m` requires **MorrisResultsAnalysisTable1.parquet**.
    - Run code: `Exp1ReportResults.m` to generate Figure #3. `Exp1PlotData.m` and `Exp1AnalysisFeatures.m` are optional, but useful to explore the data.
3. Experiment 2: Classifier feature selection datasets (1 and 2)
4. Experiment 3: Emulator Training dataset
5. Experiment 4: Emulator Generated datasets
6. Experiment 5: Classifier testing datasets (1 and 2)
7. Primary wind turbine erosion experiment. `Exp2Inputs.m`, `Exp2Driver.m`, `Exp2PlotData.m`, `Exp2AnalysisFeatures.m`. Dataset found in **Data/Exp2/LARGE2ExperimentResultTable500.txt**.
8. Experiment 3: PPzGP training. `Exp3Inputs.m`, `Exp3Driver.m`, `Exp3PlotData.m`, `Exp3AnalysisFeatures.m`. Dataset found in **Data/Exp3/LARGE2ExperimentResultsTable1_210.txt**.

## Reproducing figures
- Figure #1: Run **New_Plot_Function.m**.
- Figure #2: (Microsoft Power-Point, not included)
- Figure #3:
- Figure #4:
- Figure #5:
- Figure #6:
- Figure #7:
- Figure #8:
- Figure #9:
- Figure #10:
- Figure #11:
- Figure #12: 
To bypass data generation and recreate Figure #3 in the paper, run `Exp1ReportResults.m`.

## Machine Learning
To bypass data generation and recreate Figure #4 in the paper, run `RandomForest/FeatureSelection.m` up to line 132.

To bypass data generation and recreate Figures #5 and #6 in the paper, run `PPGP_ROM/PPGP_Train_Test.m' from line 166. To explore GP fitting, uncomment lines 9 - 165. 

To bypass data generation and recreate Figure #7 and #8 in the paper, run 'RandomForest/kfold_fitcensemble.m'.

Note, the inputs for the GP to create the emulator training dataset are found in **Exp4_inTable.txt**. The resulting emulator training dataset is found in **EmulationDataset.txt**.

# Template for OpenFAST Experimentation
Below is a description of the template for automating the set-up of OpenFAST experiments in MATLAB. 

This library provides a template for managing experiments with the OpenFAST [OpenFAST](https://github.com/OpenFAST/openfast?tab=readme-ov-file) simulation tool using MATLAB.  This code is a general template, fit to be modified for many different experiments.

# Description:
This library/framework sets up experiments with OpenFAST by changing the input files in the appropriately.  With a large number of inputs, selecting only those pertinent to a particular study is difficult.  This library is a flexible approach for running experiments.  It separates the structuring of the experimental design and the analysis of the results from the editing of the input files.  It is modular, using helper functions which can be adapted to handle different input file types, enabling this framework to apply to different turbine setups and experiment designs.

The core of the library are two files.
- `ExpTableGenerator.m`
- `ExpDriver.m`

Once the user has configured these files (and the helper functions), running the experiment and organizing the results for further analysis is simple.  Simply run the `ExpTableGenerator.m` then run the `ExpDriver.m`.

This framework streamlines OpenFAST input-output handling and keeps the data organized.  The user specifies an experiment to run by giving the input variables and settings for each test in the experiment as a matrix/table (each row is a different test, each column a different input).  Then the framework will set up and run the simulations required, organizing the outputs channels (dependent variables) requested by the user into a table that mirrors the input table provided.  In the end, the code generates a data-folder and a table of outputs from the experiment, in the same row-order as the input table.  Within the data-folder, small test-specific folders hold the summary files, time series data, and statistics for each test.

# Instructions:

Note: The scripts in this folder require:
- MatLab (with Statistics and Machine Learning Toolkit)
- Jupyter notebook (SAlib, Numpy, and Pandas)
- RobustGasp for MatLab ([here](https://github.com/mengyanggu/robustgasp-in-matlab))
- OpenFAST excecutable (adjust the path in the `testdriver.m` file)
- OpenFAST controller conpiled in the correct directory ([here](https://github.com/OpenFAST/nrel-5mw-controllers))

## Step by Step

### Step One: Table Generator 

The `ExpTableGenerator.m` file uses the selected OpenFAST inputs given to make an InputTable for each experiment.  The resulting table is saved as a text file and will be read by the `ExpDriver.m` script.  Each column represents an independent variable.  Each test is a row of the table at a unique configuration of the inputs.  Taken together, all of the rows of the table will help to answer some question about wind turbine engineering.  Follow the comments within the table generator file in order to see where to make changes.

- Line 5: Determines the name of the experiment (must match the name given in `ExpDriver.m`)
- Line 16: The *invarNames* refer to the independent variables required settings in the experiment.  Some of them may simply be a part of the experimental set-up and not variables at all.  In the given example, `windfileID` is the name of the wind file to simulate on, and will not be included in analysis.  In future experiments, multiple wind files may be specified.
- Line 22: If wanted, the user can read in design points from another source and then do additional formating/manipulation in this file.
- Line 25: Determine the number of tests to be run.
- Line 27: This is the number of inputs (it could also be the number of independent variables).
- Line 46: We save the table to a text file.

### Step Two: How to Run a Simulation

The `ExpDriver.m` file takes the input table from `ExpTableGenerator.m` to set up and run OpenFAST tests.  The results will be found in a newly created Data folder in a sub-folder with the name given by the test's name.

- Line 8: This line sets the experiment name.  It must match the experiment name specified in line 5 of `ExpTableGenerator.m`.
- Line 10: This file name must match the template files for the desired OpenFAST experiment configuration (in this example the IEA-15-240-RWT-Monopile).
- Line 12: Set which row of the input table to start with and which row of the input table to stop after.  This allows for the same input table to be run in parallel on several CPUs at once.  (Though this would require additional post-processing to combine the results together at the end).
- Line 14: Set the number of seconds for each test.
- Line 16: Set the number of seconds from the end to start calculating things like mean, standard deviation, etc.
- Line 18: Set the test time step.
- Line 20: If true, then the `.out` file will be deleted to save memory.
- Line 22: If true, then the big result table (a copy of the time-series of each requested channel found in the `.out` file but as a text table) is deleted.
- Line 46: This is where the set-up begins, and where the OpenFAST executable is called.
- Line 50: Note, when running, this code generates a file that can be used to quickly access the contents of the experiment data subfolders.  This is helpful when performing quality checks or looking at results of individual runs.  It is also how this script creates the result folders and tables.
- Line 80: After the result tables for each test are made, then a list of output variables to be calculated is sent to the 'combineResults.m' function, which is found in the 'funcs' folder.  In this example, these are just names, but one could set these up as key words to automatically call different helper functions to explore different types of output analysis.
- Line 87: This line moves the statusFile to the experiment subfolder.

Now we can go in depth on some of the key helper functions to explain how they work and how they can be modified.

### Step Three: Set-Up Function

In the next steps, all of the named functions are found in the `funcs` folder.

The `setup.m` function updates the OpenFAST files according to the experiment.  Each row of the input table is extracted and taken as in input to the `setup.m` function.  This function also takes as an input a small set of auxiliary variables.  In this example, those are the file location of the template folder, the current test number, the duration of each test (in seconds), the time step (in seconds), the id for status file, the test number, and the name of the experiment.  This can be changed according to needs.  

This file has three main sections.  In the first section, a series of helper functions are called to set up various module input files and simulation parameters.  In the second section, the output channels are formated according to an included `OutputChannels.txt` file.  Finally, in the third section, the simulation is run through the `testdriver.m` function and the results are moved to the storage folder.  Meanwhile, a status file keeps track of the tests that have been run, and will serve as a tool for indexing the saved tests in the rest of the `ExpDriver.m` script.

### Step Four: Anatomy of a Helper Function 

The `setup.m` script is called first.

Each of these helper functions is similar and has the job of modifying one type of file for the simulation.  There is one file not needed for simulation, but should be changed and saved for each test; the README file is designed to document the inputs for a given test.  This file is modified and saved along with the results of the simulation in the test-specific data subfolder at the end of the experiment.  In this way, there is a unique README for each test.  This file can be found in the template directory.  The `make_readme.m` function can be modified to name tests according to any convention.  One obvious convention is to name tests based on the value of the independent variables for that specific test.

The anatomy of a helper function is simple.  It takes as its input some portion of the current test row, and the location of the template file to be read in and the location of the resulting file to be saved to.

As demonstrated above, the helper functions make use of a few basic functions.  These are:
- `gather_up.m`: takes a fileID and returns a cell of all of its lines.
- `lay_down.m`: take a cell made up of file lines and saves a text file to a specific location.
- `editor.m`: this function is the very center of the text-editing scheme that is the true objective of this entire library.  Everything about this library is directed to set up this function to change the text to enable different test settings.

### Step Five: Output Channel Control

This is the second section of the `setup.m` function.

This is run through `outputfunc.m`.  This function allows us to modify the output channels that we want to look at.  For this to work, the output sections at the end of each of the OpenFAST files for the different included modules in the Template folder must be deleted and moved to the output channel file with the particular set-up as seen in `OutputChannels.txt`.  If this recipe isn't followed (that is the 1001 included to delieanted between each section) then the code fails.  When this script runs, it appends each of these sections to the proper files in the simulate folder.  Adding and deleting channels is done on the `OutputChannels.txt` file.  The inputs to this function are the first part of the file ID for the simulate folder.  The cell of file ids is needed to correctly access each module file.  We need to know the location of the Output.txt file.  And last, we need to know the line where the output section begins for each module file.  

### Step Six: Setting up the Driver

This is the part of the `setup.m` function where the simulation actually takes place.  In the `testdriver.m` file, line 8 needs to point to the OpenFAST executable that you use.  Line 11 must point to the correct folder for where the .fst file will be.  Note, for different tests, the `move_clean.m` function might need to be adjusted so that it moves the required output files to the data folder for each test.  

Returning to the `setup.m` function, everything else deals with filling in the statusFile as the experiment progresses.  This file has many purposes.  It can be used to restart the experiment if a simulation crashed.  It can be used to index into the data folders conveniently.  It is needed for the data-table construction process.  If this framework is followed, the user does not need to change any lines after line 68.


### Step Seven: Setting up the Parameters of the Result Table

Back in the `ExpDriver.m` script, there are two more functions to address.  First, in line 58 we call the `resultfunc.m` helper function.  Since this function is called in a loop over the lines of the statusFile, that means we are accessing files that have been moved to the data folder.  The `resultsfunc.m` function calls two basic functions.  The first, `create_mat_files.m`, will make a table version of the `.out` file and will save the names of all of the outputs, as well as their units into a `.mat` file (cell).  The second, `create_sum_table.m` is more complicated.  This makes a table, where each row is given the name of one of the output channels.  Each column is some sort of statistic derived from the time series.  In this example, those statics are the mean and the standard deviation.  Note that additional attributes could be calculated (like frequencies), and, additional functions could be written to generate other types of time-series features.  If more features are added, line 30 will need to be modified, as well.  Note that all of these features need to be included in line 80 of the `ExpDriver.m` script.

Finally, when setting up the `combineResults.m` function, which is called in line 81 of `ExpDriver.m`, as long as the variable list corresponds with the features calculated in the `create_sum_table.m` function, then no lines need to be changed.  The resulting table will have both the input table, and the output feature value for each output channel/feature combination.  Each row of this table is a different test.  This is table is a convenient way of doing analysis on the experiment, or doing machine learning tasks, like training a Regression or classification algorithm.

Note, a few of the functions included in the `funcs` folder are not described thus far.  These are the plotting functions.
- `plot_ts.m`: This requires the variable names (as formattedd in the data-folders), and a table of time series data.
- `plot_multi.m`: Requires inputs, the table of time series data, the names (as formatted in the data-folders), and a table that gives what outputs to be plotted each other.

Additional functions should be written as needed, especially when seeking to expand the input available to be changed.  This might require some creativity for efficient indexing and modifying, but the existing functions are good blueprints.  The most common type of addaptation is in helper functions that set up the various module files.  The changes needed to adapt the summary tables are very slight.

Note, in this repository, only the processed files are saved, raw time-series data should be generated locally. 

Now we have gone through what each file does.  Hopefully this is clear enough to run and recreate the results of this experiment, and to adapt this framework for one's own experimental needs.

### Process for Running a new Experiment

- Run `ExpTableGenerator.m` to generate a table of inputs for each test.
- Run `ExpDriver.m` to set up the `Simulate` folder and run OpenFAST on each test, gathering up the results from all the tests into a data table, before moving the data table and the `StatusFile.txt` to the experiment folder within the `Data` folder.

Now the experiment is finished, and the results are organized for analysis.

The authors of this script are grateful to Todd Griffith for the initial suggestion for the project and guidance in wind turbine engineering and Ipsita Mishra for her discussions and introductions to wind turbine modeling and OpenFAST software and development. 

[^1]: Seidman, J.: SideofMan/zGP: zGP in R v1.0.0, https://doi.org/10.5281/zenodo.17956672, 2025.
