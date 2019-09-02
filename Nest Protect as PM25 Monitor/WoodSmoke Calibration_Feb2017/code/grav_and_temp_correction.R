library(data.table)
library(lubridate)
library(plyr)
library(ggplot2)
library(prospectr)
library(gridExtra)
# library(doParallel)

# # setup parallel backend
# nodes <- detectCores()
# registerDoParallel(nodes-2)


dt_nest  <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/nestData_unadj.csv' )
dt_nest[,datetime := ymd_hms(datetime)]
dt_nest[,device := as.factor(device)]
dt_nest[,led := as.factor(led)]

dt_dust <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/dusttraks/dusttrakData_unadj.csv' )
dt_dust[,datetime := ymd_hms(datetime)]
dt_dust[,sample_dtX := as.factor(sample_dtX)]
dt_dust[,sample_dtY := as.factor(sample_dtY)]





############
#######	Dust Trak II
############

#### Determine contribution from DT runtime that took place without impactors in place
	# determine amount of time samples ran for on each dust trak
	time_X = as.numeric(difftime(dt_dust[sample_dtX == 'MANUAL_028', datetime][1], dt_dust[sample_dtX == 'MANUAL_028',datetime][nrow(dt_dust[sample_dtX == 'MANUAL_028'])])) * -60
	time_Y = as.numeric(difftime(dt_dust[sample_dtY == 'MANUAL_005', datetime][1], dt_dust[sample_dtY == 'MANUAL_005',datetime][nrow(dt_dust[sample_dtY == 'MANUAL_005'])])) * -60
	# determine total UNCORRECTED mass deposited on each filter during this time in UNCORRECTED µg
		# mg/m3*sec  *   sec/1   * L/1   * m3/L * flow fraction  through filter
	filtload_dtX =  dt_dust[sample_dtX == 'MANUAL_028' ,mean( pm_dtX)] / (time_X * (0.003 * (2/3)) )
	filtload_dtY = dt_dust[sample_dtY == 'MANUAL_005' ,mean( pm_dtY)] / (time_Y * (0.003 * (2/3))  )


####  Grav correction
# mean during sample period
mean_pm_dtX <- dt_dust[ sample_dtX %in% c('MANUAL_028','MANUAL_029'), mean(pm_dtX)]
mean_pm_dtY <- dt_dust[ sample_dtY %in% c('MANUAL_005','MANUAL_006'), mean(pm_dtY)]

# assign filter deposition data
mass_dep_dtX_µg <- 577.5
mass_dep_dtY_µg <- 605.8
dt_flowrate <- 3.0 * (2/3)
L_to_m3_corr  <-  0.001

# mean concentration
gconc_mean_dtX  <- dt_dust[ sample_dtX %in% c('MANUAL_028','MANUAL_029'), mass_dep_dtX_µg / ( (length(datetime) / 60) * (dt_flowrate * L_to_m3_corr) ) ]
gconc_mean_dtY  <- dt_dust[ sample_dtY %in% c('MANUAL_005','MANUAL_006'), mass_dep_dtY_µg / ( (length(datetime) / 60) * (dt_flowrate * L_to_m3_corr) ) ]


# Correction factor - at 3 sig figs
corr_dtX <- round( (mean_pm_dtX*1000) / gconc_mean_dtX , 2)
corr_dtY <-round( (mean_pm_dtY* 1000) / gconc_mean_dtY , 2)


# create uncorrect var and correct original var by grav
dt_dust[, pm_dtX_uncorrected := pm_dtX]
dt_dust[, pm_dtX := pm_dtX / corr_dtX]

dt_dust[, pm_dtY_uncorrected := pm_dtY]
dt_dust[, pm_dtY := pm_dtY / corr_dtY]

# save to disk
write.csv(dt_dust, '~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/dusttraks/dusttrakData_adj.csv' , row.names = FALSE)



# # mean during entire sampling period
# dtx_meanALL <- dt_dust[ datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00'), mean(pm_dtX)]
# dty_meanALL <- dt_dust[ datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00'), mean(pm_dtY)]
# dusttrak_meanALL <- mean(c(dtx_meanALL,dty_meanALL))

# # mean during 70 mg/m3 sampling period
# dtx_mean70 <- dt_dust[ datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00'), mean(pm_dtX)]
# dty_mean70 <- dt_dust[ datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00'), mean(pm_dtY)]
# dusttrak_mean70 <- mean(c(dtx_mean70,dty_mean70))

# # mean during 10 mg/m3 sampling period
# dtx_mean10 <- dt_dust[ datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00'), mean(pm_dtX)]
# dty_mean10 <- dt_dust[ datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00'), mean(pm_dtY)]
# dusttrak_mean10 <- mean(c(dtx_mean10,dty_mean10))

# # mean during 5 mg/m3 sampling period
# dtx_mean5 <- dt_dust[ datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00'), mean(pm_dtX)]
# dty_mean5 <- dt_dust[ datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00'), mean(pm_dtY)]
# dusttrak_mean5 <- mean(c(dtx_mean5,dty_mean5))

# # mean during 0500 mg/m3 sampling period
# dtx_mean0500 <- dt_dust[ datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00'), mean(pm_dtX)]
# dty_mean0500 <- dt_dust[ datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00'), mean(pm_dtY)]
# dusttrak_mean0500 <- mean(c(dtx_mean0500,dty_mean0500))

# # mean during 0100 mg/m3 sampling period
# dtx_mean0100 <- dt_dust[ datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00'), mean(pm_dtX)]
# dty_mean0100 <- dt_dust[ datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00'), mean(pm_dtY)]
# dusttrak_mean0100 <- mean(c(dtx_mean0100,dty_mean0100))

# all non-zero periods
dtx_meanNonzero <- dt_dust[ 
	datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00')    |
	datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00')    |
	datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00')    |
	datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00')    |
	datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00')
	, mean(pm_dtX)]
dty_meanNonzero <- dt_dust[ 
	datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00')    |
	datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00')    |
	datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00')    |
	datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00')    |
	datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00')
	, mean(pm_dtY)]
dusttrak_meanNonzero <- mean(c(dtx_meanNonzero,dty_meanNonzero))






############
#######	Nests
############

## Identify sampling rate of sample taken
## create diff-time variable to isolate 0.5hz and 0.1hz samples
	dt_nest[, diff_sec_next := as.numeric(difftime( datetime , shift(datetime, 1, type = 'lag') ), units = "secs"), by = c('device', 'led')]
	dt_nest[, diff_sec_prior := as.numeric(difftime(shift(datetime, 1, type = 'lead'), datetime ), units = "secs"), by = c('device', 'led')]
	# IR LEDsample rate
	# dt_nest[led == 'ir', count(diff_sec_next)]
	dt_nest[led == 'ir' & diff_sec_next == 10 | led == 'ir' & diff_sec_prior == 10, sample_rate := 0.1]
	dt_nest[led == 'ir' & diff_sec_next == 2 | led == 'ir' & diff_sec_prior == 2, sample_rate := 0.5]

	# Blue LED sample rate
	# dt_nest[led == 'blue', count(diff_sec_next)]
	dt_nest[led == 'blue' & diff_sec_next == 2 | led == 'blue' & diff_sec_prior == 2, sample_rate := 0.5]
	dt_nest[led == 'blue' & diff_sec_next == 190 | led == 'blue' & diff_sec_prior == 190, sample_rate := 0.0053]
	dt_nest[led == 'blue' & diff_sec_next == 200 | led == 'blue' & diff_sec_prior == 200, sample_rate := 0.005]
	dt_nest[led == 'blue' & diff_sec_next == 210 | led == 'blue' & diff_sec_prior == 210, sample_rate := 0.0048]

	#drop temporary vars
	dt_nest[, c('diff_sec_next', 'diff_sec_prior') := NULL]



###
#	Convert bits to Voltage
	# reference voltage used in the hardware setup
	vref = 3.3
	# max capacity of ADC (at 12 bits), accountinng for 0 as lowest value (rather than 1)
	max_bits = (2^12) - 1
	# make conversion
	dt_nest[, volts := round( (bits/max_bits) * vref,  3)]


	# create rolling standard deviation... five point
	# (from -k to k, where k = N/2 ... i.e. k samples pre data point and k samples post data point)
	max_k = 6
	## drop very low values (odd balls likely caused by Linux operating system interference)... drop 5 rows total
	## Create lag/lead columns for lag/lead of 1 through k points
	for (i in 1:max_k){
		# lag columns
		dt_nest[ , paste('lag',i,sep='') := shift( volts ,i, type = 'lag'), by = c('led','device') ]
		# # lead columns
		# dt_nest[ , paste('lead',i,sep='') := shift( volts ,i, type = 'lead'), by = c('led','device')  ]
	}

	## Produce rolling averages and SDs
		# leftwise RA
	ra_colnames_lag = names(dt_nest)[grep('^lag',names(dt_nest))][1:max_k ] 
	# ra_colnames_lag = names(dt_nest)[grep('lag',names(dt_nest))][1:max_k ] 
	# ra_colnames = c(ra_colnames_lag, ra_colnames_lead, prior_j)
	dt_nest[, rnum:=1:nrow(dt_nest)]
	dt_nest[, sd_roll6 := sd(c(lag1,lag2,lag3,lag4,lag5, lag6)), by='rnum']
	dt_nest[, mean_roll6 := mean(c(lag1,lag2,lag3,lag4,lag5, lag6)), by='rnum']
	dt_nest[,rnum := NULL]


## Create variable indicating difference between previous and current value in terms of roll6 SD
dt_nest[, sd_diff := (lag1 - volts)/sd_roll6 ]

# Drop extranneous
dt_nest[, c(ra_colnames_lag) := NULL]

# count number of outliers
dt_nest[sd_diff >= 5 ,length(volts), by = c('device','led')]

# drop where SD_diff > 6 sd
dt_nest <- dt_nest[sd_diff < 5]



############ Temperature  Correction
# use correction factors from 2017 Temperature Calibration
# IR temp correction
	# dt_nest[,volts := as.double(volts)]
	dt_nest[led == 'ir' & device == 'alpha', volts := volts - ( - (5.654e-04 * tempC))]
	dt_nest[led == 'ir' & device == 'beta', volts := volts - ( - (7.113e-04* tempC))]
	dt_nest[led == 'ir' & device == 'epsilon', volts := volts - ( - (4.333e-04 * tempC))]
# blue temp correction -- only applies to 'epsilon', others not significant
	dt_nest[led == 'blue' & device == 'epsilon', volts := volts - ( (5.868e-05 * tempC))]







########### Autocorrelation over time




	# Try Hig pass Butterworth filter, Gaussian moving median filter, Discrete Wavelet filter, Kalman filtering



	# # superlearner association
	# library(SuperLearner)
	# # inputs
	# SL.library <- c("SL.glm", "SL.randomForest", "SL.polymars", "SL.mean",'SL.loess','SL.xgboost','SL.ridge','SL.nnet', 'SL.glmnet','SL.svm')
	# method  <-  "method.NNLS"
	# fit.data.SL <- SuperLearner( Y = dt_nest_z[led == 'ir' & device == 'alpha', volts],
	# 		X = dt_nest_z[led == 'ir' & device == 'alpha', c('time','sys_tempC','posttest')],
	# 		family = gaussian(),
	# 		SL.library = SL.library,
	# 		method = 'method.NNLS'
	# 		 )
	# # prediction and prediction set
	# pred_SL <- predict( fit.data.SL)
	# predset_SL <- data.frame( orig = dt_nest_z[led == 'ir' & device == 'alpha', volts],
	# 			      pred = pred_SL$pred,
	# 			      datetime = dt_nest_z[led == 'ir' & device == 'alpha', datetime])
	# # MSE
	# mean((dt_nest_z[led == 'ir' & device == 'alpha', volts] - fit.data.SL$SL.predict)^2)
	# # plot
	# ggplot(predset_SL) + geom_point(aes(x=datetime, y = pred), colour = 'red') + geom_point(aes(x = datetime, y = orig))





########## Signal smoothing

# ##### Average into longer time frames
# 	# one-minute average IR
# 	dt_nest[, minute := round_date(datetime, unit = "minutes")]
# 	dt_dust[, minute := round_date(datetime, unit = "minutes")]
# 	dt_nest[ , avg_volts := mean(volts), by = c("device","minute", "led")]
# 	dt_dust[ , avg_minute_pm_dtX := mean(pm_dtX), by = "minute"]
# 	dt_dust[ , avg_minute_pm_dtY := mean(pm_dtY), by = "minute"]

# 	dt_avg <- merge(
# 		unique(dt_nest[,c('device','led','minute','avg_volts')]),
# 		unique(dt_dust[,c('minute','avg_minute_pm_dtX','avg_minute_pm_dtY')], by = "minute") 
# 		)
# 	dt_avg <- rename(dt_avg, c("minute"="datetime", "avg_volts"="volts","avg_minute_pm_dtX" = "pm_dtX", "avg_minute_pm_dtY"="pm_dtY") )
# 	dt_avg[,datetime := ymd_hms(datetime)]

# 	# ggplot(dt_avg[pm_dtX < 1], aes(y = volts, x =pm_dtX, colour = device )) + geom_point()


# 	# 30 minute average Blue 
# 	dt_nest[, minute30 := round_date(datetime, unit = "30 minutes")]
# 	dt_dust[, minute30 := round_date(datetime, unit = "30 minutes")]
# 	dt_nest[led == "blue", avg_volts := mean(volts), by = c("device","minute30")]
# 	dt_dust[ , avg_minute30_pm_dtX := mean(pm_dtX), by = "minute30"]
# 	dt_dust[ , avg_minute30_pm_dtY := mean(pm_dtY), by = "minute30"]

# 	dt_avg_30 <- merge(
# 		unique(dt_nest[led == 'ir',c('device','led','minute30','avg_volts')]),
# 		unique(dt_dust[,c('minute30','avg_minute30_pm_dtX','avg_minute30_pm_dtY')], by = "minute30") 
# 		)

# 	# ggplot(dt_avg_30, aes(y = avg_volts, x =avg_minute30_pm_dtX, colour = device)) + geom_point()



# 	# ######
# 	# # Toggle Use of minute-avg   -- note, this alters Fourier Transform filter
# 	# ######
# 	# dt_nest <- unique(dt_avg[,c("datetime","device","led","volts")])
# 	# dt_dust <- unique(dt_avg[,c("datetime","pm_dtX","pm_dtY")])



# ##### Rolling Average  -- Single, Double, and Triple
# # (from -k to k, where k = N/2 ... i.e. k samples pre data point and k samples post data point)
# max_k = 6
# rolling_ave_sizes = c(3,7,13)


# 	# for single, double, triple rolling averages 
# 	for ( j in c('single','double','triple') ){


# 		for (p in rolling_ave_sizes){

# 			dt_nest[, paste('ranaught_',p,sep='') := volts]

# 			if (j == 'single'){prior_j  = paste('ranaught_',p,sep='')}
# 			if (j == 'double'){prior_j  = paste('rasingle_',p,sep='')}
# 			if (j == 'triple'){prior_j  = paste('radouble_',p,sep='')}

# 			## Create lag/lead columns for lag/lead of 1 through k points, device and LED type 
# 			for (i in 1:max_k){
# 				# lag columns
# 				dt_nest[ ,  paste('lag',j,"_",i,sep='') := shift( get(prior_j) ,i, type = 'lag'), by = c('led','device') ]
# 				# lead columns
# 				dt_nest[ , paste('lead',j,"_",i,sep='') := shift( get(prior_j) ,i, type = 'lead') , by = c('led','device') ]
# 			}
			
# 			## Produce rolling averages
# 			k = (p-1)/2
# 				# centered RA
# 			ra_colnames_lag = names(dt_nest)[grep(paste('lag',j, sep = ''),names(dt_nest))][1:k ] 
# 			ra_colnames_lead = names(dt_nest)[grep(paste('lead',j, sep = ''),names(dt_nest))][1:k ] 
# 			ra_colnames = c(ra_colnames_lag, ra_colnames_lead, prior_j)
			
# 			dt_nest[, paste('ra',j,'_',p,sep='') := rowSums(dt_nest[, ra_colnames , with=FALSE]) / p]		
# 		}
	
# 		# drop lag/lead columns -- used only to make the rolling averages
# 		names_laglead <- c(
# 			names(dt_nest)[ grep('lag',names(dt_nest))],
# 			names(dt_nest)[ grep('lead',names(dt_nest))],
# 			names(dt_nest)[ grep('naught',names(dt_nest))]   )
# 		dt_nest[, (names_laglead) := NULL]
# 	}



# ##### Savitzky-Golay filter (Anal. Chem. 1964); local least-squares polynomial approximation

# 	# IR
# 	p= 3      # polynomial order
# 	w = 21   # filter window size,  must be odd
# 	m = 0    # differentiation order
# 	# blue
# 	p_b = 1; w_b =3; m_b = 0

# 	golay.fxn <- function(x){
# 		# IR
# 		sg <- savitzkyGolay(dt_nest[led == 'ir' & device == x ,volts], p = p, w = w, m = m)
# 		sg <- c(rep('NA', (w-1)/2 ), sg, rep('NA', (w-1)/2) )
# 		dt_nest[led == 'ir' & device == x,sg_volts := as.numeric(sg)]	

# 		# blue
# 		sg <- savitzkyGolay(dt_nest[led == 'blue' & device == x,volts], p = p_b, w = w_b, m = m_b)
# 		sg <- c(rep('NA', (w_b-1)/2), sg, rep('NA', (w_b-1)/2))
# 		dt_nest[led == 'blue' & device == x,sg_volts := as.numeric(sg)]
# 		return(dt_nest)	
# 		}

# 	l_ply(c('alpha','beta','epsilon'), golay.fxn)



# ##### Fourier Transformation filter
# 	# SUMMARY: break sample into its various frequency components; isolate 'noise' components and set to 0; retransform Fourier signal into filtered sample signal via Inverese Fourier Transform
# 	# http://databaser.net/moniwiki/pds/_ed_91_b8_eb_a6_ac_ec_97_90_eb_b3_80_ed_99_98/Using_R_for_Smoothing_and_Filtering.pdf
# 	# https://see.stanford.edu/materials/lsoftaee261/book-fall-07.pdf

# 	dt_nest_testonly  <- dt_nest[ datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00') ]


# 	fft.fxn <- function(x){
		
# 		###
# 		# Infrared LED
# 			# fft of entire test	
# 			fft_ir  <- fft(dt_nest_testonly[ device == x & led == 'ir', volts])
# 			len_ir <- length(fft_ir)
# 			# set low-noise points to zero + 0i (set real and imaginary parts to 0)
# 				# select these points manually

# 				# ggplot( data.table(y = Re(fft_ir), x = 1:len_ir) , aes(x = x, y = y) ) + geom_line()
# 				# ggplot( data.table(y = Re(fft_ir), x = 1:len_ir)[2:len_ir] , aes(x = x, y = y) ) + geom_line()
# 				# ggplot( data.table(y = Re(fft_ir), x = 1:len_ir)[2:340] , aes(x = x, y = y) ) + geom_line()


# 			## select sections of fourier signal to set at 0, specific for each device
# 			if (x == 'alpha'){ null_set  <- c( 200: 2750)}
# 			if (x == 'beta'){ null_set  <- c( 200: 3100)}
# 			if (x == 'epsilon'){ null_set  <- c( 200: 2600)}

# 			fft_ir[null_set] = 0 + 0i
			
# 			# Complete normalized inverse Fourier transform
# 			fft_irt = fft(fft_ir, inverse = TRUE)/length(fft_ir)
# 			fft_irr = Re(fft_irt)
# 				# # plot the output
# 				# all vs. original
# 				# p1  <- ggplot(dt_nest_testonly[ device == x & led == 'ir'], aes( x= datetime, y = volts) ) + geom_line() 
# 				# p2  <- ggplot( data.table(y = Re(fft_irt), x = dt_nest_testonly[ device == x & led == 'ir', datetime]) , aes(x = x, y = y) ) + geom_line()
# 				# grid.arrange(p1, p2, ncol=1)
# 				# # #  low concentration region vs. original
# 				# p1  <- ggplot(dt_nest_testonly[ device == x & led == 'ir'][1400:2200], aes( x= datetime, y = volts) ) + geom_line() 
# 				# p2  <- ggplot( data.table(y = Re(fft_irt)[1400:2200], x = dt_nest_testonly[ device == x & led == 'ir', datetime][1400:2200]) , aes(x = x, y = y) ) + geom_line()
# 				# grid.arrange(p1, p2, ncol=1)


# 		###		
# 		# Blue LED
# 			fft_blue  <- fft(dt_nest_testonly[ device == x & led == 'blue', volts])
# 			len_blue <- length(fft_blue)

# 			# set low-noise points to zero + 0i (set real and imaginary parts to 0)
# 				# # select these points manually
# 				# ggplot( data.table(y = Re(fft_blue), x = 1:len_blue) , aes(x = x, y = y) ) + geom_line()
# 				# ggplot( data.table(y = Re(fft_blue), x = 1:len_blue)[2:len_blue] , aes(x = x, y = y) ) + geom_line()
			
# 			## select sections of fourier signal to set at 0, specific for each device
# 			if (x == 'alpha'){ null_set_b  <- c( 200: 680)}
# 			if (x == 'beta'){ null_set_b  <- c( 300: 900)}
# 			if (x == 'epsilon'){ null_set_b  <- c( 150: 450)}

# 			fft_blue[null_set_b] = 0 + 0i
			
# 			# Complete normalized inverse Fourier transform, and convert to real number
# 			fft_bluet = fft(fft_blue, inverse = TRUE)/length(fft_blue)
# 			fft_bluer = Re(fft_bluet)
# 				# # plot the output
# 				# # all vs. original
# 				# p1  <- ggplot(dt_nest_testonly[ device == x & led == 'blue'], aes( x= datetime, y = volts) ) + geom_line() 
# 				# p2  <- ggplot( data.table(y = Re(fft_bluet), x = dt_nest_testonly[ device == x & led == 'blue', datetime]) , aes(x = x, y = y) ) + geom_line()
# 				# grid.arrange(p1, p2, ncol=1)


# 		###	
# 		# output datatable with LED, fft_volts, and datetime
# 		dt_output = data.table(
# 				led = c(rep('ir', length(fft_irr)), rep('blue', length(fft_bluer))),
# 				fft_volts = c(fft_irr, fft_bluer),
# 				datetime = c(dt_nest_testonly[ device == x & led == 'ir', datetime], dt_nest_testonly[ device == x & led == 'blue', datetime]),
# 				device = rep(x, (length(fft_irr) + length(fft_bluer)) )
# 				)
# 	}

# 	# create data table with new FFT values in it
# 	fft_dt <- as.data.table(ldply(c('alpha','beta','epsilon'), fft.fxn))
# 	fft_dt[, led := as.factor(led)]
# 	fft_dt[, device := as.factor(device)]

# 	# merge with  full dataset
# 	dt_nest  <-  merge(dt_nest, fft_dt, by = c('datetime','device', 'led'), all = T)



# ##### Triple rolling average of Fourier Transform
# max_k = 6
# rolling_ave_sizes = c(3,5,7,13)


# 	# for single, double, triple rolling averages 
# 	for ( j in c('single','double','triple') ){


# 		for (p in rolling_ave_sizes){

# 			dt_nest[, paste('fft_ranaught_',p,sep='') := fft_volts]

# 			if (j == 'single'){fft_prior_j  = paste('fft_ranaught_',p,sep='')}
# 			if (j == 'double'){fft_prior_j  = paste('fft_rasingle_',p,sep='')}
# 			if (j == 'triple'){fft_prior_j  = paste('fft_radouble_',p,sep='')}

# 			## Create lag/lead columns for lag/lead of 1 through k points
# 			for (i in 1:max_k){
# 				# lag columns
# 				dt_nest[ led == 'ir', paste('fft_lag',j,"_",i,sep='') := shift( get(fft_prior_j) ,i, type = 'lag'),by = device]
# 				dt_nest[ led == 'blue', paste('fft_lag',j,"_",i,sep='') := shift( get(fft_prior_j) ,i, type = 'lag'), by = device ]
# 				# lead columns
# 				dt_nest[ led == 'ir', paste('fft_lead',j,"_",i,sep='') := shift( get(fft_prior_j) ,i, type = 'lead'), by = device ]
# 				dt_nest[ led == 'blue', paste('fft_lead',j,"_",i,sep='') := shift( get(fft_prior_j) ,i, type = 'lead'), by = device ]
# 			}
			
# 			## Produce rolling averages
# 			k = (p-1)/2
# 				# centered RA
# 			fft_ra_colnames_lag = names(dt_nest)[grep(paste('fft_lag',j, sep = ''),names(dt_nest))][1:k ] 
# 			fft_ra_colnames_lead = names(dt_nest)[grep(paste('fft_lead',j, sep = ''),names(dt_nest))][1:k ] 
# 			fft_ra_colnames = c(fft_ra_colnames_lag, fft_ra_colnames_lead, fft_prior_j)
			
# 			dt_nest[, paste('fft_ra',j,'_',p,sep='') := rowSums(dt_nest[, fft_ra_colnames , with=FALSE]) / p]		
# 		}
	
# 		# drop lag/lead columns -- used only to make the rolling averages
# 		fft_names_laglead <- c(
# 			names(dt_nest)[ grep('fft_lag',names(dt_nest))],
# 			names(dt_nest)[ grep('fft_lead',names(dt_nest))],
# 			names(dt_nest)[ grep('fft_naught',names(dt_nest))]   )
# 		dt_nest[, (fft_names_laglead) := NULL]
# 	}




##### LOESS Smoothing - 12 point loess

## Experimentally determine best smoothing operation
	# plot(dt_nest[ led == 'ir' & device == 'alpha', volts], type = 'l')

	# plot( 
	# 	loess( dt_nest[ led == 'ir' & device == 'alpha', volts] ~ dt_nest[ led == 'ir' & device == 'alpha', as.numeric(datetime)], 
	# 		span = 0.01,
	# 		degree = 0
	# 		)$fitted, 
	#        type = 'l'
	#        )


span_ir =0.0025
degree_ir = 0

span_blue = 0.01
degree_blue = 0


# perform loess smooth

loess_fxn <- function(x){

	## IR
	lo_ir <- data.table(
		volts_loess =	loess( dt_nest[ led == 'ir' & device == x, volts] ~ dt_nest[ led == 'ir' & device == x, as.numeric(datetime)] 
			# + dt_nest[ led == 'ir' & device == x, sample_rate] 
			, 
					span = span_ir,
					degree = degree_ir,
					surface = 'direct',
					model = TRUE)$fitted,
		datetime = dt_nest[ led == 'ir' & device == x & !is.na(datetime), datetime]
		)
	setnames(lo_ir, c('volts_loess','datetime'))
	lo_ir[, led := 'ir']


	## Blue
	lo_blue <- data.table(
		volts_loess =	loess( dt_nest[ led == 'blue' & device == x, volts] ~ dt_nest[ led == 'blue' & device == x, as.numeric(datetime)] 
			# + dt_nest[ led == 'blue' & device == x, sample_rate] 
			, 
					span = span_blue,
					degree = degree_blue,
					surface = 'direct',
					model = TRUE)$fitted,
		datetime = dt_nest[ led == 'blue' & device == x & !is.na(datetime), datetime]
		)
	setnames(lo_blue, c('volts_loess','datetime'))
	lo_blue[, led := 'blue']

	lo <- rbind(lo_ir, lo_blue)

	# name device
	lo[, device := x]

	# return to global environment
	assign(paste("lo",x,sep='_'), lo, envir = .GlobalEnv) 
}

# run function
l_ply(c('alpha','beta','epsilon'), .fun = loess_fxn, .progress='text')

# merge loess dataframes (one per device)
lo <- rbind(lo_alpha, lo_beta, lo_epsilon)

# merge loess data frames with original dataset
dt_nest  <- merge(dt_nest, lo, by = c('device', 'datetime','led'), all.x = TRUE)

# plot
ggplot(dt_nest, aes(x=datetime, y = volts, colour = device)) + geom_point() + facet_grid(led ~.)




#######
#### assign  final 'smoothed' variable
#######
dt_nest[ led == 'ir', volts_smoothed := volts_loess]
dt_nest[ led == 'blue', volts_smoothed := volts_loess]





############ PM calibration

#### PM Calibration Against Dusttrak

	# 	 model_airaw <- lm( pm_dt ~ volts, dt_comb[led=='ir' & device == 'alpha' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00')] )
	# 	 model_biraw <- lm( pm_dt ~ volts, dt_comb[led=='ir' & device == 'beta' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00')] )
	# 	 model_eiraw <- lm( pm_dt ~ volts, dt_comb[led=='ir' & device == 'epsilon' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00')] )

	# 	 model_abraw <- lm( pm_dt ~ volts, dt_comb[led=='blue' & device == 'alpha' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00')] )
	# 	 model_bbraw <- lm( pm_dt ~ volts, dt_comb[led=='blue' & device == 'beta' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00')] )
	# 	 model_ebraw <- lm( pm_dt ~ volts, dt_comb[led=='blue' & device == 'epsilon' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00')] )




	# 	# entire campling period	
	# 	corrALL_ir <- 
	# 		as.data.table(dt_comb[ led == 'ir' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])

	# 	corrALL_blue <- 
	# 		as.data.table(dt_comb[ led == 'blue' & datetime > ymd_hms('2017-02-02 13:18:00') & datetime < ymd_hms('2017-02-02 20:00:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
		
	# 	# 70 mg/m3 period	
	# 	corr70_ir <- 
	# 		as.data.table(dt_comb[ led == 'ir' & datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
	# 	corr70_blue <- 
	# 		as.data.table(dt_comb[ led == 'blue' & datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
		
	# 	# 10 mg/m3 period	
	# 	corr10_ir <- 
	# 		as.data.table(dt_comb[ led == 'ir' & datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
	# 	corr10_blue <- 
	# 		as.data.table(dt_comb[ led == 'blue' & datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
		
	# 	# 5 mg/m3 period	
	# 	corr5_ir <- 
	# 		as.data.table(dt_comb[ led == 'ir' & datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
	# 	corr5_blue <- 
	# 		as.data.table(dt_comb[ led == 'blue' & datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
		
	# 	# 0500 mg/m3 period	
	# 	corr0500_ir <- 
	# 		as.data.table(dt_comb[ led == 'ir' & datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
	# 	corr0500_blue <- 
	# 		as.data.table(dt_comb[ led == 'blue' & datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
		
	# 	# 0100 mg/m3 period	
	# 	corr0100_ir <- 
	# 		as.data.table(dt_comb[ led == 'ir' & datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
	# 	corr0100_blue <- 
	# 		as.data.table(dt_comb[ led == 'blue' & datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00'), mean(nest_DTmean_ratio, na.rm=T), by= device])
		
	# 	# nonzero
	# 	corrNonzero_ir <- as.data.table(
	# 		dt_comb[
	# 			led == 'ir' & datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00')    |
	# 			led == 'ir' & datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00')    |
	# 			led == 'ir' & datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00')    |
	# 			led == 'ir' & datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00')    |
	# 			led == 'ir' & datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00')
	# 		, mean(nest_DTmean_ratio, na.rm=T), by= device])
	# 	corrNonzero_blue <- as.data.table(
	# 		dt_comb[
	# 			led == 'blue' & datetime > ymd_hms('2017-02-02 13:48:00') & datetime < ymd_hms('2017-02-02 14:18:00')    |
	# 			led == 'blue' & datetime > ymd_hms('2017-02-02 18:08:00') & datetime < ymd_hms('2017-02-02 18:38:00')    |
	# 			led == 'blue' & datetime > ymd_hms('2017-02-02 14:48:00') & datetime < ymd_hms('2017-02-02 15:18:00')    |
	# 			led == 'blue' & datetime > ymd_hms('2017-02-02 15:48:00') & datetime < ymd_hms('2017-02-02 16:33:00')    |
	# 			led == 'blue' & datetime > ymd_hms('2017-02-02 17:03:00') & datetime < ymd_hms('2017-02-02 17:43:00')
	# 		, mean(nest_DTmean_ratio, na.rm=T), by= device])


	# # correction against dusttrak
	# correction_ir <- corr10_ir
	# correction_blue <- corr10_ir)

	# # ir
	# dt_nest[ device == 'alpha' & led == 'ir', mg_m3 := volts_smoothed / correction_ir[device == 'alpha', V1] ]
	# dt_nest[ device == 'beta' & led == 'ir', mg_m3 := volts_smoothed / correction_ir[device == 'beta', V1]]
	# dt_nest[ device == 'epsilon' & led == 'ir', mg_m3 := volts_smoothed / correction_ir[device == 'epsilon', V1]]
	# # blue
	# dt_nest[ device == 'alpha' & led == 'blue', mg_m3 := volts_smoothed / correction_blue[device == 'alpha', V1] ]
	# dt_nest[ device == 'beta' & led == 'blue', mg_m3 := volts_smoothed / correction_blue[device == 'beta', V1]]
	# dt_nest[ device == 'epsilon' & led == 'blue', mg_m3 := volts_smoothed / correction_blue[device == 'epsilon', V1]]


# # baseline determination
# 	# create row-wise numeric vector 
# 	foo.t <- t(dt_nest[led == 'ir' & device == 'alpha', volts_smoothed])
# 	# create baseline matrix
# 	bc.fillPeaks  <-  baseline(foo.t, method = 'medianWindow', hwm = 10)
# 	# plot
# 	plot(bc.fillPeaks)




# # Zero by subtracting mean during zero period + 2 
# 	#
# 	number_of_sd = 2
# 	#
# 	zero.fxn <- function(x){
# 		dt_nest[led == 'ir' & device == x, volts_smoothed := volts_smoothed - ( get(paste(x,'_irmean_zero', sep='')) + (number_of_sd*(get(paste(x,'_irsd_zero', sep='')))) ) ]	
# 		dt_nest[led == 'blue' & device == x, volts_smoothed := volts_smoothed - ( get(paste(x,'_irmean_zero', sep='')) + (number_of_sd*(get(paste(x,'_irsd_zero', sep='')))) ) ]	
# 		return(dt_nest)
# 	}
# 	l_ply( c('alpha','beta','epsilon'), zero.fxn)

# 	# force negative values to 0
# 	dt_nest[ volts_smoothed < 0, volts_smoothed := 0]




##### correction using linear models
# dt_nest[volts_smoothed == 0, mg_m3 := 0]
	

# compare to dusttrak
# combine the two datasets
dt_comb <- merge(dt_nest, dt_dust, by = 'datetime', all.x=T)
dt_comb[!(is.na(pm_dtX)) & !is.na(pm_dtY) ,pm_dt := (pm_dtX + pm_dtY) / 2]

	#P redict volts ~ PM
	cal_model_function_dv <- function(x){

		model_i <- lm( volts_smoothed ~ pm_dt, dt_comb[led=='ir' & device == x & datetime >= ymd_hms('2017-02-02 13:18:00') & datetime <= ymd_hms('2017-02-02 20:00:00')] )

		model_b <- lm( volts_smoothed ~ pm_dt, dt_comb[led=='blue' & device == x & datetime >= ymd_hms('2017-02-02 13:18:00') & datetime <= ymd_hms('2017-02-02 20:00:00')] )
		
		assign(paste("model_", substring(x,1,1) ,'i_dv',sep=''), model_i, envir = .GlobalEnv) 
		assign(paste("model_", substring(x,1,1) ,'b_dv',sep=''), model_b, envir = .GlobalEnv) 

	}

	l_ply(c('alpha','beta','epsilon'), .fun = cal_model_function_dv, .progress='text')

	# Predict PM ~ volts
	cal_model_function <- function(x){

		model_i <- lm( pm_dt ~ volts_smoothed, dt_comb[led=='ir' & device == x & datetime >= ymd_hms('2017-02-02 13:18:00') & datetime <= ymd_hms('2017-02-02 20:00:00')] )

		model_b <- lm( pm_dt ~ volts_smoothed, dt_comb[led=='blue' & device == x & datetime >= ymd_hms('2017-02-02 13:18:00') & datetime <= ymd_hms('2017-02-02 20:00:00')] )
		
		assign(paste("model_", substring(x,1,1) ,'i',sep=''), model_i, envir = .GlobalEnv) 
		assign(paste("model_", substring(x,1,1) ,'b',sep=''), model_b, envir = .GlobalEnv) 

	}

	l_ply(c('alpha','beta','epsilon'), .fun = cal_model_function, .progress='text')



## apply linear calibration (Predict PM ~ volts)

correction_fxn <- function(x){

	#IR LED
	dt_nest[ device == x & led == 'ir' & volts_smoothed > 0 , mg_m3 := predict(
		get(paste("model_", substring(x,1,1) ,'i',sep='')),
		data.frame(volts_smoothed = volts_smoothed)) ]
	# blue LED
	dt_nest[ device == x & led == 'blue' & volts_smoothed > 0 , mg_m3 := predict(
		get(paste("model_", substring(x,1,1) ,'b',sep='')),
		data.frame(volts_smoothed = volts_smoothed)) ]

}

l_ply(c('alpha','beta','epsilon'), .fun = correction_fxn, .progress='text')

ggplot(dt_nest, aes(x=datetime, y = mg_m3, colour = device)) + geom_line() + facet_grid(device + led ~.)


	# summarize models
	summary(lm(model_ai_dv))
	summary(lm(model_bi_dv))
	summary(lm(model_ei_dv))
	summary(lm(model_ab_dv))
	summary(lm(model_bb_dv))
	summary(lm(model_eb_dv))




### ZERO
	baseline_z_start <- ymd_hm("2017-2-2 13:17") 
	baseline_z_end <- ymd_hm("2017-2-2 13:47") 
	posttest_z_start <- ymd_hm("2017-2-2 19:00") 
	posttest_z_end <- ymd_hm("2017-2-2 20:00") 
	# numeric datetime range
	datetime_range_z <- c(seq(as.numeric(ymd_hm("2017-2-2 13:17")), as.numeric(ymd_hm("2017-2-2 13:47") )),
				seq(as.numeric(ymd_hm("2017-2-2 19:00")), as.numeric(ymd_hm("2017-2-2 20:00") ))
				)
	# create new dataset for baseline and post-sample zero periods only
	dt_nest_z <- dt_nest[ as.numeric(datetime) %in% datetime_range_z]
	# define pre-zero vs. post-zero
	dt_nest_z[datetime >= baseline_z_start & datetime <= baseline_z_end, posttest := 0]
	dt_nest_z[datetime >= posttest_z_start & datetime <= posttest_z_end, posttest := 1]

	# plot
	ggplot(dt_nest_z[posttest == 1], aes(x = 1:length( volts_smoothed ) , y = volts_smoothed)) + geom_line() + facet_wrap(~ device + led, nrow = 3, scales = "free")  #+ geom_point()

	# summary stats
	dt_nest_z[, mean(volts_smoothed), by = c('device','led')]
	dt_nest_z[, sd(volts_smoothed), by = c('device','led')]



# baseline via mean and SD during zero periods -- USE POST-SAMPLE ONLY

zero_read.fxn <- function(x){

	## For non-grav adjusted LOESS smoothed
		# calculate mean		
		irmean_zero <- dt_nest_z[ device == x & led == 'ir' & posttest == 1, mean(volts_smoothed, na.rm=T)]
		bluemean_zero <- dt_nest_z[ device == x & led == 'blue' & posttest == 1, mean(volts_smoothed, na.rm=T)]
		
		# calculate standard dev
		irsd_zero <- dt_nest_z[ device == x & led == 'ir' & posttest == 1, sd(volts_smoothed, na.rm= T)]
		bluesd_zero <- dt_nest_z[ device == x & led == 'blue' & posttest == 1, sd(volts_smoothed, na.rm= T)]
		
		
	## For grav adjusted LOESS smoothed
		# calculate mean		
		irmean_zero_g <- dt_nest_z[ device == x & led == 'ir' & posttest == 1, mean(mg_m3, na.rm=T)]
		bluemean_zero_g <- dt_nest_z[ device == x & led == 'blue' & posttest == 1, mean(mg_m3, na.rm=T)]
		
		# calculate standard dev
		irsd_zero_g <- dt_nest_z[ device == x & led == 'ir' & posttest == 1, sd(mg_m3, na.rm= T)]
		bluesd_zero_g <- dt_nest_z[ device == x & led == 'blue' & posttest == 1, sd(mg_m3, na.rm= T)]


		# output to global var
		assign( paste( x,'_irmean_zero' , sep='') ,irmean_zero, envir = .GlobalEnv)
		assign( paste( x,'_bluemean_zero' , sep='') ,bluemean_zero , envir = .GlobalEnv)
		assign( paste( x,'_irsd_zero' , sep='') ,irsd_zero, envir = .GlobalEnv)
		assign( paste( x,'_bluesd_zero' , sep='') ,bluesd_zero, envir = .GlobalEnv)

		assign( paste( x,'_irmean_zero_g' , sep='') ,irmean_zero_g, envir = .GlobalEnv)
		assign( paste( x,'_bluemean_zero_g' , sep='') ,bluemean_zero_g , envir = .GlobalEnv)
		assign( paste( x,'_irsd_zero_g' , sep='') ,irsd_zero_g, envir = .GlobalEnv)
		assign( paste( x,'_bluesd_zero_g' , sep='') ,bluesd_zero_g, envir = .GlobalEnv)
		
		}

	l_ply( c('alpha','beta','epsilon'), zero_read.fxn, .progress = 'text')



# write to CSV
write.csv(dt_nest, '~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/nestData_temp_and_grav_adj.csv', row.names=F)