#!/usr/bin/env/python

# Read from SHT15 and RPi systemp (C) 
# L. Drew Hill, UC Berkeley December 30, 2016

# run with:
#	screen sudo python temp_read.py

# import appropriate packages
import wiringpi
import time
# import itertools
import datetime
from sht_sensor import Sht
import os

# define filename for output
FILENAME = "nest_templog.txt"

# setup wiringpi to read GPIO pins via the "physical" reference method (i.e. 1-40)
wiringpi.wiringPiSetupGpio()

# define RPi GPIO pins ("GPIO" pin reference system)
sht_vcc_pin = 5
sht_data_pin = 13 
sht_sck_pin = 6

# make sure sht15 sclk is set to low -- is required before power up
wiringpi.digitalWrite(sht_sck_pin, 0)
# power cycle sht_vcc_pin just in case
wiringpi.digitalWrite(sht_vcc_pin, 0)
time.sleep(3)
# open 3.3v power pin tow power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
wiringpi.pinMode(sht_vcc_pin, 1)
wiringpi.digitalWrite(sht_vcc_pin, 1)

# identify the SHT15's "sck" and "data" pins (using GPIO numbering, i..e the "_g" values), and VDD input voltage
sht = Sht(sht_sck_pin, sht_data_pin, voltage='3.5V')

# loop that takes exactly 1 second to execute
i = 0
start = time.time()
while True:
	i += 1
	# Read SHT temp and RH
	tempC = str(round(sht.read_t(),2))
	rh = str(round(sht.read_rh(),2))
	# Read datetime
	dt = '%s' % datetime.datetime.now()#.strftime("%Y-%m-%d %H:%M:%S")
	# Read tempC_pi			
	tempC_pi = os.popen('vcgencmd measure_temp').read()[5:9]
	# Write to file
	f = open(FILENAME, "a")
	f.write(dt +"," + tempC_pi + "," + tempC + "," + rh + "\n")	
	f.close()
	print(dt +"," + tempC_pi + "," + tempC + "," + rh)
	time.sleep( i - ( time.time() - start) )