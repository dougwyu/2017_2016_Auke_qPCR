# 2017_2016_Auke_qPCR

salmon_datamining.r   #  this is to extract data from the excel files. 

salmon_inla_clean.Rmd  # this runs the inla model on the full sockeye dataset

salmon_predict.Rmd  # this removes every other day from the time series and runs inla on the dataset (either by using inla's own interpolation method or by interpolating the missing values and running inla on the newly interpolated dataset).  the idea here is to simulate sampling eDNA every other day, not every day.


background information from Yuanheng (slightly edited):

"The main r-script is 'salmon_inla_clean.Rmd'. 

The file, 'source_salmon.r' is needed for running some functions in the main script. 

The file 'salmon_dataming.r' is the file for generating the two dataset files, 'sockeye_adults_narm_B.csv' and 'sockeye_adults_nazero_B.csv'. So as you can see from the file names, i only use the data from sample B here. The main script here uses the data file 'sockeye_adults_narm_B.csv', as i discussed with Chris that he agrees with you that all NAs of qPCR should be removed. But while I was in Kunming, Yahan has the opinion to treat these NAs as zero. That's why I generate the file 'sockeye_adults_nazero_B.csv' and the plots that I sent to you couple of weeks ago are results of this file.

The major reason to have such nice fit is time-autoregression. That's also why I don't send you the r-script that I'm implemented using MCMC as I haven't figured out how to write functions for autoregression there. In the main r-script, I modeled a model without time-autoregression, 'm.pnt.rela'. ""
