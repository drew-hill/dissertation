/* 
  MODIFIED July 2016 by Drew Hill at UC Berkeley FROM:
      ADS1115_sample.c - 12/9/2013. Written by David Purdie as part of the openlabtools initiative
      Initiates and reads a single sample from the ADS1115 (without error handling)
*/
#include <stdio.h>
#include <fcntl.h>     // open
#include <inttypes.h>  // uint8_t, etc
#include <linux/i2c-dev.h> // I2C bus definitions

// int main()
// {
//   return 0;
// }

int read_ads() {
    
  int ADS_address = 0x48;   // Address of our device on the I2C bus
  int I2CFile;
  
  uint8_t writeBuf[3];      // Buffer to store the 3 bytes that we write to the I2C device
  uint8_t readBuf[2];       // 2 byte buffer to store the data read from the I2C device
  
  int16_t val;              // Stores the 16 bit value of our ADC conversion
  
  I2CFile = open("/dev/i2c-1", O_RDWR);     // Open the I2C device for reading and writing
  
  ioctl(I2CFile, I2C_SLAVE, ADS_address);   // Specify the address of the I2C Slave to communicate with
      
  // These three bytes are written to the ADS1115 to set the config register and start a conversion 
  // Differential (A0-A1), gain = 4, non-continuous, 860sps, disaple comparator and grounded ADDR pin
  writeBuf[0] = 1;          // This sets the pointer register so that the following two bytes write to the config register
  writeBuf[1] =	0x87;		    // This sets the 8 MSBs of the config register (bits 15-8) to 10000111; for gain of 1: writeBuf[1] = 0x83; // 10000011     
  writeBuf[2] = 0xE3;       // This sets the 8 LSBs of the config register (bits 7-0) to  11100011
  
  // Initialize the buffer used to read data from the ADS1115 to 0
  readBuf[0]= 0;        
  readBuf[1]= 0;
      
  // Write writeBuf to the ADS1115, the 3 specifies the number of bytes we are writing,
  // this begins a single conversion
  write(I2CFile, writeBuf, 3);  

  // Wait for the conversion to complete, this requires bit 15 to change from 0->1
  while ((readBuf[0] & 0x80) == 0)  // readBuf[0] contains 8 MSBs of config register, AND with 10000000 to select bit 15
  {
      read(I2CFile, readBuf, 2);    // Read the config register into readBuf
  }

  writeBuf[0] = 0;                  // Set pointer register to 0 to read from the conversion register
  write(I2CFile, writeBuf, 1);
  
  read(I2CFile, readBuf, 2);        // Read the contents of the conversion register into readBuf

  val = readBuf[0] << 8 | readBuf[1];   // Combine the two bytes of readBuf into a single 16 bit result 
  
  printf("%.4f",(float)val);    // Print the result to terminal, first convert from binary value to mV
        
  close(I2CFile);
  
  return 0;

}


