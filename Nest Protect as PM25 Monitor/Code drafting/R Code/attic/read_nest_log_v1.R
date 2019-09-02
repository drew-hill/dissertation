# a quick script template for reading in the files produced by the nest_read.py script
# by Drew Hill, UC Berkeley
# June 2016

# bash command to transfer file from RasPi
# scp lawson@192.168.29.157:~/nest_monster_test_9June_early_copy.txt ~/Desktop

library(data.table)
library(plyr)
library(lubridate)

filename <- "~/Desktop/nest_monster_test_9June_early_copy.txt"
col.names <- c('led','datetime','voltage','pi_temp')

dt1 <- fread(filename, col.names=col.names)

# truncate and update datetime
dt1[,datetime := ymd_hms(datetime, tz="America/Los_Angeles")]

# make temp numeric, dropping extranneous bits
dt1[,pi_temp := strsplit(pi_temp,'=')[[1]][2] ]
dt1[,pi_temp := strsplit(pi_temp,"'")[[1]][1] ]
dt1[,pi_temp := as.numeric(pi_temp) ]

# convert voltage to mV
dt1[, mv := voltage*1000]
#drop regular voltage
dt1[, c('voltage') := NULL, with=F]

# create separate voltage columns by IR type
	# assumes pi_temp is always the same for ir and blue at datetime X
dt <- dcast.data.table(dt1, datetime + pi_temp ~ led, value.var = c("mv"))

# dataset where readings averaged by minute
dt1_min <- dt1
dt1_min[,datetime := floor_date(datetime, unit = c("minute"))]
dt1_min[,avg_mv:=mean(mv, na.rm=T),by="led,datetime"]
dt1_min[,avg_pi_temp:=mean(pi_temp, na.rm=T),by="led,datetime"]
dt1_min[,c("mv"):=NULL, with=F]
dt1_min <- unique(dt1_min)

dt_min <- dcast.data.table(dt1_min, datetime + avg_pi_temp ~ led, value.var = c("avg_mv"))


# library(ggplot2)
# ggplot(dt1_min, aes(x=datetime, y=avg_mv-400, colour=led))+geom_line()

cor(x=dt[!is.na(blue) & !is.na(ir),blue],y = dt[!is.na(blue) & !is.na(ir),ir])
cor(x=dt_min[!is.na(blue),blue],y = dt_min[!is.na(blue),ir])