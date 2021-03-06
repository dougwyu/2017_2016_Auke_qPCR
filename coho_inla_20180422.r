# Salmon Project
# 
# Y. Li, Apr 16 2018
# last modified Apr 17 2018

# R version -> 3.4.4 (2018-03-15)
# system -> x86_64, linux-gnu

# install.packages("INLA", repos="https://inla.r-inla-download.org/R/stable", dep=TRUE)

#...............................................................#
rm(list=ls())
lapply(c('zoo','cowplot','nlme','MuMIn','readxl','sp','geoR','lubridate','tidyverse','INLA'),library,character.only =T)
	
# setwd("/home/yuanheng/Documents/Project_salmon/R/")
source('source_salmon.r')
	

	
# .................... read in data ......................
dd.qpcr.env.coho = read.table(file='data/coho_a2.csv',sep=',',header=T)
dd.qpcr.env.coho$Date = as.POSIXct(dd.qpcr.env.coho$Date, format='%Y-%m-%d')
#format(as.POSIXct(dd.qpcr.env.adults.rm$Date, format='%Y-%m-%d'),format='%m-%d')
	
#
dd.qpcr.env.coho$txtdate = strptime(as.character(dd.qpcr.env.coho$Date),'%Y-%m-%d')
dd.qpcr.env.coho$txtdate = as.factor(format(dd.qpcr.env.coho$txtdate,'%m-%d'))
	
datex=as.Date(strptime(dd.qpcr.env.coho$txtdate,'%m-%d'))
a = c(0,int_diff(datex)/days(1))
for (i in length(a):1){	a[i]=sum(a[1:i]) }
dd.qpcr.env.coho$date.n = a
a
	
# ... standardize variable
dd.qpcr.env.coho$Quantity.norm = log(dd.qpcr.env.coho$Quantity)
dd.qpcr.env.coho$Quantity.norm2 = MyStd(dd.qpcr.env.coho$Quantity)
	
par(mfrow=c(2,1))
hist(dd.qpcr.env.coho$Quantity.norm, breaks=10)
hist(dd.qpcr.env.coho$Quantity.norm2, breaks=10)
	
# .... cut to regularly spaced time-series ..
a
a[2:61]-a[1:60]
	
dd.qpcr.env.coho = dd.qpcr.env.coho[4:61, ]
dd.qpcr.env.coho$txtdate
hist(dd.qpcr.env.coho$date.n, breaks=50)
	
# .................. explore potential independent variables .............................
names(dd.qpcr.env.coho)
	
MyVar <- c("txtdate", "Quantity.norm", "Quantity.norm2", "Quantity","Sum", "sum.2", "sum.adult")#date.n
	
pairs(dd.qpcr.env.coho[,MyVar])
	
cor(dd.qpcr.env.coho[ , c(MyVar[2:4], "date.n")])
corvif(data.frame(Date=dd.qpcr.env.coho[,18], qPCR=dd.qpcr.env.coho[,6], qPCR.n=dd.qpcr.env.coho[,20]))		#c("Quantity.norm2", "date.n")
# date & qpcr data too similar
	
# ..... descriptive plots ......
# pdf("plots/describe_coho.pdf", width = 15, height = 5)
par(las=1, mfrow = c(1,1), mar = c(2,5,2,.5), oma = c(1,1,1.5,1),cex=1.2)
plot(dd.qpcr.env.coho$Date, dd.qpcr.env.coho$sum.adult, xlab='', ylab='' ,type='l', ylim=c(0, max(dd.qpcr.env.coho$sum.2)))
lines(dd.qpcr.env.coho$Date, dd.qpcr.env.coho$sum.2, col='red')
title(ylab='Individual', outer=T, line=-1.5, cex.lab=1.2)
title(main='Daily Counts', cex.main=1.5)
	
legend('topright', legend = c('adult', paste(expression(adult+jack),sep='')), lty=c(1,1), col=c('black', 'red'), bty='n')
	
# dev.off()
	
# pdf("plots/describe_coho_qpcr.pdf", width = 15, height = 5)
par(las=1, mfrow = c(1,1), mar = c(2,5,2,.5), oma = c(1,1,1.5,1),cex=1.2)
plot(dd.qpcr.env.coho$Date, dd.qpcr.env.coho$Quantity, xlab='', ylab='', type='b', pch=16)
title(ylab='eDNA concentration', outer=T, line=-.8, cex.lab=1.2)
title(main='Daily eDNA', cex.main=1.5)
	
# dev.off()
	
# .......... INLA models ................................
hist(dd.qpcr.env.coho$date.n,breaks=50)
names(dd.qpcr.env.coho)
	
inla.setOption(scale.model.default = TRUE)
U = 0.1			# explore U & sigma values
hyperl=list(theta=list(prior='pc.prec', param=c(U, 0.005)))
	
# ...... zero-inflated Poission & ar1 ......
	# 'ar' - regularly spaced time-series
	# coho.adult+jack
m.par2.rela = inla(sum.2 ~ Quantity.norm2 + f(txtdate, model = 'ar1', hyper=hyperl),
			control.compute = list(dic =T, mlik=T, cpo=T, config=T),
			control.inla=list(int.strategy = "grid", diff.logdens = 4, strategy="laplace", npoints=21),	
			control.predictor = list(compute=T),
			family = 'zeroinflatedpoisson1', 
			data = dd.qpcr.env.coho
		)
	
summary(m.par2.rela)
	
	# coho.adult
m.par1.rela = inla(sum.adult ~ Quantity.norm2 + f(txtdate, model = 'ar1', hyper=hyperl),
			control.compute = list(dic =T, mlik=T, cpo=T, config=T),
			control.inla=list(int.strategy = "grid", diff.logdens = 4, strategy="laplace", npoints=21),	
			control.predictor = list(compute=T),
			family = 'zeroinflatedpoisson1', # 'poisson'
			data = dd.qpcr.env.coho
		)
	
summary(m.par1.rela)
	
# no autoregression
	# adult + jack
m.pnt2.rela = inla(sum.2 ~ Quantity.norm2 ,
			#verbose=T,
			control.compute = list(dic =T, config=T, mlik=T, cpo=T),
			control.inla=list(int.strategy = "grid", diff.logdens = 4, strategy="laplace", npoints=21),	
			control.predictor = list(compute=T),
			#control.family = list(list(prior='lognormal')),		# gamma
			
			family = 'zeroinflatedpoisson1',
			data = dd.qpcr.env.coho
		)
	
summary(m.pnt2.rela)
# DIC-value way too high
	
	# adult
m.pnt1.rela = inla(sum.adult ~ Quantity.norm2 ,
			#verbose=T,
			control.compute = list(dic =T, config=T, mlik=T, cpo=T),
			control.inla=list(int.strategy = "grid", diff.logdens = 4, strategy="laplace", npoints=21),	
			control.predictor = list(compute=T),
			#control.family = list(list(prior='lognormal')),		# gamma
			
			family = 'zeroinflatedpoisson1',#poisson
			data = dd.qpcr.env.coho
		)
	
summary(m.pnt1.rela)
	

# .................... model check .............................  
# (
#	I also tried some other model-checking criteria, but they're either too conservative (meaning all models are good according to these conservative criteria) or I'm not quite sure if I did a correct job implying them. 
#	same applies to PIT criterion, because cpo calculation failed sometimes
#	so I'm relying on the simplest ACF criterion here. 
# )
	# PIT (probability integral transform), a form of cross-validation test 
		# adult + jack & time autoregression
table(m.par2.rela$cpo$failure)	# fail21% 
sum(m.par2.rela$cpo$failure!=0) / length(m.par2.rela$cpo$failure)
	
par(mfrow=c(2,1))
hist(m.par2.rela$cpo$pit, breaks=40)	
# the model has bias (skew) or overdispersed (dome), even though cpo fails at 21%
hist(m.par2.rela$cpo$cpo, breaks=40)	#
	
hist(m.par2.rela$cpo$pit, breaks=25)
mean(m.par2.rela$cpo$pit)
# bias? 
	 
		# adult & time autoregression
table(m.par1.rela$cpo$failure)	# fail29% 
sum(m.par1.rela$cpo$failure!=0) / length(m.par1.rela$cpo$failure)
	
par(mfrow=c(2,1))
hist(m.par1.rela$cpo$pit, breaks=40)	# the model has bias (skew), even though cpo fails at 29%
hist(m.par1.rela$cpo$cpo, breaks=40)	#
	
		# adult + jack, no time
table(m.pnt2.rela$cpo$failure)	# fail0%, all valid 
sum(m.pnt2.rela$cpo$failure!=0) / length(m.pnt2.rela$cpo$failure)
	
par(mfrow=c(2,1))
hist(m.pnt2.rela$cpo$pit, breaks=40)	# the model underdispersed (U-shape)?
hist(m.pnt2.rela$cpo$cpo, breaks=40)	#
	
hist(m.pnt2.rela$cpo$pit, breaks=25)
mean(m.pnt2.rela$cpo$pit)
# bias? underdispersed?
	
		# adult, no time
table(m.pnt1.rela$cpo$failure)	# fail0%, all valid 
sum(m.pnt1.rela$cpo$failure!=0) / length(m.pnt1.rela$cpo$failure)
	
par(mfrow=c(2,1))
hist(m.pnt1.rela$cpo$pit, breaks=40)	# the model underdispersed (U-shape)?
hist(m.pnt1.rela$cpo$cpo, breaks=40)	#
	
hist(m.pnt1.rela$cpo$pit, breaks=25)
mean(m.pnt1.rela$cpo$pit)
# bias?
	
#pdf("plots/coho_PIT_ar-zero.pdf", width = 7, height = 7)
	
#par(las=1, mfrow = c(1,1), mar = c(2,5,2,.5), oma = c(1,1,1,1),cex=1.2)
#hist(m.par2.rela$cpo$pit,breaks=50, main="", cex.lab=1.2)
#title(main='PIT-values, fail32%', cex.main=1.35)
	
#dev.off()
	
	#  acf (auto-correlation function), checking residual correlation
		# adult + jack & time autoregression
resid.count.ar2 = dd.qpcr.env.coho$sum.2 - m.par2.rela$summary.fitted.values$mean
	
# pdf("plots/coho_acf_ar-time-AJ.pdf", width = 7, height = 7)
par(las=1, mfrow = c(1,1), mar = c(4,4,2.5,.5), oma = c(2,1,.5,1),cex=1.2)
acf(resid.count.ar2,type= 'correlation',main='', cex.lab=1.2)#''covariance
title(main='Residual Autocorrelation',cex.main=1.35)
legend('topright', legend = paste(expression(adult+jack&time),sep=''), bty='n')
	
# dev.off()
	
		# adult & time autoregression
resid.count.ar1 = dd.qpcr.env.coho$sum.adult - m.par1.rela$summary.fitted.values$mean
	
# pdf("plots/coho_acf_ar-time-A.pdf", width = 7, height = 7)
par(las=1, mfrow = c(1,1), mar = c(4,4,2.5,.5), oma = c(2,1,.5,1),cex=1.2)
acf(resid.count.ar1,type= 'correlation',main='', cex.lab=1.2)#''covariance
title(main='Residual Autocorrelation',cex.main=1.35)
legend('topright', legend = paste(expression(adult&time),sep=''), bty='n')
	
# dev.off()
	
		# adult + jack, no time
resid.count.nt2 = dd.qpcr.env.coho$sum.2 - m.pnt2.rela$summary.fitted.values$mean
	
# pdf("plots/coho_acf_ar-notime-AJ.pdf", width = 7, height = 7)
par(las=1, mfrow = c(1,1), mar = c(4,4,2.5,.5), oma = c(2,1,.5,1),cex=1.2)
acf(resid.count.nt2,type= 'correlation',main='', cex.lab=1.2)#''covariance
title(main='Residual Autocorrelation',cex.main=1.35)
legend('topright', legend = paste(expression(adult+jack),sep=''), bty='n')
# not great
	
# dev.off()
	
		# adult, no time
resid.count.nt1 = dd.qpcr.env.coho$sum.adult - m.pnt1.rela$summary.fitted.values$mean
	
# pdf("plots/coho_acf_ar-notime-A.pdf", width = 7, height = 7)
par(las=1, mfrow = c(1,1), mar = c(4,4,2.5,.5), oma = c(2,1,.5,1),cex=1.2)
acf(resid.count.nt1,type= 'correlation',main='', cex.lab=1.2)#''covariance
title(main='Residual Autocorrelation',cex.main=1.35)
legend('topright', legend = paste(expression(adult),sep=''), bty='n')
# not great
	
# dev.off()
	
c(m.pnt2.rela$dic$dic, m.par2.rela$dic$dic)
c(m.pnt1.rela$dic$dic, m.par1.rela$dic$dic)
	

	

# .. plot fitted
	# adult + jack & time autoregression
	# According to cov() in the beginning, 'Date' and 'qpcr' are too similar that we shouldn't include them both in the model. But I guess in this model, date serves as autoregression which has way different function than qpcr here ...
# pdf("plots/coho_fitted_ar-time-AJ.pdf", width = 15, height = 5)
par(las=1, mfrow = c(1,1), mar = c(4,4,2,.5), oma = c(1,1,1,1),cex=1.2)
	
plot(dd.qpcr.env.coho$Date, m.par2.rela$summary.fitted.values[,"mean"], type='n', lty=1, pch=4,col='blue', ylim=c(min(m.par2.rela$summary.fitted.values[,3]),max(m.par2.rela$summary.fitted.values[,5])), xlab='', ylab='')	#, 
title(ylab='Individual', outer=T, line=-1.2, cex.lab=1.2)
title(main='Model fit', cex.main=1.5)
	
# CI interval
polygon.x <- c(dd.qpcr.env.coho$Date, rev(dd.qpcr.env.coho$Date))
polygon.y <- c(m.par2.rela$summary.fitted.values$'0.025quant', rev(m.par2.rela$summary.fitted.values$'0.975quant'))
polygon(x=polygon.x, y=polygon.y, col='lightblue', border=NA)
	
lines(dd.qpcr.env.coho$Date, m.par2.rela$summary.fitted.values[,"mean"], lty=1,col='blue')
	
points(dd.qpcr.env.coho$Date, dd.qpcr.env.coho$sum.2, ylab='Total count',xlab='Date',type='p',pch=20, col='#FFA50088', lty=1)	#lwd=3, 
	
legend('topright', legend=c('count', 'fitted', '95% CI'), pch = c(20,NA, NA), col = c('#FFA50088', 'blue', 'lightblue'), lty=c(NA, 1, 1), lwd=c(1,1,10), bty='n', cex=1.2, title= paste(expression(adult+jack&time),sep=''))
	
# dev.off()
	

	# adult & time autoregression
# pdf("plots/coho_fitted_ar-time-A.pdf", width = 15, height = 5)
par(las=1, mfrow = c(1,1), mar = c(4,4,2,.5), oma = c(1,1,1,1),cex=1.2)
	
plot(dd.qpcr.env.coho$Date, m.par1.rela$summary.fitted.values[,"mean"], type='n', lty=1, pch=4,col='blue', ylim=c(min(m.par1.rela$summary.fitted.values[,3]),max(m.par1.rela$summary.fitted.values[,5])), xlab='', ylab='')	#, 
title(ylab='Individual', outer=T, line=-1.2, cex.lab=1.2)
title(main='Model fit', cex.main=1.5)
	
# CI interval
polygon.x <- c(dd.qpcr.env.coho$Date, rev(dd.qpcr.env.coho$Date))
polygon.y <- c(m.par1.rela$summary.fitted.values$'0.025quant', rev(m.par1.rela$summary.fitted.values$'0.975quant'))
polygon(x=polygon.x, y=polygon.y, col='lightblue', border=NA)
	
lines(dd.qpcr.env.coho$Date, m.par1.rela$summary.fitted.values[,"mean"], lty=1,col='blue')
	
points(dd.qpcr.env.coho$Date, dd.qpcr.env.coho$sum.adult, ylab='Total count',xlab='Date',type='p',pch=20, col='#FFA50088', lty=1)	#lwd=3, 
	
legend('topright', legend=c('count', 'fitted', '95% CI'), pch = c(20,NA, NA), col = c('#FFA50088', 'blue', 'lightblue'), lty=c(NA, 1, 1), lwd=c(1,1,10), bty='n', cex=1.2, title= paste(expression(adult&time),sep=''))
	
# dev.off()
	



# ......................... plot model parameters ................................

## ... plot latent
#pdf("plots/time-smoother_ar-zero.pdf", width = 10, height = 7)
#par(las=1, mfrow = c(1,1), mar = c(4,3,2.5,.5), oma = c(1,1,1,1), cex=1.2)
	
#plot(dd.qpcr.env.adults.rm$Date, m.par0.rela$summary.random$txtdate[,2][7:108],type='l', ylab='',xlab='', ylim=c(min(m.par0.rela$summary.random$txtdate[,4]),max(m.par0.rela$summary.random$txtdate[,6])))		#
	
#title(ylab='smoother', outer=T, line=-1.4, cex.lab=1.2)
#title(main='Time Autoregression', cex.main=1.5)
	
#lines(dd.qpcr.env.adults.rm$Date, m.par0.rela$summary.random$txtdate[,4][7:108], lty=2,col='black')
#lines(dd.qpcr.env.adults.rm$Date, m.par0.rela$summary.random$txtdate[,6][7:108], lty=2,col='black')
#abline(h=0,lty=3)
	
#dev.off()
	
## ... posterior distribution
#pdf("plots/posterior_ar-zero.pdf", width = 12, height = 6)
#par(las=1, mfrow = c(1,2), mar = c(4,4,1.5,.5), oma = c(1,1,1,1),cex=1.1)
	
#aa = sd(dd.qpcr.env.adults.rm$Q_corr_qpcr.rm)
#bb = mean(dd.qpcr.env.adults.rm$Q_corr_qpcr.rm)
	
#plot(m.par0.rela$marginals.fixed$"(Intercept)",type='l', xlab='Intercept', ylab='', cex.lab=1.2)
#abline(v = m.par0.rela$summary.fixed['(Intercept)', "0.5quant"], col = "red",lty=3)
#abline(v = m.par0.rela$summary.fixed['(Intercept)', "0.025quant"], col = "red",lty=3)
#abline(v = m.par0.rela$summary.fixed['(Intercept)', "0.975quant"], col = "red",lty=3)
#plot(m.par0.rela$marginals.fixed$"Q_corr_qpcr.rm.norm2"[,1]*aa + bb, m.par0.rela$marginals.fixed$"Q_corr_qpcr.rm.norm2"[,2],type='l', xlab='eDNA concentration', ylab='', cex.lab=1.2)
	
#abline(v = m.par0.rela$summary.fixed['Q_corr_qpcr.rm.norm2', "0.5quant"]*aa + bb, col = "red",lty=3)
#abline(v = m.par0.rela$summary.fixed['Q_corr_qpcr.rm.norm2', "0.025quant"]*aa + bb, col = "red",lty=3)
#abline(v = m.par0.rela$summary.fixed['Q_corr_qpcr.rm.norm2', "0.975quant"]*aa + bb, col = "red",lty=3)
	
#dev.off()
	


















