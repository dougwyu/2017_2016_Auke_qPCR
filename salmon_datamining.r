# Salmon Project datamining

# modified from D. Yu
# Y. Li, last modified Apr 02 2018

#....................................................................#
rm(list=ls())
lapply(c('tidyverse','zoo','cowplot','nlme','MuMIn','readxl','INLA','sp','geoR','lubridate'),library,character.only=T)
	
setwd("/home/yuanheng/Documents/Project_salmon/R/")
	

# ... read in data ..................
ddname = "data/AukeCreek_Sockeye_2016_qPCRVsCount_20170802.2.xlsx"
dd.qpcr = read_excel(ddname, "Ct_Sockeye_2016_work", col_names=T, col_types = c("date","numeric","text","text","text","numeric","text","text","text","numeric","numeric","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip"), na='NA', n_max=822)
dd.env = read_excel(ddname, "Summary", col_names=T, col_types=c("skip","skip","skip","skip","skip","date","numeric","numeric","numeric","numeric","numeric","date","numeric","numeric","numeric","numeric","skip","skip","skip","skip"), na='NA',n_max=170)
	

# .... discard NAs ......
	# comment-out lines demonstrate how to treat NAs of qPCR as zero 
dd.qpcr.removed = dd.qpcr %>% filter(CT!='NA')				# remove NA qPCR
#CTall=replace(dd.qpcr$CT,is.na(dd.qpcr$CT), 0)
#Qty_ng_per_ul.all = replace(dd.qpcr$Qty_ng_per_ul, is.na(dd.qpcr$Qty_ng_per_ul), 0)
#dd.qpcr.NAzero = cbind(dd.qpcr, CTall)
	
dd.qpcr.sum.rm <- dd.qpcr.removed %>% group_by(SampleID) %>% summarise(Date = first(Date), Plate_ID = first(Plate_ID), SampleNumber = first(SampleNumber), SampleReplicate = first(SampleReplicate), updownstream = first(updownstream), CT_mean = mean(CT, na.rm=TRUE), CT_sd = sd(CT, na.rm=TRUE), Qty_ng_per_ul_mean = mean(Qty_ng_per_ul, na.rm=TRUE), Qty_ng_per_ul_sd = sd(Qty_ng_per_ul, na.rm=TRUE), n_qpcrs = sum(!is.na(CT))) %>% arrange(Date)
	
#dd.qpcr.sum.all <- dd.qpcr.NAzero %>% group_by(SampleID) %>% summarise(Date = first(Date), Plate_ID = first(Plate_ID), SampleNumber = first(SampleNumber), SampleReplicate = first(SampleReplicate), updownstream = first(updownstream), CT_mean.all = mean(CTall, na.rm=F), CT_sd.all = sd(CTall, na.rm=F), Qty_ng_per_ul_mean.all = mean(Qty_ng_per_ul.all, na.rm=F), Qty_ng_per_ul_sd.all = sd(Qty_ng_per_ul.all, na.rm=F), n_qpcrs.all = sum(!is.na(CTall))) %>% arrange(Date)
	
dd.qpcr.env.rm = left_join(dd.qpcr.sum.rm, dd.env, by = "Date")
	
dd.qpcr.env.rm <- dd.qpcr.env.rm %>% mutate(Q_corr_qpcr.rm = Qty_ng_per_ul_mean*(Q_cfs/max(Q_cfs)))
dd.qpcr.env.rm <- dd.qpcr.env.rm %>% mutate(G_corr_qpcr.rm = Qty_ng_per_ul_mean*(Gage_Height/max(Gage_Height)))
	
dd.qpcr.env.adults.rm = dd.qpcr.env.rm %>% filter(updownstream == 'upstream')
	
dd.qpcr.env.adults.rm_B <- dd.qpcr.env.adults.rm %>% filter(SampleReplicate == "B")
	
write.table(dd.qpcr.env.adults.rm_B, file='data/sockeye_adults_narm_B.csv',sep=',',row.names=F)
