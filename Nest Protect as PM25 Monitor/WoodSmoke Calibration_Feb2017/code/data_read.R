## Read in data from the Feb 2 Lab PM Calibration

library(data.table)
library(lubridate)
library(plyr)
library(ggplot2)


############
######## 	NEST DATA
############

############ Read raw files
# alpha
dt_pa <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/alpha/logpm_woodsmoke_calibration_alpha_2feb.txt', col.names = c('led', 'datetime','bits'))
dt_ta <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/alpha/logtemp_woodsmoke_calibration_alpha_2feb.txt', col.names = c('datetime', 'tempC','rh','sys_tempC'))
# beta
dt_pb <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/beta/logpm_woodsmoke_calibration_beta_2feb.txt', col.names = c('led', 'datetime','bits'))
dt_tb <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/beta/logtemp_woodsmoke_calibration_beta_2feb.txt', col.names = c('datetime', 'tempC','rh','sys_tempC'))
# epsilon
dt_pe <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/epsilon/logpm_woodsmoke_calibration_epsilon_2feb.txt', col.names = c('led', 'datetime','bits'))
dt_te <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/epsilon/logtemp_woodsmoke_calibration_epsilon_2feb.txt', col.names = c('datetime', 'tempC','rh','sys_tempC'))


######### Stack datatables
# create device variable names
dt_pa[,device := 'alpha']
dt_ta[,device := 'alpha']
dt_pb[,device := 'beta']
dt_tb[,device := 'beta']
dt_pe[,device := 'epsilon']
dt_te[,device := 'epsilon']

# create list
pm_list <- list(dt_pa,dt_pb,dt_pe)
temp_list <- list(dt_ta,dt_tb,dt_te)

# combine/stack by row
pm <- rbindlist(pm_list)
temp <- rbindlist(temp_list)


########## adjust datetime
# convert from string to datetime format
pm[, datetime := ymd_hms(datetime)]
temp[, datetime := ymd_hms(datetime)]

# join pm and temp datatables by nearest datetime
pm[, date_round := round_date(datetime, unit = "10 seconds")]
temp[, date_round := round_date(datetime, unit = "10 seconds")]
	# # check for any missing timestamps / readings
	# # pm - GOOD (some skipped/missing readings, but otherwise good)
	# 	pm[, date_prior := shift(datetime, 1L, type = "lag"), by = c('device','led')]
	# 	pm[, date_diff := as.numeric(difftime(datetime,date_prior))]
	# 	# countinug -- expect mostly 0, 2, 10, 190, 200, 210 NA... check others, especially non-even values
	# 	count(pm[,date_diff])
	# 	print(pm[!date_diff  %in% c(0,2,10,190, 200, 210,'NA')], nrows = 110)
	# # temperature - GOOD
	# 	temp[, date_prior := shift(datetime, 1L, type = "lag"), by = device]
	# 	temp[, date_diff := as.numeric(difftime(datetime,date_prior))]
	# 	# countinug -- expect only 10 and NA
	# 	count(temp[,date_diff])

# drop temp datetime to avoid confusion
temp[, datetime := NULL]


########## merge temp and pm
# merge by device and rounded date 
dt_nest <- merge(pm, temp, by = c('device','date_round'), all.x = T)
	# # examine rows without Temp data - GOOD -- 42 PM samples without temp data (nrow of pm == 18422, while nrow of dt == 18380)
	# # all missing samples are from pre-test Epsilon run. OK to ignore
	# print(dt_nest[is.na(tempC)], nrows = 50)
	dt_nest <- dt_nest[complete.cases(dt_nest)]

# drop rounded date variable
dt_nest[, date_round := NULL]


########## save datatable to disk
write.csv(dt_nest, '~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/nestData_unadj.csv' ,row.names = FALSE)




############
######## 	DUSTTRAK II DATA
############

############ read raw data 
#DustTrak X1
DustTrakX1 <- readLines('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/dusttraks/DusttrakX1_2Feb2017.txt')

# isolate data from master file
MANUAL_026  <-  DustTrakX1[8811: 8840]
MANUAL_027  <- DustTrakX1[8869:8871]
MANUAL_028  <-  DustTrakX1[8900:9177]
MANUAL_029  <- DustTrakX1[9206:33744]
MANUAL_030  <- DustTrakX1[33773:37659]

# function convert run files into data tables
dusttrak_clean_function_dtX <- function(x){
	temp  <- get(x)
	
	# convert from list of comma-sep varialbes -> list of lists -> to one large string -> matrix -> data table
	temp <- as.data.table(
				matrix( 
					unlist( 
						strsplit(temp, ",") 
						) 
					,  ncol = 3, byrow = TRUE)
				)
	# set column names 
	setnames(temp, c('date','time','pm_dtX'))
	# create datetime variable
	temp[, datetime := mdy_hms(paste(date, time, sep = " "))]
	temp[,c('date','time') := NULL]

	# make pm value numeric
	temp[, pm_dtX := as.numeric(pm_dtX)]

	# create variable for sample name
	temp[, sample_dtX := x]

}

# convert run files into data tables
run_list_dtX1 <- c('MANUAL_026', 'MANUAL_027', 'MANUAL_028', 'MANUAL_029', 'MANUAL_030')
dusttrak_x1 <- as.data.table( ldply( run_list_dtX1, dusttrak_clean_function_dtX) )


# function convert run files into data tables
dusttrak_clean_function_dtY <- function(x){
	temp  <- get(x)
	
	# convert from list of comma-sep varialbes -> list of lists -> to one large string -> matrix -> data table
	temp <- as.data.table(
				matrix( 
					unlist( 
						strsplit(temp, ",") 
						) 
					,  ncol = 3, byrow = TRUE)
				)
	# set column names 
	setnames(temp, c('date','time','pm_dtY'))
	# create datetime variable
	temp[, datetime := mdy_hms(paste(date, time, sep = " "))]
	temp[,c('date','time') := NULL]

	# make pm value numeric
	temp[, pm_dtY := as.numeric(pm_dtY)]

	# create variable for sample name
	temp[, sample_dtY := x]

}


#DustTrak X1
DustTrakY <- readLines('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/dusttraks/DusttrakY_2Feb2017.txt')

# isolate data from master file
MANUAL_005  <-  DustTrakY[30:305]
MANUAL_006  <-  DustTrakY[334:24872]
MANUAL_007  <-  DustTrakY[24901:28785]

run_list_dtY <- c('MANUAL_005', 'MANUAL_006', 'MANUAL_007')
dusttrak_y <- as.data.table(ldply( run_list_dtY, dusttrak_clean_function_dtY))

dt_dust <- merge(dusttrak_x1, dusttrak_y, all= T)

# write to disk
write.csv(dt_dust, '~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/dusttraks/dusttrakData_unadj.csv' ,row.names = FALSE)