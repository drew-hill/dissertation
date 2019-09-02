/* 
July 2016 by Drew Hill at UC Berkeley
Reads a single 13-bit sample from the mcp3304
NOT FAST ENOUGH TO READ NEST SENSOR OUTPUT


send to RPi with
  scp -r /Users/Lawson/Dropbox/Aerie/Nest\ Protect\ Teardown/c\ code/mcp3304/mcp_read.c lawson@192.168.29.102:~/Downloads

compile (in ~/Downloads directory) with 
  gcc -o test mcp_read.c -lwiringPi

transfer back from pi with
    scp lawson@192.168.29.102:~/Downloads/nest_datalog.txt  /Users/Lawson/Desktop/cloop.txt

*/
#include <stdarg.h>

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>

#include <wiringPi.h>
#include <wiringPiSPI.h>


// take care of conflict between WiringPi delay and bcm delay
#define delayMicroseconds bcm2835_delayMicroseconds
#include <bcm2835.h>
#undef delayMicroseconds



float read_mcp3304_adc(void)
{

    if (!bcm2835_init())
    {
        printf("bcm2835_init failed. Are you running as root??\n");
        return 1;
    }


    if (!bcm2835_spi_begin())
    {
      printf("bcm2835_spi_begin failed. Are you running as root??\n");
      return 1;
    }

    bcm2835_spi_setBitOrder(BCM2835_SPI_BIT_ORDER_MSBFIRST);  
    bcm2835_spi_setDataMode(BCM2835_SPI_MODE0);                   // The default - spi mode 0
    bcm2835_spi_setClockDivider(BCM2835_SPI_CLOCK_DIVIDER_256); // 1.6 MHz (max for MCP3304 = 2.1)
    bcm2835_spi_chipSelect(BCM2835_SPI_CS0);                      // The default - chip select 0
    bcm2835_spi_setChipSelectPolarity(BCM2835_SPI_CS0, LOW);      // chip select goes low during data transfer on MCP3304, so set this to low


    // Send a byte to the slave and simultaneously read a byte back from the slave
    // If you tie MISO to MOSI, you should read back what was sent
    
    // define three-element array of transfer bytes and read bytes
    char tbytes [3];
    char rbytes [3];

    // define the bytes in the buffer to be sent to the ADC via SPI
    tbytes[0] = 0b00001011;
    tbytes[1] = 0b10000000;
    tbytes[2] = 0b00000000;

    // send 3 bytes in the form of the tbytes buffer
    bcm2835_spi_transfernb(tbytes , rbytes, 3);
    

    bcm2835_spi_end();
    // bcm2835_close();  // dropped because i need bcm2835 open during the main function

    // ADAPTED from http://pi.gids.nl:81/adc/  
    char thing = 0x0F & rbytes[1];
    float adcValue = ( thing << 8) | rbytes[2];
    
    // printf("rbytes %d %d %d\n", rbytes[0], rbytes[1] ,rbytes[2]);
    // printf("ADC Value: %d\n" ,adcValue);

    return adcValue;

}  




int main(void)
{
  int ir_pin_in = 27;
  int ir_pin_out = 23;
  
  time_t timer;
  char time_buff[26]; //buffer for time object
  struct tm* tm_info;
  float adcValue;
  float adcValue1;
  float adcValue2;
  float adcValue3;
  
  FILE * pFile; //declare file
  char *FILENAME = "nest_c_test.txt";

// Following event-detection approach adapted from Mike McCauley's BCM2835 library

    if (!bcm2835_init())
        return 1;
    
    // Set IR led inpin to as input, and outpin to output
    bcm2835_gpio_fsel(ir_pin_in, BCM2835_GPIO_FSEL_INPT);
    bcm2835_gpio_fsel(ir_pin_out, BCM2835_GPIO_FSEL_OUTP);
    
    // Enable the detection of a rising edge
    bcm2835_gpio_aren(ir_pin_in);
   
   // while loop to detect edge rise, then perform functions
    while (1)
    {
        // if edge rises
        if (bcm2835_gpio_eds(ir_pin_in))
        {

            adcValue1 = read_mcp3304_adc();
            adcValue2 = read_mcp3304_adc();
            adcValue3 = read_mcp3304_adc();
            adcValue = (adcValue1 + adcValue2 + adcValue3) / 3;
            
            time (&timer);
            tm_info = localtime(&timer);
            strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);
            pFile = fopen(FILENAME, "a"); //open file to append
            fprintf( pFile, "ir, %s, %f\n", time_buff, adcValue);  // print to file
            fclose( pFile );

            bcm2835_gpio_write (ir_pin_out, HIGH);
            usleep(500000); // sleep for half a second to blink and avoid a gazillion readings
            bcm2835_gpio_write (ir_pin_out, LOW);

            // Now clear the eds flag by setting it to 1
            bcm2835_gpio_set_eds(ir_pin_in);
            
            // print results to terminal
            printf("ir, %s, %f\n", time_buff, adcValue);
        }

    }

    bcm2835_close();
    return 0;
}





// Without using the event-detection bcm function



// int main(void)
// {
//   int ir_pin_in = 27;
//   int ir_pin_out = 23;
  
//   time_t timer;
//   char time_buff[26]; //buffer for time object
//   struct tm* tm_info;
//   float adcValue;
//   float adcValue1;
//   float adcValue2;
//   float adcValue3;
  
//   FILE * pFile; //declare file
//   char *FILENAME = "nest_c_test.txt";

// // Following event-detection approach adapted from Mike McCauley's BCM2835 library

//     if (!bcm2835_init())
//         return 1;
    
//     // Set IR led inpin to as input, and outpin to output
//     bcm2835_gpio_fsel(ir_pin_in, BCM2835_GPIO_FSEL_INPT);
//     bcm2835_gpio_fsel(ir_pin_out, BCM2835_GPIO_FSEL_OUTP);

   
//    // while loop to detect edge rise, then perform functions
//     for(;;)
//     {
//         while ( bcm2835_gpio_lev(ir_pin_in) == 1 )
//         {

//             adcValue1 = read_mcp3304_adc();
//             adcValue2 = read_mcp3304_adc();
//             adcValue3 = read_mcp3304_adc();
//             adcValue = (adcValue1 + adcValue2 + adcValue3) / 3;
            
//             time (&timer);
//             tm_info = localtime(&timer);
//             strftime(time_buff, 26, "%Y-%m-%d %H:%M:%S", tm_info);
//             pFile = fopen(FILENAME, "a"); //open file to append
//             fprintf( pFile, "ir, %s, %f\n", time_buff, adcValue);  // print to file
//             fclose( pFile );

//             bcm2835_gpio_write (ir_pin_out, HIGH);
//             usleep(500000); // sleep for half a second to blink and avoid a gazillion readings
//             bcm2835_gpio_write (ir_pin_out, LOW);
            
//             // print results to terminal
//             printf("ir, %s, %f\n", time_buff, adcValue);
//         }
//     }

//     bcm2835_close();
//     return 0;
// }
