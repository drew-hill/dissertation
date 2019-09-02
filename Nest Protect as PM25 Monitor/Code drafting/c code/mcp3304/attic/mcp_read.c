/* 
   ADAPTED from http://pi.gids.nl:81/adc/, July 2016 by Drew Hill at UC Berkeley
      Reads a single 12-bit sample from the mcp3304 (no error handling)

send to RPi with
  scp -r /Users/Lawson/Dropbox/Aerie/Nest\ Protect\ Teardown/c\ code/mcp3304/mcp_read.c lawson@192.168.29.102:~/Downloads

compile (in ~/Downloads directory) with 
  gcc -o test mcp_read.c -lwiringPi

transfer back from pi with
	scp lawson@192.168.29.102:~/Downloads/nest_datalog.txt  /Users/Lawson/Desktop/cloop.txt

*/

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>

#include <wiringPi.h>
#include <wiringPiSPI.h>

/* Global variables of the MCP3304 read code */
#define CS_MCP3304  8       // BCM_GPIO8

#define SPI_CHANNEL 0
#define SPI_SPEED   200000 

int read_mcp3304_adc()
{
  unsigned char buff[3];
  int adcValue = 0;
  int ch = 7;

  buff[0] = 0b00001111;
  buff[1] = ch<<7;
  buff[2] = 0x00;

  digitalWrite(CS_MCP3304, 0);  // Low : CS Active

  wiringPiSPIDataRW(SPI_CHANNEL, buff, 3);

  buff[1] = 0x0F & buff[1];
  adcValue = ( buff[1] << 8) | buff[2];

  digitalWrite(CS_MCP3304, 1);  // High : CS Inactive

  return adcValue;
}


// Main read/write code

int main (void)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  int adcValue = 0;
  unsigned int microseconds;
  int ir_pin_in = 27;
  int blue_pin_in = 17;
  int blue_pin_out = 24;
  int ir_pin_out = 23;
  



  FILE * pFile; //declare file
  char *FILENAME = "nest_datalog.txt";

  // warnings

  if(wiringPiSetup() == -1)
  {
    fprintf (stdout, "Unable to start wiringPi: %s\n", strerror(errno));
    return 1 ;
  }

  if(wiringPiSPISetup(SPI_CHANNEL, SPI_SPEED) == -1)
  {
    fprintf (stdout, "wiringPiSPISetup Failed: %s\n", strerror(errno));
    return 1 ;
  }

  // Set Pin Modes
  pinMode(CS_MCP3304, OUTPUT);
  // pinMode(ir_pin_in, INPUT);
  // pinMode(ir_pin_out, OUTPUT);
  
  for (;;)
  {
    adcValue = read_mcp3304_adc();
    time (&timer);
    tm_info = localtime(&timer);
    strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);
    pFile=fopen(FILENAME, "a"); //open file to append
    fprintf(pFile, "ir, %s, %d\n", time_buff, adcValue);  // print to file
    fclose(pFile);
    // printf("ir, %d, %s ", adcValue, time_buff);
    // usleep(10); // sleep to avoid a gazillion readings
  }
  return 0;
}