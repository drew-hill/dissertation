// Compile with:    gcc -pthread -o testSHT1x_pigpio -l rt testSHT1x_pigpio_18jan.c RPi_SHT1x_pigpio.c -lpigpio -lm


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

*/


#include <pigpio.h>
#include <stdio.h>
#include "RPi_SHT1x_pigpio.h"
#include <time.h>
#include <sched.h>
#include <pthread.h>
#include <stdarg.h>



float temp_read(void)
{
  unsigned char noError = 1; 
  float temp; 
  float filler = 0.0;
  value temp_val;
  
  
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

  // Convert intergers to float and calculate true values
  temp_val.f = (float)temp_val.i;
  
  // Calculate Temperature and Humidity
  SHT1x_Calc(&filler, &temp_val.f);

  // create result buffer
  temp = temp_val.f;

  return temp;
}


float rh_read(void)
{
  unsigned char noError = 1; 
  float rh;   
  float filler = 0.0;
  value humi_val;  
  
  // Wait at least 11ms after power-up (chapter 3.1)
  gpioDelay(20); 
  
  // Set up the SHT1x Data and Clock Pins
  SHT1x_InitPins();
  
  // Reset the SHT1x
  SHT1x_Reset();
  
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
  humi_val.f = (float)humi_val.i;
  
  // Calculate Temperature and Humidity
  SHT1x_Calc(&humi_val.f, &filler);

  // create result buffer
  rh = humi_val.f;

  return rh;
}




/* function to read the MCP3304 */
int * read_adc()
// note that this returns a pointer to an array, since arrays are not returnable by C functions
{
  
  int CS_MCP3304 = 8; // BCM_GPIO8
  int SPI_CHANNEL = 0;
  int SPI_SPEED = 2100000;

  unsigned char txbyte_buff[3];
  unsigned char rxbyte_buff[3];
  unsigned char txbyte_buff2[3];
  unsigned char rxbyte_buff2[3];
  unsigned char txbyte_buff3[3];
  unsigned char rxbyte_buff3[3];
  unsigned char txbyte_buff4[3];
  unsigned char rxbyte_buff4[3];
  unsigned char txbyte_buff5[3];
  unsigned char rxbyte_buff5[3];
  static int result_buff[5];

  int h;

  
  // if (gpioInitialise() < 0) return 1;

  h = spiOpen(SPI_CHANNEL, SPI_SPEED, 0);

  txbyte_buff[0] = 0b00001011;
  txbyte_buff[1] = 0b10000000;
  txbyte_buff[2] = 0b00000000;

  txbyte_buff2[0] = 0b00001011;
  txbyte_buff2[1] = 0b10000000;
  txbyte_buff2[2] = 0b00000000;

  txbyte_buff3[0] = 0b00001011;
  txbyte_buff3[1] = 0b10000000;
  txbyte_buff3[2] = 0b00000000;

  txbyte_buff4[0] = 0b00001011;
  txbyte_buff4[1] = 0b10000000;
  txbyte_buff4[2] = 0b00000000;

  txbyte_buff5[0] = 0b00001011;
  txbyte_buff5[1] = 0b10000000;
  txbyte_buff5[2] = 0b00000000;
   

  // read 1 - ignoring sign byte
  spiXfer(h, txbyte_buff, rxbyte_buff, 3);
  rxbyte_buff[1] = 0x0F & rxbyte_buff[1];
  result_buff[0] = ( rxbyte_buff[1] << 8) | rxbyte_buff[2];

  // read 2
  spiXfer(h, txbyte_buff2, rxbyte_buff2, 3);
  rxbyte_buff2[1] = 0x0F & rxbyte_buff2[1];
  result_buff[1] = ( rxbyte_buff2[1] << 8) | rxbyte_buff2[2];

  // read 3
  spiXfer(h, txbyte_buff3, rxbyte_buff3, 3);
  rxbyte_buff3[1] = 0x0F & rxbyte_buff3[1];
  result_buff[2] = ( rxbyte_buff3[1] << 8) | rxbyte_buff3[2];

  // read 3
  spiXfer(h, txbyte_buff4, rxbyte_buff4, 3);
  rxbyte_buff4[1] = 0x0F & rxbyte_buff4[1];
  result_buff[3] = ( rxbyte_buff4[1] << 8) | rxbyte_buff4[2];

  // read 3
  spiXfer(h, txbyte_buff5, rxbyte_buff5, 3);
  rxbyte_buff5[1] = 0x0F & rxbyte_buff5[1];
  result_buff[4] = ( rxbyte_buff5[1] << 8) | rxbyte_buff5[2];  



  spiClose(h);
  // gpioTerminate();

  // printf("adc: %d\n", adcValue);

  return result_buff;
}





void *main (void* pString)
{
      float temp;
      float rh;
      float adcValue;
      float adcValue1;
      float adcValue2;
      float adcValue3;
      float adcValue4;
      float adcValue5;
      int *adcValue_buff;
      FILE *temp_comm; //declare popen file
      char systemp[15];
      time_t timer;
      char time_buff[26]; //buffer for time object
      struct tm* tm_info;
      unsigned int microseconds;
      int ir_pin_in = 27;
      int ir_pin_out = 23;

	//Initialise the Raspberry Pi GPIO
	gpioInitialise();

      /* power cycle sht_vcc_pin just in case */
        // # open 3.3v power pin to power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
      gpioSetMode(5, PI_OUTPUT);
      gpioWrite(5, 0);
      sleep(1);
      gpioWrite(5, 1);


      // // C is too fast, wait ~ 144 µs to take reading
      // usleep(144);
      // nanosleep((const struct timespec[]){{0, 144000L}}, NULL);        
      // delayMicroseconds(144);
      for(int i = 0; i <=  12000; i++ );    


      // read adc
      adcValue_buff = read_adc();
	
      /* read temp and humidty from sht */
	temp = temp_read();
      rh = rh_read();

      /* read system temp*/
        // open system command pipe
      temp_comm = popen("/opt/vc/bin/vcgencmd measure_temp", "r");
        // get output of that system command, and read it to variable 'get_temp'
      fgets(systemp, sizeof(systemp)-1, temp_comm);

      // read sample time
      time (&timer);
      tm_info = localtime(&timer);
      strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);

      // average 5 ADC readings
      adcValue1 = adcValue_buff[0];
      adcValue2 = adcValue_buff[1];
      adcValue3 = adcValue_buff[2];
      adcValue4 = adcValue_buff[3];
      adcValue5 = adcValue_buff[4];
      adcValue = (adcValue1 + adcValue2 + adcValue3 + adcValue4 + adcValue5) / 5;     

      /* print : note that fgets forces a newline, so no '\n' required*/
	printf("ex, %s, %.1f, %.1f, %.1f,%s", time_buff, adcValue, temp, rh, systemp);

      /* Make LED blink for half of a second -- also triggers temperature reading */
      gpioWrite(ir_pin_out, 1);
      usleep(500000); // sleep for half a second to blink and avoid a gazillion readings
      gpioWrite(ir_pin_out, 0);

      // Disengage GPIOs using PIGPIO syntax
      gpioTerminate();

}