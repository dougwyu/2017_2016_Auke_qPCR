# Salmon Project datamining

# modified from D. Yu
# Y. Li, last modified Apr 17 2018

#....................................................................#
rm(list=ls())
lapply(c('tidyverse','zoo','cowplot','nlme','MuMIn','readxl','INLA','sp','geoR','lubridate'),library,character.only=T)
	
setwd("/home/yuanheng/Documents/Project_salmon/R/")
	

# ... read in data ..................
ddname = "data/2016_AukeCoho_qPCR_20171024.xlsx"
	
options(digits=15) 
	
dd.qpcr = read_excel(ddname, "Sheet1", col_names=T, col_types = c("skip","text","date","text","text","skip","skip","numeric","numeric","numeric","numeric","numeric","numeric", "skip","skip","skip","skip","skip","skip","skip","skip","skip"), n_max=366, na=c("","NA","Undetermined"))	#
colnames(dd.qpcr)[c(1:3,5:7,9:10)] = c('Sample.Name','Coll.Date','Target.Name', 'CT','CT.Mean','CT.SD', 'Quantity.Mean','Quantity.SD')
str(dd.qpcr)
	
dd.env = read_excel(ddname, "Sheet1", col_names=T, col_types=c("skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip","skip", "date","numeric","numeric","numeric","numeric","numeric"), n_max=132)
colnames(dd.env)[2:5] = c('Coho.M','Coho.F','Coho.Jack','Coho.Juv')
a=replace(dd.env[,2:5], is.na(dd.env[,2:5]), 0)		# treat empty cell as zero
dd.env[,2:5] = a
	
# .......................... Coho Data ..................................................
summary(dd.qpcr$CT)
which(is.na(dd.qpcr$CT))
which(is.na(dd.qpcr$Quantity.SD))
	
dd.qpcr.process = dd.qpcr %>% dplyr::filter(CT!='NA') 
# 'CT' == 'NA' -> 'Undetermined', so delete
str(dd.qpcr.process)
	
dd.qpcr.process.part = plyr::ddply(dd.qpcr.process, ~Sample.Name, summarise, n_qpcrs = sum(!is.na(CT)), CT.sd = sd(CT), CT = mean(CT), Quantity.sd = sd(Quantity), Quantity = mean(Quantity), Coll.Date=first(Coll.Date), Target.Name = first(Target.Name), Task = first(Task))
#  
dd.qpcr.process.part = dd.qpcr.process.part[order(dd.qpcr.process.part$Coll.Date), ]
str(dd.qpcr.process.part)
dd.qpcr.process.part$Sample.Name
	
# use Sample A
dd.qpcr.a = dd.qpcr.process.part[seq(1,dim(dd.qpcr.process.part)[1], by=2),]
dd.qpcr.b = dd.qpcr.process.part[seq(2,dim(dd.qpcr.process.part)[1], by=2),]
	# two samples for 2016-09-01, error? treat second as 09-02?
dd.qpcr.a[22:25, ]
dd.qpcr.a$Coll.Date[24] = as.Date("2016-09-02", format='%Y-%m-%d')
dd.qpcr.a$Coll.Date
	
str(dd.env)
par(mfrow=c(2,1))
plot(dd.env$Date, dd.env$Sum)
plot(dd.qpcr.a$Coll.Date, dd.qpcr.a$Quantity)
	
dd.env$Coll.Date= dd.env$Date
dd.qpcr.env.a = left_join( dd.qpcr.a,dd.env, by = "Coll.Date")
	
for(i in 1:length(dd.qpcr.env.a$Date)){
	dd.qpcr.env.a$sum.adult[i] = sum(dd.qpcr.env.a$Coho.M[i], dd.qpcr.env.a$Coho.F[i])
	dd.qpcr.env.a$sum.2[i] = sum(dd.qpcr.env.a$Coho.M[i], dd.qpcr.env.a$Coho.F[i], dd.qpcr.env.a$Coho.Jack[i])
}
	
write.table(dd.qpcr.env.a[,-7], file="data/coho_a2.csv", row.names=F, sep=',')
	

