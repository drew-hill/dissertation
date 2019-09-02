/* 
   July 2016 by Drew Hill at UC Berkeley
    Reads a single 12-bit sample from the mcp3304

send to RPi with
  scp -r /Users/Lawson/Dropbox/Aerie/Nest\ Protect\ Teardown/c\ code/mcp3304/mcp_read.c lawson@192.168.29.102:~/Downloads

compile (in ~/Downloads directory) with:
  gcc -pthread -o mcp_read_pigpio mcp_read_pigpio.c -lpigpio

once in the appropriate directory (probably ~/NestC) launch with screen, sudo, and nice to set priority to -20 (gives max priority to these processes):
  screen sudo nice -n -20 ./mcp_read_pigpio

transfer back from pi with
	scp lawson@192.168.29.102:~/Downloads/nest_datalog.txt  /Users/Lawson/Desktop/cloop.txt

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


/* Global variables of the MCP3304 read code */
#define CS_MCP3304  8       // BCM_GPIO8

#define SPI_CHANNEL 0
#define SPI_SPEED   2100000 


int * read_adc()
// note that this returns a pointer to an array, since arrays are not returnable by C functions
{
  
  unsigned char txbyte_buff[3];
  unsigned char rxbyte_buff[3];
  unsigned char txbyte_buff2[3];
  unsigned char rxbyte_buff2[3];
  unsigned char txbyte_buff3[3];
  unsigned char rxbyte_buff3[3];
  static int result_buff[3];

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


  // read 1
      // ADAPTED from http://pi.gids.nl:81/adc/  
  spiXfer(h, txbyte_buff, rxbyte_buff, 3);
  rxbyte_buff[1] = 0x0F & rxbyte_buff[1];
  result_buff[0] = ( rxbyte_buff[1] << 8) | rxbyte_buff[2];

  // read 2
      // ADAPTED from http://pi.gids.nl:81/adc/  
  spiXfer(h, txbyte_buff2, rxbyte_buff2, 3);
  rxbyte_buff2[1] = 0x0F & rxbyte_buff2[1];
  result_buff[1] = ( rxbyte_buff2[1] << 8) | rxbyte_buff2[2];

  // read 3
      // ADAPTED from http://pi.gids.nl:81/adc/  
  spiXfer(h, txbyte_buff3, rxbyte_buff3, 3);
  rxbyte_buff3[1] = 0x0F & rxbyte_buff3[1];
  result_buff[2] = ( rxbyte_buff3[1] << 8) | rxbyte_buff3[2];


  spiClose(h);
  // gpioTerminate();

  // printf("adc: %d\n", adcValue);

  return result_buff;
}



int main(void)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  unsigned int microseconds;
  int ir_pin_in = 27;
  int blue_pin_in = 17;
  int blue_pin_out = 24;
  int ir_pin_out = 23;
  int sht_vcc_pin = 5;
  int sht_data_pin = 13; 
  int sht_sck_pin = 6;
  float adcValue;
  float adcValue1;
  float adcValue2;
  float adcValue3;
  int *adcValue_buff;
  
  FILE * file_out; //declare file
  char *FILENAME = "nest_c_testDec26.txt";


  // set gpios
  gpioInitialise();
  
  gpioSetMode(ir_pin_in, PI_INPUT);
  gpioSetMode(ir_pin_out, PI_OUTPUT);
   
   // while loop to detect edge rise, then perform functions
    for (;;)
    {
        // if ir in_pin goes high
        if (gpioRead(ir_pin_in) ==1)
        {

            // C is too fast, wait 30 µs to take reading
            usleep(30);

            // read adc
            adcValue_buff = read_adc();
            adcValue1 = adcValue_buff[0];
            adcValue2 = adcValue_buff[1];
            adcValue3 = adcValue_buff[2];
            adcValue = (adcValue1 + adcValue2 + adcValue3) / 3;
            
            // read sample time, then print results to file and terminal
            time (&timer);
            tm_info = localtime(&timer);
            strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);
            file_out = fopen(FILENAME, "a"); //open file to append
            fprintf( file_out, "ir, %s, %f\n", time_buff, adcValue);  // print to file
            fclose( file_out );

            // Make LED blink for half of a second
            gpioWrite(ir_pin_out, 1);
            usleep(500000); // sleep for half a second to blink and avoid a gazillion readings
            gpioWrite(ir_pin_out, 0);
            
            // print results to terminal
            printf("ir, %s, %f\n", time_buff, adcValue);
            
        }

    }

  gpioTerminate();
    return 0;
}