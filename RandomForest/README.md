## Guidelines

First, each experiment requires selecting predictors on an independent dataset. This is done in `Class_Predictor_Selection.m`. 

Second, the simulator trained classifier results are created using `Simulation_Trained_Classifier_Runner.m`. Or in parallel (see **RandomForest/Parallel_Train_Test**. Similarly, `Emulation_Trained_Classifier_Runner.m` generates the emulation-based results. All of the results used in the paper are saved in this folder, so there is no need to re-run these codes to generate tables and figures. 

Finally, the test results are post-processed using `Run_postprocessing.m`. 
