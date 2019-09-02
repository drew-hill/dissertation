/* 
   Dec 29, 2016 by L. Drew Hill at UC Berkeley

send to RPi with
  scp -r /Users/Lawson/Dropbox/Aerie/Nest\ Protect\ Teardown/c\ code/mcp3304/mcp_read.c lawson@192.168.29.102:~/Downloads

compile (in ~/Downloads directory) with:
  gcc -pthread -o adc_test adc_test.c -lpigpio

once in the appropriate directory (probably ~/NestC) launch with screen, sudo, and nice to set priority to -20 (gives max priority to these processes):
  screen sudo nice -n -20 ./mcp_read_pigpio

transfer back from pi with
	scp lawson@192.168.29.102:~/Downloads/nest_datalog.txt  /Users/Lawson/Desktop/cloop.txt


// Attributions:
	- System time syntax adapted from [http://stackoverflow.com/questions/3673226/how-to-print-time-in-format-2009-08-10-181754-811], answer by Hamid Nazari

	- Threading code informed by [http://stackoverflow.com/questions/3051009/c-run-two-functions-at-the-same-time], answers by Stephen and GManNickG

	- Code to interpret bytes read from ADC was adapted from [http://pi.gids.nl:81/adc/]

      - Code to print temperature (output from terminal command) adapted from [http://stackoverflow.com/questions/646241/c-run-a-system-command-and-get-output], answer by Steve Kemp & Uli Köhler

*/


#include <stdarg.h>
#include <pigpio.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <sched.h>
#include <pthread.h>
#include <wiringPi.h>


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
  static int result_buff[2];

  int h;

  
  // if (gpioInitialise() < 0) return 1;

  h = spiOpen(SPI_CHANNEL, SPI_SPEED, 0);

  txbyte_buff[0] = 0b00001011;
  txbyte_buff[1] = 0b10000000;
  txbyte_buff[2] = 0b00000000;

  txbyte_buff2[0] = 0b00001011;
  txbyte_buff2[1] = 0b10000000;
  txbyte_buff2[2] = 0b00000000;
   

  // read 1 (new method of experimentation - Jan 2017) -- don't ignore sign byte
  spiXfer(h, txbyte_buff, rxbyte_buff, 3);
  rxbyte_buff[1] = 00011111 & rxbyte_buff[1];
  result_buff[0] = ( rxbyte_buff[1] << 8) | rxbyte_buff[2];


  // read 2 - original (Dec 2017) -- ignore sign byte
  spiXfer(h, txbyte_buff2, rxbyte_buff2, 3);
  rxbyte_buff2[1] = 00001111 & rxbyte_buff2[1];
  result_buff[1] = ( rxbyte_buff2[1] << 8) | rxbyte_buff2[2];



  spiClose(h);
  // gpioTerminate();

  // printf("adc: %d\n", adcValue);

  return result_buff;
}


/* Main function to create, excute, and close threads for each LED ping function */
int main(void)
{
	time_t timer;
	char time_buff[26]; //buffer for time object
	struct tm* tm_info;
	unsigned int microseconds;
	int ir_pin_in = 27;
	int ir_pin_out = 23;
	float adcValue;
	float adcValue1;
	float adcValue2;
	float adcValue3;
	float adcValue4;
	float adcValue5;
	int *adcValue_buff;
	
	gpioInitialise();

	gpioSetMode(ir_pin_in, PI_INPUT);
	gpioSetMode(ir_pin_out, PI_OUTPUT);
	
	// read adc
	adcValue_buff = read_adc();
	adcValue1 = adcValue_buff[0];
	adcValue2 = adcValue_buff[1];
	// adcValue3 = adcValue_buff[2];
	// adcValue4 = adcValue_buff[3];
	// adcValue5 = adcValue_buff[4];
	// adcValue = (adcValue1 + adcValue2 + adcValue3 + adcValue4 + adcValue5) / 5;

    
    	// Print results to terminal -- NOTE: 'get_temp' has an inherent \n after... must go at end
   	 printf("ADC new vs. old: %.1f : %.1f\n", adcValue1, adcValue2);   
  

 	// Disengage GPIOs using PIGPIO syntax
  	gpioTerminate();
  
  return 0;
}