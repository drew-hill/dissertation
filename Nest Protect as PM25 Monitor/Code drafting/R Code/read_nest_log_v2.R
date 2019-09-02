# a quick script template for reading in the files produced by the nest_read.py script
# by Drew Hill, UC Berkeley
# June 2016

# bash command to transfer file from RasPi
# scp lawson@192.168.29.157:~/nest_datalog.txt ~/Desktop

library(data.table)
library(plyr)
library(lubridate)

filename <- "~/Dropbox/Aerie/Nest Protect Teardown/early nest pats tests/HillHouse - 13June/datafiles/nest_datalog.txt"
col.names <- c('led','datetime','voltage','pi_tempC','tempC','rh')

dt1 <- fread(filename, col.names=col.names)

# truncate and update datetime
dt1[,datetime := ymd_hms(datetime, tz="America/Los_Angeles")]
dt1[, datetime := round_date(datetime, unit = c("second"))]

# convert voltage to mV
dt1[, mv := voltage*1000]
#drop regular voltage
dt1[, c('voltage') := NULL, with=F]

# create separate voltage columns by IR type
	# assumes pi_temp is always the same for ir and blue at datetime X
dt <- dcast.data.table(dt1, datetime + pi_tempC + tempC +rh ~ led, value.var = c("mv"))

# dataset where readings averaged by minute
dt1_min <- dt1
dt1_min[,datetime := round_date(datetime, unit = c("minute"))]
dt1_min[,avg_mv:=mean(mv, na.rm=T),by="led,datetime"]
dt1_min[,avg_pi_tempC:=mean(pi_tempC, na.rm=T),by="led,datetime"]
dt1_min[,avg_tempC:=mean(tempC, na.rm=T),by="led,datetime"]
dt1_min[,avg_rh:=mean(rh, na.rm=T),by="led,datetime"]

dt1_min[,c("mv","pi_tempC","tempC","rh"):=NULL, with=F]
dt1_min <- unique(dt1_min)

dt_min <- dcast.data.table(dt1_min, datetime + avg_pi_tempC + avg_tempC + avg_rh ~ led, value.var = c("avg_mv"))

# average tempC and rh will differ between IR and Blue due to the frequency of measurement (Blue LEd is less frequent than IR LED), so replace average temp for Blue measurements with that of IR measurements 
