/* 
    V0.7
   Jan 18, 2017 by L. Drew Hill at UC Berkeley
   Updates: (from v0.5) converts sutructure from infinite "for" loops to interrupts to reduce CPU load and, thus, chances of failure

send to RPi with
  scp -r /Users/lawsonhill/Box\ Sync/Nest\ -\ dissertation/NestRead lawson@192.168.29.100:~

compile (in appriate directory) with:
  gcc -pthread -o mcp_read_pigpio mcp_read_pigpio_v0.c -lpigpio -l rt RPi_SHT1x_pigpio.c -lm




once in the appropriate directory (probably ~/NestC) launch with screen, sudo, and nice to set priority to -20 (gives max priority to these processes):
  screen sudo nice -n -20 ./mcp_read_pigpio

or set to autorun on startup by editng /etc/rc.local to include the following lines (above 'exit 0')
  screen nice -n -20 /home/lawson/NestC/mcp_read_pigpio

transfer back from pi with
  scp lawson@192.168.29.102:~/Downloads/nest_datalog.txt  /Users/Lawson/Desktop/cloop.txt


// Attributions:
  - System time syntax adapted from [http://stackoverflow.com/questions/3673226/how-to-print-time-in-format-2009-08-10-181754-811], answer by Hamid Nazari

  - Threading code informed by [http://stackoverflow.com/questions/3051009/c-run-two-functions-at-the-same-time], answers by Stephen and GManNickG

  - Code to interpret bytes read from ADC was adapted from [http://pi.gids.nl:81/adc/]

      - Code to print system temperature (output from terminal command) adapted from [http://stackoverflow.com/questions/646241/c-run-a-system-command-and-get-output], answer by Steve Kemp & Uli Köhler

      - Code to read RH and Temparture from SHT15 sensor modified from John Burns (www.john.geek.nz)

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
#include "RPi_SHT1x_pigpio.h"



/* DEFINE NAME OF LOG FILE */

#define FILENAME "/home/lawson/NestFiles/allc_test_18jan2017.txt"

/* ********************************* */




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

  // create result
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




/* while loop to ping MCP3304 (ADC) in response to Infrared LED firing */
void ir_read (int gpio, int level, unsigned int tick)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  unsigned int microseconds;
  int ir_pin_out = 23;
  
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
  float adcValue;
  int h;
  
  float temp;
  float rh;
  FILE *temp_comm; //declare popen file
  char systemp[15];

  FILE * file_out; //declare data output file


  gpioSetMode(ir_pin_out, PI_OUTPUT);
     

  /*Process is too fast, wait ~ 144 µs for PD signal to ramp up */
  // for(int i = 0; i <=  12000; i++ );        


  /* Read ADC */
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


  /* Read Sample Time */
  // important to get Blue and IR timing very close together; rh and temp do not need as much temporal precision
  time (&timer);
  tm_info = localtime(&timer);
  strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);


  /* Read temp and humidty from sht */
  temp = temp_read();
  rh = rh_read();


  /* read system temp*/
    // open system command pipe
  temp_comm = popen("/opt/vc/bin/vcgencmd measure_temp", "r");
    // get output of that system command, and read it to variable 'get_temp'
  fgets(systemp, sizeof(systemp)-1, temp_comm);


  // Make LED blink for 3/4 of a second -- wait half, sleep half
  gpioWrite(ir_pin_out, 1);
  for(int i = 0; i <=  40000000; i++ );  
  nanosleep((const struct timespec[]){{0, 500000000L}}, NULL); // sleep for half a second to blink      
  gpioWrite(ir_pin_out, 0);  


  // average 5 ADC readings
  adcValue = (result_buff[0] + result_buff[1] + result_buff[2] + result_buff[3] + result_buff[4]) / 5;


  // Print results to terminal -- NOTE: 'get_temp' has an inherent \n after... must go at end
  printf("ir, %s, %.1f, %.1f, %.1f, %s", time_buff, adcValue, temp, rh, systemp);   

  // Print results to file -- NOTE: 'get_temp' has an inherent \n after... must go at end
  file_out = fopen(FILENAME, "a"); //open file to append
  fprintf( file_out, "ir, %s, %.1f, %.1f, %.1f, %s", time_buff, adcValue, temp, rh, systemp);  // print to file
  fclose( file_out );
      
}    


/* while loop to ping MCP3304 (ADC) in response to Blue LED firing */
void blue_read (int gpio, int level, unsigned int tick)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  unsigned int microseconds;
  int blue_pin_out = 24;
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
  float adcValue;
  int h;

  FILE * file_out; //declare data output file

  gpioSetMode(blue_pin_out, PI_OUTPUT);


  /*Process is too fast, wait ~ 144 µs for PD signal to ramp up */
  // for(int i = 0; i <=  12000; i++ );        


  /* Read ADC */
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


  /* Read sample time */
  time (&timer);
  tm_info = localtime(&timer);
  strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);


  // average 5 ADC readings
  adcValue = (result_buff[0] + result_buff[1] + result_buff[2] + result_buff[3] + result_buff[4]) / 5;


  // Make LED blink for 3/4 of a second  -- wait half, sleep half
  gpioWrite(blue_pin_out, 1);
  for(int i = 0; i <=  40000000; i++ );  
  nanosleep((const struct timespec[]){{0, 500000000L}}, NULL); // sleep for half a second to blink      
  gpioWrite(blue_pin_out, 0);  

  // Print results to terminal -- NOTE: 'get_temp' has an inherent \n after... must go at end
  printf("blue, %s, %.1f, NA, NA, NA\n", time_buff, adcValue);   

  // Print results to file -- NOTE: 'get_temp' has an inherent \n after... must go at end
  file_out = fopen(FILENAME, "a"); //open file to append
  fprintf( file_out, "blue, %s, %.1f, NA, NA, NA\n", time_buff, adcValue);  // print to file
  fclose( file_out );

} 

void *looper (void *pString)
{
  /*KEEP THE PROGRAM ALIVE! */
  for (;;)
  {
    sleep(10);
  }
}



/* Main function to create, excute, and close threads for each LED ping function */
void main(void)
{

  pthread_t thread1;
  int sht_vcc_pin = 5;
  int ir_pin_in = 27;
  int blue_pin_in = 17;


  // Initialize GPIO pins with PIGPIO syntax
  gpioInitialise();


  /* Set Inputs */
  gpioSetMode(ir_pin_in, PI_INPUT);
  gpioSetMode(blue_pin_in, PI_INPUT);


  /* power cycle sht_vcc_pin just in case */
  // # open 3.3v power pin to power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
  gpioSetMode(sht_vcc_pin, PI_OUTPUT);
  gpioWrite(sht_vcc_pin, 0);
  sleep(1);
  gpioWrite(sht_vcc_pin, 1);


  /* Set Interrup for IR LED */
  gpioSetISRFunc( ir_pin_in, RISING_EDGE, -1, ir_read );


  /* Set Interrup for BLue LED */
  gpioSetISRFunc( blue_pin_in, RISING_EDGE, -1, blue_read );


  /* set up continuous looper to keep the program alive*/
  pthread_create(&thread1, NULL, looper,"Thread 1 - looper");
  

  /* Exit threads */
  pthread_join( thread1, NULL);
  exit(EXIT_SUCCESS);


  // Disengage GPIOs using PIGPIO syntax
  gpioTerminate();

}