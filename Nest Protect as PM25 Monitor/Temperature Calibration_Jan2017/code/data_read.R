## Read in data from the January 24 Lab Temperature Calibration

library(data.table)
library(lubridate)
library(ggplot2)


########## read in Nest data
# alpha
dt_pa <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/alpha/alpha_logpm_temp_calibration_24an.txt', col.names = c('led', 'datetime','bits'))
dt_ta <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/alpha/alpha_logtemprh_temp_calibration_24jan.txt', col.names = c('datetime', 'tempC','rh','sys_tempC'))
# beta
dt_pb <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/beta/beta_logpm_temp_calibration_24an.txt', col.names = c('led', 'datetime','bits'))
dt_tb <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/beta/beta_logtemprh_temp_calibration_24jan.txt', col.names = c('datetime', 'tempC','rh','sys_tempC'))
# epsilon
dt_pe <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/epsilon/epsilon_logpm_temp_calibration_24an.txt', col.names = c('led', 'datetime','bits'))
dt_te <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/epsilon/epsilon_logtemprh_temp_calibration_24jan.txt', col.names = c('datetime', 'tempC','rh','sys_tempC'))


######### Tidy AND Stack datatables
	# create device variable names
	dt_pa[,device := as.factor('alpha')]
	dt_ta[,device := as.factor('alpha')]
	dt_pb[,device := as.factor('beta')]
	dt_tb[,device := as.factor('beta')]
	dt_pe[,device := as.factor('epsilon')]
	dt_te[,device := as.factor('epsilon')]

	## Combine datatables
	# create list
	pm_list <- list(dt_pa,dt_pb,dt_pe)
	temp_list <- list(dt_ta,dt_tb,dt_te)

	# combine/stack by row
	pm <- rbindlist(pm_list)
	temp <- rbindlist(temp_list)

	# make datetime a true datetime variable
	pm[, datetime := ymd_hms(datetime)]
	temp[, datetime := ymd_hms(datetime)]

	# create datetime variable that rounds to closest 10 second calue
	pm[, date_round := round_date(datetime, unit = "10 seconds")]
	temp[, date_round := round_date(datetime, unit = "10 seconds")]

	# drop temp datetime -- pm datetime is more important so will be kept
	temp[, datetime := NULL]

	# make LED a factor for clarity
	pm[, led := as.factor(led)]

	# convert bits to volts
	# reference voltage used in the hardware setup
	vref = 3.3
	# max capacity of ADC (at 12 bits), accountinng for 0 as lowest value (rather than 1)
	max_bits = (2^12) - 1
	# make conversion
	pm[, volts := round( (bits/max_bits) * vref, 3)]



########## merge temp and pm
# merge by device and rounded date
dt <- merge(pm, temp, by = c('device','date_round'), all.x = T)

# drop rounded date variable
dt[, date_round := NULL]


########### Flag various parts of the calibration process
# zero
dt[,zero_flag := 0]
dt[ datetime > ymd_hms('2017-01-24 14:12:00') & datetime < ymd_hms('2017-01-24 20:50:00') ,zero_flag := 1]

# incubator
dt[,incub_flag := 0]
dt[ datetime > ymd_hms('2017-01-24 14:40:00') & datetime < ymd_hms('2017-01-24 20:10:00') ,incub_flag := 1]


########## Isolate and remove outliers

## decision rule = difference between current and previous reading is > 5 SD (keeping this positive allows us to catch only low outliers, i.e. values lthat are outliers due to the mechanism we describe in the paper... lagged adc reading)

# # plot
# ggplot(dt) + geom_point(aes(x = tempC, y = volts, colour = device, shape = led)) + facet_wrap(~led, scales = "free", nrow = 2) + ggtitle("Temperature Correlation, by Device & LED") + ylab("Response") + xlab("Temperature (C)") + facet_grid(device + led ~ ., scales = 'free')

# create rolling standard deviation... five point
# (from -k to k, where k = N/2 ... i.e. k samples pre data point and k samples post data point)
max_k = 6


## Create lag/lead columns for lag/lead of 1 through k points
for (i in 1:max_k){
	# lag columns
	dt[ led == 'ir', paste('lag',i,sep='') := shift( volts ,i, type = 'lag'), by = device ]
	dt[ led == 'blue', paste('lag',i,sep='') := shift( volts ,i, type = 'lag'),by = device ]
	# # lead columns
	# dt[ led == 'ir', paste('lead',i,sep='') := shift( volts ,i, type = 'lead') ]
	# dt[ led == 'blue', paste('lead',i,sep='') := shift( volts ,i, type = 'lead') ]
}

## Produce rolling averages and SDs
	# centered RA
ra_colnames_lag = names(dt)[grep('^lag',names(dt))][1:max_k ] 
# ra_colnames_lag = names(dt)[grep('lag',names(dt))][1:max_k ] 
# ra_colnames = c(ra_colnames_lag, ra_colnames_lead, prior_j)
dt[, rnum:=1:nrow(dt)]
dt[, sd_roll6 := sd(c(lag1,lag2,lag3,lag4,lag5,lag6)), by='rnum']
dt[, mean_roll6 := mean(c(lag1,lag2,lag3,lag4,lag5,lag6)), by='rnum']


## Create variable indicating difference between previous and current value in terms of roll6 SD
dt[, sd_diff := (lag1 - volts)/sd_roll6 ]
# # plot - before drop
# ggplot(dt) + geom_point(aes(x = tempC, y = volts, colour = device, shape = led)) + facet_wrap(~led, scales = "free", nrow = 2) + ggtitle("Temperature Correlation, by Device & LED") + ylab("Response") + xlab("Temperature (C)") + facet_grid(device + led ~ ., scales = 'free')


## drop anything with sd_diff > 5 SDs
nrow(dt[ sd_diff >= 5])

dt <- dt[sd_diff < 5]

# # plot - after drop
# ggplot(dt) + geom_point(aes(x = tempC, y = volts, colour = device, shape = led)) + facet_wrap(~led, scales = "free", nrow = 2) + ggtitle("Temperature Correlation, by Device & LED") + ylab("Response") + xlab("Temperature (C)") + facet_grid(device + led ~ ., scales = 'free')


########## model temp and rh impacts
# ir LED correction
summary(lm( volts ~ tempC, data = dt[led=='ir' & device == 'alpha' & incub_flag == 1]))
summary(lm( volts ~ tempC, data = dt[led=='ir' & device == 'beta' & incub_flag == 1]))
summary(lm( volts ~ tempC, data = dt[led=='ir' & device == 'epsilon' & incub_flag == 1]))

summary(lm( volts ~ tempC, data = dt[led=='blue' & device == 'alpha' & incub_flag == 1]))
summary(lm( volts ~ tempC, data = dt[led=='blue' & device == 'beta' & incub_flag == 1]))
summary(lm( volts ~ tempC, data = dt[led=='blue' & device == 'epsilon' & incub_flag == 1]))





# # plot volts vs temp
# ggplot( dt[led == 'ir' & device == 'alpha' & incub_flag == 1], aes( x=tempC, y = volts)) + geom_point()
# ggplot( dt[led == 'ir' & device == 'beta' & incub_flag == 1], aes( x=tempC, y = volts)) + geom_point()
# ggplot( dt[led == 'ir' & device == 'epsilon' & incub_flag == 1], aes( x=tempC, y = volts)) + geom_point()
# ggplot( dt[led == 'blue' & device == 'alpha' & incub_flag == 1], aes( x=tempC, y = volts)) + geom_point()
# ggplot( dt[led == 'blue' & device == 'beta' & incub_flag == 1], aes( x=tempC, y = volts)) + geom_point()
# ggplot( dt[led == 'blue' & device == 'epsilon' & incub_flag == 1], aes( x=tempC, y = volts)) + geom_point()

# # plot volts vs rh
# ggplot( dt[led == 'ir' & device == 'alpha' & incub_flag == 1] , aes( x=rh, y = volts)) + geom_point()
# ggplot( dt[led == 'ir' & device == 'beta' & incub_flag == 1], aes( x=rh, y = volts)) + geom_point()
# ggplot( dt[led == 'ir' & device == 'epsilon' & incub_flag == 1], aes( x=rh, y = volts)) + geom_point()
# ggplot( dt[led == 'blue' & device == 'alpha' & incub_flag == 1], aes( x=rh, y = volts)) + geom_point()
# ggplot( dt[led == 'blue' & device == 'beta' & incub_flag == 1], aes( x=rh, y = volts)) + geom_point()
# ggplot( dt[led == 'blue' & device == 'epsilon' & incub_flag == 1], aes( x=rh, y = volts)) + geom_point()

# # plot rh over time
# ggplot(dt[led == 'ir' & device == 'alpha' & incub_flag == 1], aes(x=datetime, y=rh)) + geom_point()
# ggplot(dt[led == 'ir' & device == 'beta' & incub_flag == 1], aes(x=datetime, y=rh)) + geom_point()
# ggplot(dt[led == 'ir' & device == 'epsilon' & incub_flag == 1], aes(x=datetime, y=rh)) + geom_point()

# # plot temp over time
# ggplot(dt[led == 'ir' & device == 'alpha' & incub_flag == 1], aes(x=datetime, y=tempC)) + geom_point()
# ggplot(dt[led == 'ir' & device == 'beta' & incub_flag == 1], aes(x=datetime, y=tempC)) + geom_point()
# ggplot(dt[led == 'ir' & device == 'epsilon' & incub_flag == 1], aes(x=datetime, y=tempC)) + geom_point()

# # plot systemp over time
# ggplot(dt[led == 'ir' & device == 'alpha' & incub_flag == 1], aes(x=datetime, y=sys_tempC)) + geom_point()
# ggplot(dt[led == 'ir' & device == 'beta' & incub_flag == 1], aes(x=datetime, y=sys_tempC)) + geom_point()
# ggplot(dt[led == 'ir' & device == 'epsilon' & incub_flag == 1], aes(x=datetime, y=sys_tempC)) + geom_point()


########## summary
summary(dt[led=='ir' & device == 'alpha' & incub_flag == 1])
summary(dt[led=='ir' & device == 'beta' & incub_flag == 1])
summary(dt[led=='ir' & device == 'epsilon' & incub_flag == 1])

summary(dt[led=='blue' & device == 'alpha' & incub_flag == 1])
summary(dt[led=='blue' & device == 'beta' & incub_flag == 1])
summary(dt[led=='blue' & device == 'epsilon' & incub_flag == 1])



# plot Figure 4
dt[ led == 'ir', led := "Infrared LED"]
dt[ led == 'blue', led := "Blue LED"]

fig4 <- ggplot(dt) + geom_point(aes(x = tempC, y = volts, colour = device)) + facet_wrap(~led, scales = "free", nrow = 2) + ylab("Response (V)") + xlab("Temperature (C)") + theme_bw() + theme(plot.title = element_text(hjust = 0.5)) + scale_colour_manual(name = 'Device', values = c('#F8766D','#00BA38','#619Cff'), labels = c('alpha','beta','epsilon')) #+ ggtitle("Temperature Correlation, by Device & LED") 

ggsave(filename = '~/Box Sync/Dissertation/Nest Chapter/SSD Figures/Figure_4.tiff', plot = fig4, path = NULL, scale = 1, width = 6, height = 4, units = c("in"), dpi = 300)




########## read in DustTrak data
dt_dust <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/Temperature Calibration_Jan2017/data/dusttrak/DustTrak_temperaturecal_24jan2017_noHeader.txt', header= T, col.names = c('date','time','pm'))
dt_dust[, datetime := mdy_hms( paste(date,time, sep = ' ') )]
dt_dust[,c('date','time') :=  NULL]


# mean in Bin during Bin Zero Confirmation
	# with zero filter attachd to bin
dt_dust[ datetime > ymd_hm('2017-01-24 14:12') & datetime < ymd_hm('2017-01-24 14:15'), summary(pm)]
	#without zero filter attached to bin
dt_dust[ datetime > ymd_hm('2017-01-24 14:27') & datetime < ymd_hm('2017-01-24 14:37'), summary(pm)]

# mean in Room
dt_dust[ datetime > ymd_hm('2017-01-24 14:16') & datetime < ymd_hm('2017-01-24 14:26'), summary(pm)]

# mean in incubator mid-test
dt_dust[ datetime > ymd_hm('2017-01-24 16:59') & datetime < ymd_hm('2017-01-24 17:14'), summary(pm)]

# mean in bin post-test, no zero filter attached to bin (like air being pulled in through bin seals due to pressure drop from DT pumping)
dt_dust[ datetime > ymd_hm('2017-01-24 20:41') & datetime < ymd_hm('2017-01-24 20:51'), summary(pm)]
ggplot(dt_dust[ datetime > ymd_hm('2017-01-24 20:41') & datetime < ymd_hm('2017-01-24 20:51')], aes(x = datetime, y = pm)) + geom_point()

# mean in room post-testing -- things were getting very warm
dt_dust[ datetime > ymd_hm('2017-01-24 20:52') & datetime < ymd_hm('2017-01-24 21:02'), summary(pm)]