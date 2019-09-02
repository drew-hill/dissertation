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

