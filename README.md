# 2017_2016_Auke_qPCR

salmon_datamining.r   #  this is to extract data from the excel files. 

salmon_inla_clean.Rmd  # this runs the inla model on the full sockeye dataset

salmon_predict.Rmd  # this removes every other day from the time series and runs inla on the dataset (either by using inla's own interpolation method or by interpolating the missing values and running inla on the newly interpolated dataset).  the idea here is to simulate sampling eDNA every other day, not every day.
