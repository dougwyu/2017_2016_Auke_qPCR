# 2017_2016_Auke_qPCR

sockeye_datamining.r   #  this is to extract data from the excel files. 

sockeye_inla_clean.Rmd  # this runs the inla model on the full sockeye dataset

sockeye_predict.Rmd  # this removes every other day from the time series and runs inla on the dataset (either by using inla's own interpolation method or by interpolating the missing values and running inla on the newly interpolated dataset).  the idea here is to simulate sampling eDNA every other day, not every day.


Next step (as of 12 April 2018) is to run inla on the coho dataset and then to see how well or badly the sockeye and coho datasets work on the other species. Ideally, we would have two years of eDNA & count data for each species, but we don't have that.  


background information from Yuanheng (slightly edited):

"The main r-script is 'sockeye_inla_clean.Rmd'. 

The file, 'sockeye_salmon.r' is needed for running some functions in the main script. 

The file 'sockeye_dataming.r' is the file for generating the two dataset files, 'sockeye_adults_narm_B.csv' and 'sockeye_adults_nazero_B.csv'. So as you can see from the file names, i only use the data from sample B here. The main script here uses the data file 'sockeye_adults_narm_B.csv', as i discussed with Chris that he agrees with you that all NAs of qPCR should be removed. But while I was in Kunming, Yahan has the opinion to treat these NAs as zero. That's why I generate the file 'sockeye_adults_nazero_B.csv' and the plots that I sent to you couple of weeks ago are results of this file.

The major reason to have such nice fit is time-autoregression. That's also why I don't send you the r-script that I'm implemented using MCMC as I haven't figured out how to write functions for autoregression there. In the main r-script, I modeled a model without time-autoregression, 'm.pnt.rela'. ""
