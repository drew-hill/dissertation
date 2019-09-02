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
#include <stdarg.h>

#include <pigpio.h>
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
  float adcValue = 0;
  float adcValue1 = 0;
  float adcValue2 = 0;
  float adcValue3 = 0;
  unsigned int microseconds;
  int ir_pin_in = 27;
  int blue_pin_in = 17;
  int blue_pin_out = 24;
  int ir_pin_out = 23;
  int sht_vcc_pin = 5;
  int sht_data_pin = 13; 
  int sht_sck_pin = 6;


  FILE * pFile; //declare file
  char *FILENAME = "nest_c_test.txt";

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

//   // make sure sht15 sclk is set to low -- is required before powerup
//   digitalWrite(sht_sck_pin, 0);
// // power cycle sht_vcc_pin just in case
//   digitalWrite(sht_vcc_pin, 0);
//   usleep(microseconds = 3000);
// // open 3.3v power pin tow power up sht15 temp and humidity sensor
//   pinMode(sht_vcc_pin, OUTPUT);
//   digitalWrite(sht_vcc_pin, 1);

  // Set Pin Modes
  pinMode(CS_MCP3304, OUTPUT);
  pinMode(ir_pin_in, INPUT);
  pinMode(blue_pin_in, INPUT);
  pinMode(ir_pin_out, OUTPUT);
  pinMode(blue_pin_out, OUTPUT);


// infinite for loop to keep program running
    // while loop to read IR pin


void readwrite_fxn (void)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  float adcValue = 0;
  float adcValue1 = 0;
  float adcValue2 = 0;
  float adcValue3 = 0;
  unsigned int microseconds;
  int ir_pin_in = 27;
  int blue_pin_in = 17;
  int blue_pin_out = 24;
  int ir_pin_out = 23;
  int sht_vcc_pin = 5;
  int sht_data_pin = 13; 
  int sht_sck_pin = 6;


  FILE * pFile; //declare file
  char *FILENAME = "nest_c_test.txt";


  adcValue1 = read_mcp3304_adc();
  adcValue2 = read_mcp3304_adc();
  adcValue3 = read_mcp3304_adc();
  adcValue = (adcValue1 + adcValue2 + adcValue3) / 3;
  time (&timer);
  tm_info = localtime(&timer);
  strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);
  pFile=fopen(FILENAME, "a"); //open file to append
  fprintf(pFile, "ir, %s, %f\n", time_buff, adcValue);  // print to file
  fclose(pFile);
  // printf("ir, %d, %s ", adcValue, time_buff);

  digitalWrite (ir_pin_out, 1);
  usleep(500); // sleep to avoid a gazillion readings
  digitalWrite (ir_pin_out, 0);
}




void edges(int gpio, int level, uint32_t tick)
{

   int g;

   if (g_reset_counts)
   {
      g_reset_counts = 0;
      for (g=0; g<MAX_GPIOS; g++) g_pulse_count[g] = 0;
   }

   /* only record low to high edges */
   if (level == 1) g_pulse_count[gpio]++;
}

int main(int argc, char *argv[])
{
   unsigned int microseconds;
   int ir_pin_in = 27;
   int blue_pin_in = 17;
   int blue_pin_out = 24;
   int ir_pin_out = 23;

   int i, rest, g, wave_id, mode;
   gpioPulse_t pulse[2];
   int count[MAX_GPIOS];

   /* command line parameters */

   rest = initOpts(argc, argv);

   /* get the gpios to monitor */

   g_num_gpios = 0;

   for (i=rest; i<argc; i++)
   {
      g = atoi(argv[i]);
      if ((g>=0) && (g<32))
      {
         g_gpio[g_num_gpios++] = g;
         g_mask |= (1<<g);
      }
      else fatal(1, "%d is not a valid g_gpio number\n", g);
   }

   if (!g_num_gpios) fatal(1, "At least one gpio must be specified");

   printf("Monitoring gpios");
   for (i=0; i<g_num_gpios; i++) printf(" %d", g_gpio[i]);
   printf("\nSample rate %d micros, refresh rate %d deciseconds\n",
      g_opt_s, g_opt_r);

   gpioCfgClock(g_opt_s, 1, 1);

   if (gpioInitialise()<0) return 1;

   gpioWaveClear();

   pulse[0].gpioOn  = g_mask;
   pulse[0].gpioOff = 0;
   pulse[0].usDelay = g_opt_p;

   pulse[1].gpioOn  = 0;
   pulse[1].gpioOff = g_mask;
   pulse[1].usDelay = g_opt_p;

   gpioWaveAddGeneric(2, pulse);

   wave_id = gpioWaveCreate();

   /* monitor g_gpio level changes */

   for (i=0; i<g_num_gpios; i++) gpioSetAlertFunc(g_gpio[i], edges);

   mode = PI_INPUT;

   if (g_opt_t)
   {
      gpioWaveTxSend(wave_id, PI_WAVE_MODE_REPEAT);
      mode = PI_OUTPUT;
   }

   for (i=0; i<g_num_gpios; i++) gpioSetMode(g_gpio[i], mode);

   while (1)
   {
      for (i=0; i<g_num_gpios; i++) count[i] = g_pulse_count[g_gpio[i]];

      g_reset_counts = 1;

      for (i=0; i<g_num_gpios; i++)
      {
         printf(" %d=%d", g_gpio[i], count[i]);
      }

      printf("\n");

      gpioDelay(g_opt_r * 100000);
   }

   gpioTerminate();
}