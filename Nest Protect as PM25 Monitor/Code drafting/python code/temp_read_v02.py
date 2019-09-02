#!/usr/bin/env/python



# v0.2 -- updates: now writes to separate file, repeats every 10 seconds more accurately

# Read from SHT15 and RPi systemp (C) 
# L. Drew Hill, UC Berkeley Jan 23, 2016

# run with:
#	screen sudo python temp_read.py

# import appropriate packages
import wiringpi
from time import sleep
# import itertools
import datetime
from sht_sensor import Sht
import os

# define filename for output
FILENAME = "/home/lawson/NestFiles/logtemprh_temp_calibration_24jan.txt"

# setup wiringpi to read GPIO pins via the "physical" reference method (i.e. 1-40)
wiringpi.wiringPiSetupGpio()

# define RPi GPIO pins ("GPIO" pin reference system)
sht_vcc_pin = 5
sht_data_pin = 13 
sht_sck_pin = 6
ir_pin_out = 23


# make sure sht15 sclk is set to low -- is required before power up
wiringpi.digitalWrite(sht_sck_pin, 0)
# power cycle sht_vcc_pin just in case
wiringpi.digitalWrite(sht_vcc_pin, 0)
sleep(3)
# open 3.3v power pin to power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
wiringpi.pinMode(sht_vcc_pin, 1)
wiringpi.digitalWrite(sht_vcc_pin, 1)

# identify the SHT15's "sck" and "data" pins (using GPIO numbering, i..e the "_g" values), and VDD input voltage
sht = Sht(sht_sck_pin, sht_data_pin, voltage='3.5V')


# print initial 
f = open(FILENAME, "a")
f.write("NA, NA, NA,NA\n")	
f.close()


# loop that takes exactly 1 second to execute
i = 0
while True:
	if wiringpi.digitalRead( ir_pin_out ) == 1:
		dt = datetime.datetime.now()
		while True:
			i += 1
			# Read SHT temp and RH
			dt_clk = datetime.datetime.now()
			dt_str = '%s' % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
			tempC = str(round(sht.read_t(),1))
			rh = str(round(sht.read_rh(),1))
			# Read tempC_pi			
			tempC_pi = os.popen('vcgencmd measure_temp').read()[5:9]			
			# Write to file
			f = open(FILENAME, "a")
			f.write( dt_str+ "," + tempC + "," + rh  + "," + tempC_pi + "\n")	
			f.close()
			print(dt_str+ "," + tempC + "," + rh  + "," + tempC_pi)
			# sleep for some amount of time that will not cause interference with file read/write
			sleep( 10 - 
				(  ( datetime.datetime.now() - dt ).total_seconds() - (10* (i-1)) ) 
				) 



			