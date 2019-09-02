/* 
   Dec 29, 2016 by L. Drew Hill at UC Berkeley

send to RPi with
  scp -r /Users/Lawson/Dropbox/Aerie/Nest\ Protect\ Teardown/c\ code/mcp3304/mcp_read.c lawson@192.168.29.102:~/Downloads

compile (in ~/Downloads directory) with:
  gcc -pthread -o mcp_read_pigpio mcp_read_pigpio.c -lpigpio -lwiringPi

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


// /* function to read the SHT15 temp and humidity sensor */
// int read_sht(){

// // Identify important GPIO pins for SHT15
// int sht_vcc_pin = 5;
// int sht_data_pin = 13; 
// int sht_sck_pin = 6;


// // gpioInitialise();
// // // make sure sht15 sck is set to low -- is required before power up
// // // power cycle sht_vcc_pin just in case
// // gpioSetMode(sht_vcc_pin, PI_INPUT);
// // gpioWrite(sht_vcc_pin, 0);
// // // sleep for 2 seconds
// // usleep(2000000);
// // // open 3.3v power pin tow power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
// // gpioWrite(sht_vcc_pin, 1);

// // identify the SHT15's "sck" and "data" pins (using GPIO numbering, i..e the "_g" values), and VDD input voltage
// sht = Sht(sht_sck_pin, sht_data_pin, voltage='3.5V');



// }






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
   

  // read 1
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



/* while loop to ping MCP3304 (ADC) in response to Infrared LED firing */
void *ir_loop (void* pString)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  unsigned int microseconds;
  int ir_pin_in = 27;
  int ir_pin_out = 23;
  int sht_vcc_pin = 5;
  int sht_data_pin = 13; 
  int sht_sck_pin = 6;
  float adcValue;
  float adcValue1;
  float adcValue2;
  float adcValue3;
  float adcValue4;
  float adcValue5;
  int *adcValue_buff;
  
  FILE * file_out; //declare data output file
  char *FILENAME = "nest_c_testDec29.txt";

  FILE *temp_comm; //declare popen file
  char get_temp[20];

  // set gpios
  // gpioInitialise();
  
  gpioSetMode(ir_pin_in, PI_INPUT);
  gpioSetMode(ir_pin_out, PI_OUTPUT);
   
   // while loop to detect edge rise, then perform functions
    for (;;)
    {
        // if ir in_pin goes high
        if (gpioRead(ir_pin_in) ==1)
        {

            // // C is too fast, wait 25 µs to take reading
            // nanosleep((const struct timespec[]){{0, 25000L}}, NULL);        
            // for(int i = 0; i <=  10000; i++ );        
            delayMicroseconds(25);

            // read adc
            adcValue_buff = read_adc();
            adcValue1 = adcValue_buff[0];
            adcValue2 = adcValue_buff[1];
            adcValue3 = adcValue_buff[2];
            adcValue4 = adcValue_buff[3];
            adcValue5 = adcValue_buff[4];
            adcValue = (adcValue1 + adcValue2 + adcValue3 + adcValue4 + adcValue5) / 5;
            
            // read system temp
              // open system command pipe
            temp_comm = popen("/opt/vc/bin/vcgencmd measure_temp", "r");
              // get output of that system command, and read it to variable 'get_temp'
            fgets(get_temp, sizeof(get_temp)-1, temp_comm);

            // read sample time
            time (&timer);
            tm_info = localtime(&timer);
            strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);

            // Print results to file -- NOTE: 'get_temp' has an inherent \n after... must go at end
            file_out = fopen(FILENAME, "a"); //open file to append
            fprintf( file_out, "ir, %s, %.01f, %s", time_buff, adcValue, get_temp);  // print to file
            fclose( file_out );

            // Make LED blink for half of a second
            gpioWrite(ir_pin_out, 1);
            nanosleep((const struct timespec[]){{0, 750000000L}}, NULL);         // sleep for half a second to blink and avoid a gazillion readings
            gpioWrite(ir_pin_out, 0);
            
            // Print results to terminal -- NOTE: 'get_temp' has an inherent \n after... must go at end
            printf("ir, %s, %.1f, %s", time_buff, adcValue, get_temp);   
            
        }
        else
        {
          // sleep for 1 nanosec to take some strain off of the CPU
          nanosleep((const struct timespec[]){{0, 1L}}, NULL);        
        }    
    }
} 



/* while loop to ping MCP3304 (ADC) in response to Blue LED firing */
void *blue_loop (void *pString)
{
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  unsigned int microseconds;
  int blue_pin_in = 17;
  int blue_pin_out = 24;
  int sht_vcc_pin = 5;
  int sht_data_pin = 13; 
  int sht_sck_pin = 6;
  float adcValue;
  float adcValue1;
  float adcValue2;
  float adcValue3;
  float adcValue4;
  float adcValue5;
  int *adcValue_buff;
  
  FILE * file_out; //declare data output file
  char *FILENAME = "nest_c_testDec29.txt";

  FILE *temp_comm; //declare popen file
  char get_temp[20];


  // set gpios
  // gpioInitialise();
  
  gpioSetMode(blue_pin_in, PI_INPUT);
  gpioSetMode(blue_pin_out, PI_OUTPUT);
   
   // while loop to detect edge rise, then perform functions
    for (;;)
    {
        // if ir in_pin goes high
        if (gpioRead(blue_pin_in) ==1)
        {

            // // C is too fast, wait 25 µs to take reading (25 µs at 1200 MHZ)
            // nanosleep((const struct timespec[]){{0, 25000L}}, NULL);
            // for(int i = 0; i <=  10000; i++ );        
            delayMicroseconds(25);

            // read adc
            adcValue_buff = read_adc();
            adcValue1 = adcValue_buff[0];
            adcValue2 = adcValue_buff[1];
            adcValue3 = adcValue_buff[2];
            adcValue4 = adcValue_buff[3];
            adcValue5 = adcValue_buff[4];
            adcValue = (adcValue1 + adcValue2 + adcValue3 + adcValue4 + adcValue5) / 5;
            
            // read system temp
              // open system command pipe
            temp_comm = popen("/opt/vc/bin/vcgencmd measure_temp", "r");
              // get output of that system command, and read it to variable 'get_temp'
            fgets(get_temp, sizeof(get_temp)-1, temp_comm);

            // read sample time
            time (&timer);
            tm_info = localtime(&timer);
            strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);

            // print results to file -- NOTE: 'get_temp' has an inherent \n after... must go at end
            file_out = fopen(FILENAME, "a"); //open file to append
            fprintf( file_out, "blue, %s, %.01f, %s", time_buff, adcValue, get_temp);  // print to file
            fclose( file_out );

            // Make LED blink for half of a second
            gpioWrite(blue_pin_out, 1);
            nanosleep((const struct timespec[]){{0, 750000000L}}, NULL);         // sleep for half a second to blink and avoid a gazillion readings
            gpioWrite(blue_pin_out, 0);

            // Print results to terminal -- NOTE: 'get_temp' has an inherent \n after... must go at end
            printf("blue, %s, %.1f, %s", time_buff, adcValue, get_temp);
            

        }
        else
        {
          // sleep for 1 µsec to take some strain off of the CPU
          nanosleep((const struct timespec[]){{0, 1L}}, NULL);        
        }       
    }
} 




/* Main function to create, excute, and close threads for each LED ping function */
int main(void)
{

  pthread_t thread1, thread2;
  int sht_vcc_pin = 5;

  // Initialize GPIO pins with PIGPIO syntax
  gpioInitialise();

  /* establish important items for SHT15 to operate */
      // make sure sht15 sck is set to low -- is required before power up
      // power cycle sht_vcc_pin just in case
  gpioSetMode(sht_vcc_pin, PI_INPUT);
  gpioWrite(sht_vcc_pin, 0);
      // sleep for 2 seconds
  usleep(2000000);
     // open 3.3v power pin tow power up sht15 temp and humidity sensor... using phyiscal pin values (no "_g")
  gpioWrite(sht_vcc_pin, 1);



  // Begin each thread
  pthread_create(&thread1, NULL, ir_loop,"Thread 1 - ir");
  pthread_create(&thread2, NULL, blue_loop, "Thread 2 - blue");

  // Exit threads
  pthread_join( thread1, NULL);
  pthread_join( thread2, NULL);
  exit(EXIT_SUCCESS);
  

  // Disengage GPIOs using PIGPIO syntax
  gpioTerminate();
  
  return 0;
}