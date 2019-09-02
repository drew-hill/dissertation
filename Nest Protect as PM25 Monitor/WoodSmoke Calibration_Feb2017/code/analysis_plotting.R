library(data.table)
library(lubridate)
library(plyr)
library(ggplot2)
library(gridExtra)

# read in grav_and_temp_correction.R
source('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/code/grav_and_temp_correction.R')


## Adjsut dt_nest (and load, if necessary)
# dt_nest  <- fread('~/Box Sync/Nest - dissertation/2017 Calibrations/WoodSmoke Calibration_Feb2017/data/nests/nestData_TEMPadj.csv' )
# dt_nest[,datetime := ymd_hms(datetime)]
dt_nest[,device := as.factor(device)]
dt_nest[,led := as.factor(led)]

# adjust dt_dust
# dt_dust[, pm_dt := (pm_dtX + pm_dtY) / 2]


# create new plotting datasets
plotter1 <- merge(dt_nest, dt_dust, all.x = T, by = c('datetime'))

# rename variables for Prettiness
plotter1b <- rename(plotter1,c('datetime' = 'Time'))

# reshape
plotter <- melt(plotter1b, id.vars = c('Time','led','device'), measure.vars = c('mg_m3','pm_dtX','pm_dtY'))
plotter[variable == 'mg_m3', variable := device]
# drop extranneous DustTrak values
plotter <- plotter[!(device != 'epsilon' & variable == 'pm_dtX' | device != 'epsilon' & variable == 'pm_dtY')]
plotter[, device := NULL]
# rename
plotter[variable == 'alpha', variable := 'Nest Device Alpha']
plotter[variable == 'beta', variable := 'Nest Device Beta']
plotter[variable == 'epsilon', variable := 'Nest Device Epsilon']
plotter[variable == 'pm_dtX', variable := 'DustTrak No. 1']
plotter[variable == 'pm_dtY', variable := 'DustTrak No. 2']


# Identify sample periods
plotter[ Time > ymd_hms('2017-02-02 13:46:00') & Time < ymd_hms('2017-02-02 14:30:00'), period := 'High' ]
plotter[ Time > ymd_hms('2017-02-02 18:05:00') & Time < ymd_hms('2017-02-02 18:50:00'), period := 'Med-High' ]
plotter[ Time > ymd_hms('2017-02-02 14:48:00') & Time < ymd_hms('2017-02-02 15:15:00'), period := 'Med' ]
plotter[ Time > ymd_hms('2017-02-02 15:48:00') & Time < ymd_hms('2017-02-02 17:45:00'), period := 'Low' ]

# make time period for Entire sample by r-stacking 
plotter2 <-  copy(plotter)
plotter2[Time > ymd_hms('2017-02-02 13:02:00') & Time < ymd_hms('2017-02-02 20:00:00'), period := 'Entire Sample']
plotter <- rbind(plotter, plotter2)

# adjsute period order for aestehtics
plotter$period <- factor(plotter$period, levels = c("Entire Sample","High", "Med-High", "Med", "Low"))

# # get appropriate colors of interest -- colors are picked as equally spaced distances aroudn the color pallette
	# library(scales)
	# show_col(hue_pal()(3))

# all Device output
fig5 <- ggplot(plotter[!is.na(period) & led == 'ir' & Time > ymd_hms('2017-02-02 13:00:02') & Time < ymd_hms('2017-02-02 20:00:00') ]) + geom_line(aes(x = Time, y = value, colour = variable))   +
	labs( y = expression(PM[2.5]~Concentration~(mg/m^3)), x = expression(Time)) +
	theme_bw() + theme(plot.title = element_text(hjust = 0.5)) + facet_wrap(~period, ncol = 1,scale = 'free') + scale_colour_manual(name = 'Device', values = c('#F8766D','#00BA38','#619Cff','red','blue'), labels = c('alpha','beta','epsilon','DustTrak No. 1','DustTrak No. 2')) #+ ggtitle('Overlayed Nest Protect IR (smoothed & scaled) \nand DustTrak Output (roughly grav-adjusted)')

# save
ggsave(filename = '~/Box Sync/Dissertation/Nest Chapter/SSD Figures/Figure_5.tiff', plot = fig5, path = NULL, scale = 1, width = 6, height = 6, units = c("in"), dpi = 300)


## Correlation matrix for all devices
library(GGally)
	
	dt_corrmat <- copy(plotter[period == 'Entire Sample' & Time > ymd_hms('2017-02-02 13:00:02') & Time < ymd_hms('2017-02-02 20:00:00')])
	##Average into longer time frames
	# one-minute average IR
	dt_corrmat[, minute := round_date(Time, unit = "minutes")]
	dt_corrmat[ , avg_value := mean(value), by = c("led","variable", "minute")]
	dt_corrmat[ , c('value', 'period','Time') := NULL]
	dt_corrmat <- rename(dt_corrmat, c("minute"='Time'))

	dt_corrmat  <- unique(dt_corrmat)


	# cast into appropriate datatable
	dt_corrmat <- dcast(
		dt_corrmat,
		Time ~ variable + led,
		value.var = 'avg_value'
		)
	dt_corrmat <- rename(dt_corrmat, c("Nest Device Alpha_ir" = 'alpha_ir', "Nest Device Beta_ir" = 'beta_ir', 'Nest Device Epsilon_ir' = 'epsilon_ir','DustTrak No. 1_ir' = 'DustTrak1', 'DustTrak No. 2_ir' = 'DustTrak2',"Nest Device Alpha_blue" = 'alpha_blue', "Nest Device Beta_blue" = 'beta_blue', 'Nest Device Epsilon_blue' = 'epsilon_blue'))
	dt_corrmat[ , c('DustTrak No. 2_blue', 'DustTrak No. 1_blue') := NULL]




fig6 <- ggpairs(dt_corrmat[, !c('Time')], diag = 'blank', columnLabels = c('alpha\nblue', ' alpha\nIR', 'beta\nblue', ' beta\nIR', 'epsilon\nblue', ' epsilon\nIR', 'DustTrak\n1', 'DustTrak\n2')) +
	labs( y = expression(PM[2.5]~Concentration~(mg/m^3)), x = expression(PM[2.5]~Concentration~(mg/m^3))) +
	theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank())

# save
ggsave(filename = '~/Box Sync/Dissertation/Nest Chapter/SSD Figures/Figure_6.tiff', plot = fig6, path = NULL, scale = 1, width = 6, height = 6, units = c("in"), dpi = 300)


# # plot 1:1
# ggplot(plotter1[datetime > ymd_hms('2017-02-02 13:00:02') & datetime < ymd_hms('2017-02-02 20:00:00')]) + geom_point(aes(x = pm_dtY, y = mg_m3, colour = device)) + facet_wrap(~ led, nrow = 2, scales = 'free') + ggtitle('Nest Protect (raw) vs. DustTrak Output (roughly grav-adjusted), by Nest LED Type') + xlab('DustTrak Output (mg/m3), roughly grav-adjusted') + ylab("Nest Protect Output (raw)")+ theme(plot.title = element_text(hjust = 0.5))

# ggplot(plotter1[datetime > ymd_hms('2017-02-02 13:00:02') & datetime < ymd_hms('2017-02-02 20:00:00')]) + geom_point(aes(x = pm_dtY, y = volts, colour = device)) + facet_wrap(~ led, nrow = 2, scales = 'free') + ggtitle('Nest Protect (raw) vs. DustTrak Output\n (roughly grav-adjusted), by Nest LED Type') + xlab('DustTrak Output (mg/m3), roughly grav-adjusted') + ylab("Nest Protect Output (raw)")+ theme(plot.title = element_text(hjust = 0.5))




############ Summary
# ir (run "grav_and_temp_correction.R" file first)
summary(model_ai_dv)
summary(model_bi_dv)
summary(model_ei_dv)
# blue
summary(model_ab_dv)
summary(model_bb_dv)
summary(model_eb_dv)




############ Noise and Signal-to-Noise calculations


##### Limit of Detection and Sensitivity
# Zero period
	ggplot(dt_nest_z[posttest == 1], aes(x = datetime , y = mg_m3)) + geom_point() + facet_wrap(~ device + led, nrow = 3, scales = "free")  #+ geom_point()

	dt_nest_z[posttest == 1, mean(mg_m3), by = c('device','led')]
	dt_nest_z[posttest == 1, sd(mg_m3), by = c('device','led')]

# Zero period
	ggplot(dt_nest_z[posttest == 1], aes(x = datetime , y = volts_smoothed)) + geom_point() + facet_wrap(~ device + led, nrow = 3, scales = "free")  #+ geom_point()

	dt_nest_z[posttest == 1, mean(volts_smoothed), by = c('device','led')]
	dt_nest_z[posttest == 1, sd(volts_smoothed), by = c('device','led')]	