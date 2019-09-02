library(data.table)
library(plyr)
library(lubridate)
library(ggplot2)


########## Read in
# a quick script template for reading in the files produced by the nest_read_wfloor.py script
# by Drew Hill, UC Berkeley
# Dec 2016

# bash command to transfer file from RasPi
# scp lawson@192.168.29.157:~/nest_datalog.txt ~/Desktop

library(data.table)
library(plyr)
library(lubridate)
library(ggplot2)

filename <- "~/Desktop/nest_datalog_data_2016dec12.txt"
col.names <- c('led','datetime','floor','mv','pi_tempC','tempC','rh')

dt1 <- fread(filename, col.names=col.names)

# truncate and update datetime
dt1[,datetime := ymd_hms(datetime, tz="America/Los_Angeles")]
dt1[, datetime := round_date(datetime, unit = c("second"))]

# create separate voltage columns by IR type
	# assumes pi_temp is always the same for ir and blue at datetime X
	# ignores/drops floor
dt <- dcast.data.table(dt1, datetime + pi_tempC + tempC +rh ~ led, value.var = c("mv"))

# adjust IR output by temperature, based on lab calibration
# device code 'alpha'
dt[, ir := ir - (-0.64954 * tempC + 0.04560*rh) ]

# cal_alpha_ir <- 577.15918 + (-0.64954 * tempC) + (0.04560*rh)


# average tempC and rh will differ between IR and Blue due to the frequency of measurement (Blue LEd is less frequent than IR LED), so replace average temp for Blue measurements with that of IR measurements 









########### assign datatable of interest to 'dt'
dt_proc  <- copy(dt)
dt_proc <- rename(dt_proc, c('ir'='ir_lag0'))


############ Kalman FIltering signal process





########### create lagged ir and blue columns



############ Weighted Average signal process
# low IR flag ... iterative

	## Step 1) raw difference between global mean and point value must be < 1 sd
	dt_proc[,c('ir_low') := 0]
	dt_step1 <- dt_proc[ dt_proc[, mean(ir_lag0, na.rm=T)] - ir_lag0 >  dt_proc[, sd(ir_lag0, na.rm=T)] , ir_low :=1 ][ ir_low < 1]
	
	ggplot(dt_step1, aes(x=datetime, y = ir_lag0) ) + geom_point() + ylim(c(545,590))

	
	## Step 2) Raw difference between 6-point (1 minute) rolling average and current point must be < 1/4 SD; note that this only looks at major decreases in the RA, and not increases

		########### Create Rolling averages
		rolling_ave_sizes = c(6)
		## create lag columns
		max_lag = 30 # 5 minute rolling average
		for (i in 1:max_lag){
			dt_step1[, paste('ir_lag',i,sep='') := shift(ir_lag0,i)]
		}
		# rolling avg
		for (i in rolling_ave_sizes){

			ra_colnames = names(dt_step1)[grep('lag',names(dt_step1))][1:i] 
			dt_step1[, paste('ir_ra',i,sep='') := rowSums(dt_step1[, ra_colnames , with=FALSE]) / i]
		}
		# rolling stdev
		for (i in rolling_ave_sizes){
			ra_colnames = names(dt_step1)[grep('lag',names(dt_step1))][1:i] 
			dt_step1[, paste('ir_rs',i,sep='')  := apply(dt_step1[, ra_colnames , with=FALSE], 1, sd, na.rm=F)]
		}
		# drop lag columns
		lag_names = names(dt_step1)[grep('lag',names(dt_step1))]
		dt_step1[, unlist(lag_names[2:length(lag_names)]) := NULL]

	dt_step1[,c('ir_low') := 0]
	dtf  <- dt_step1[ ir_ra6 - ir_lag0 > dt_step1[,sd( ir_lag0, na.rm=T)] / 4 , ir_low :=1 ][ir_low < 1]


# drop extranneous columns
dtf[, c('ir_low','ir_ra6') := NULL]




############## Create rolling averages in final data table
## dtf is new datatable (data tabel final)
rolling_ave_sizes = c(3,6,12, 30)

## create lag columns
max_lag = 30 # 5 minute rolling average

for (i in 1:max_lag){
	dtf[, paste('ir_lag',i,sep='') := shift(ir_lag0,i)]
}

# # every 20 samples for blue
# dt_step1[, blue_lag := shift(blue, 20)]


# rolling avg
for (i in rolling_ave_sizes){

	ra_colnames = names(dtf)[grep('lag',names(dtf))][1:i] 
	dtf[, paste('ir_ra',i,sep='') := rowSums(dtf[, ra_colnames , with=FALSE]) / i]
}

# rolling stdev
for (i in rolling_ave_sizes){
	ra_colnames = names(dtf)[grep('lag',names(dtf))][1:i] 
	dtf[, paste('ir_rs',i,sep='')  := apply(dtf[, ra_colnames , with=FALSE], 1, sd, na.rm=F)]
}

# drop lag columns
lag_names = names(dtf)[grep('lag',names(dtf))]
dtf[, unlist(lag_names[2:length(lag_names)]) := NULL]


ggplot(dtf) + geom_point(aes(x=datetime, y = ir_lag0),size=0.5 ) + geom_line(aes(x=datetime, y=tempC + 580), colour= 'red') + geom_line(aes(x=datetime, y=rh+550), colour = 'blue') + geom_line(aes(x=datetime, y=pi_tempC + 560), colour= 'green') 

	ggplot(dtf, aes(x=datetime, y = ir_ra6) ) + geom_point() + geom_line(aes(x=datetime, y=tempC + 580), colour= 'red') + geom_line(aes(x=datetime, y=rh+550), colour = 'blue') + geom_line(aes(x=datetime, y=pi_tempC + 560), colour= 'green') 

	ggplot(dtf, aes(x=datetime, y = ir_ra30) ) + geom_point() + geom_line(aes(x=datetime, y=tempC + 580), colour= 'red') + geom_line(aes(x=datetime, y=rh+550), colour = 'blue') + geom_line(aes(x=datetime, y=pi_tempC + 560), colour= 'green') 

# average by minute
# dt1_min <- dt
# dt1_min[,datetime := round_date(datetime, unit = c("minute"))]
# dt1_min[, avg_ir := mean(ir_ra6, na.rm=T), by = datetime]

# ggplot(dt1_min[ir_ra6 > 0], aes(x=datetime, y = avg_ir ) ) + geom_line() + geom_point(colour='blue', size = .2) + theme_bw() + ylim(c(-5,5))
