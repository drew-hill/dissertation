// Compile with: gcc -o testSHT1x -l rt testSHT1x.c RPi_SHT1x.c -l bcm2835 -lm


/*
Raspberry Pi SHT1x communication library.
By:      John Burns (www.john.geek.nz)
Date:    01 November 2012
License: CC BY-SA v3.0 - http://creativecommons.org/licenses/by-sa/3.0/

This is a derivative work based on
	Name: Nice Guy SHT11 library
	By: Daesung Kim
	Date: 04/04/2011
	Source: http://www.theniceguy.net/2722
	License: Unknown - Attempts have been made to contact the author

Dependencies:
	BCM2835 Raspberry Pi GPIO Library - http://www.open.com.au/mikem/bcm2835/

Sensor:
	Sensirion SHT11 Temperature and Humidity Sensor interfaced to Raspberry Pi GPIO port

SHT pins:
	1. GND  - Connected to GPIO Port P1-06 (Ground)
	2. DATA - Connected via a 10k pullup resistor to GPIO Port P1-01 (3V3 Power)
	2. DATA - Connected to GPIO Port P1-18 (GPIO 24)
	3. SCK  - Connected to GPIO Port P1-16 (GPIO 23)
	4. VDD  - Connected to GPIO Port P1-01 (3V3 Power)

Note:
	GPIO Pins can be changed in the Defines of RPi_SHT1x.h
*/

#include <bcm2835.h>
#include <stdio.h>
#include "RPi_SHT1x.h"

float * printTempAndHumidity(void)
{
  unsigned char noError = 1; 
  static float temp_rh_buff[2]; 
  value humi_val,temp_val;
  
  
  // Wait at least 11ms after power-up (chapter 3.1)
  delay(20); 
  
  // Set up the SHT1x Data and Clock Pins
  SHT1x_InitPins();
  
  // Reset the SHT1x
  SHT1x_Reset();
  
  // Request Temperature measurement
  noError = SHT1x_Measure_Start( SHT1xMeaT );
  if (!noError) {
    return 0;
    }
    
  // Read Temperature measurement
  noError = SHT1x_Get_Measure_Value( (unsigned short int*) &temp_val.i );
  if (!noError) {
    return 0;
    }

  // Request Humidity Measurement
  noError = SHT1x_Measure_Start( SHT1xMeaRh );
  if (!noError) {
    return 0;
    }
    
  // Read Humidity measurement
  noError = SHT1x_Get_Measure_Value( (unsigned short int*) &humi_val.i );
  if (!noError) {
    return 0;
    }

  // Convert intergers to float and calculate true values
  temp_val.f = (float)temp_val.i;
  humi_val.f = (float)humi_val.i;
  
  // Calculate Temperature and Humidity
  SHT1x_Calc(&humi_val.f, &temp_val.f);

  // create result buffer
  temp_rh_buff[0] = temp_val.f;
  temp_rh_buff[1] = humi_val.f;

  return temp_rh_buff;
}


void *main (void* pString)
{
	float *temp_rh_value_buff;

	//Initialise the Raspberry Pi GPIO
	if(!bcm2835_init())
		return 1;

	// power cycle sht_vcc_pin just in case
	// # open 3.3v power pin to power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
	bcm2835_gpio_write(RPI_GPIO_SHT1x_VCC, LOW);
	sleep(3);
	bcm2835_gpio_fsel(RPI_GPIO_SHT1x_VCC, BCM2835_GPIO_FSEL_OUTP);
	bcm2835_gpio_write(RPI_GPIO_SHT1x_VCC, HIGH);
	
	temp_rh_value_buff = printTempAndHumidity();

	printf("temp and rh, %.1f, %.1f\n", temp_rh_value_buff[0], temp_rh_value_buff[1]);
}
