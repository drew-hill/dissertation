// Compile with: gcc -pthread -o testSHT1x_pigpio -l rt testSHT1x_pigpio.c RPi_SHT1x_pigpio.c -lpigpio -lm


/*
A derivative of the testSHT1x library included in the:

            Raspberry Pi SHT1x communication library.
            Originally By:      John Burns (www.john.geek.nz)
            Date:    01 November 2012
            License: CC BY-SA v3.0 - http://creativecommons.org/licenses/by-sa/3.0/

                      This is a derivative work based on
                      Name: Nice Guy SHT11 library
                      By: Daesung Kim
                      Date: 04/04/2011
                      Source: http://www.theniceguy.net/2722
                      License: Unknown - Attempts have been made to contact the author (by John Burns)

Modified By: L. Drew Hill, UC Berkeley
Date: 17 January 2017
Modifications: 
  shift GPIO library from the BCM2835 C library to the pigpio C library
  produce code suitable for my thesis reearch on smart smoke detector sensors
  decrease resolution to 8/12 bit

*/


#include <pigpio.h>
#include <stdio.h>
#include "RPi_SHT1x_pigpio.h"



float * TempAndHumidity(void)
{
  unsigned char noError = 1; 
  static float temp_rh_buff[2]; 
  value humi_val,temp_val;
  
  
  // Wait at least 11ms after power-up (chapter 3.1)
  gpioDelay(20); 
  
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
      float temp;
      float rh;

	//Initialise the Raspberry Pi GPIO
	gpioInitialise();

      // power cycle sht_vcc_pin just in case
      // # open 3.3v power pin to power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
      gpioSetMode(5, PI_OUTPUT);
      gpioWrite(5, 0);
      sleep(1);
      gpioWrite(5, 1);
	
	temp_rh_value_buff = TempAndHumidity();
      temp = temp_rh_value_buff[0];
      rh = temp_rh_value_buff[1];

	printf("%.1f, %.1f\n, ", temp, rh);

      // Disengage GPIOs using PIGPIO syntax
      gpioTerminate();

}







/* original script simply modified to operate on my device via pigpio */

// void printTempAndHumidity(void)
// {
//   unsigned char noError = 1;  
//   value humi_val,temp_val;
  
  
//   // Wait at least 11ms after power-up (chapter 3.1)
//   gpioDelay(20); 
  
//   // Set up the SHT1x Data and Clock Pins
//   SHT1x_InitPins();
  
//   // Reset the SHT1x
//   SHT1x_Reset();
  
//   // Request Temperature measurement
//   noError = SHT1x_Measure_Start( SHT1xMeaT );
//   if (!noError) {
//     return;
//     }
    
//   // Read Temperature measurement
//   noError = SHT1x_Get_Measure_Value( (unsigned short int*) &temp_val.i );
//   if (!noError) {
//     return;
//     }

//   // Request Humidity Measurement
//   noError = SHT1x_Measure_Start( SHT1xMeaRh );
//   if (!noError) {
//     return;
//     }
    
//   // Read Humidity measurement
//   noError = SHT1x_Get_Measure_Value( (unsigned short int*) &humi_val.i );
//   if (!noError) {
//     return;
//     }

//   // Convert intergers to float and calculate true values
//   temp_val.f = (float)temp_val.i;
//   humi_val.f = (float)humi_val.i;
  
//   // Calculate Temperature and Humidity
//   SHT1x_Calc(&humi_val.f, &temp_val.f);

//   //Print the Temperature to the console
//   printf("Temperature: %0.2f%cC\n",temp_val.f,0x00B0);

//   //Print the Humidity to the console
//   printf("Humidity: %0.2f%%\n",humi_val.f);
//   //Calculate and print the Dew Point
//   float fDewPoint;
//   SHT1x_CalcDewpoint(humi_val.f ,temp_val.f, &fDewPoint);
//   printf("Dewpoint: %0.2f%cC\n",fDewPoint,0x00B0);

// }


// void main (void)
// {

//   //Initialise the Raspberry Pi GPIO
//   gpioInitialise();

//   sleep(1);

//   // power cycle sht_vcc_pin just in case
//   // # open 3.3v power pin to power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
//   gpioSetMode(RPI_GPIO_SHT1x_VCC, PI_OUTPUT);
//   gpioWrite(RPI_GPIO_SHT1x_VCC, 0);
//   sleep(1);
//   gpioWrite(RPI_GPIO_SHT1x_VCC, 1);
//   sleep(1);

//   printTempAndHumidity();

//   // Disengage GPIOs using PIGPIO syntax
//   gpioTerminate();

//   // return 0;
// }



