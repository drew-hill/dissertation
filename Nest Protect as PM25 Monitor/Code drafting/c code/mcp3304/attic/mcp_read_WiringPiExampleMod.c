/* 
   ADAPTED from WiringPi MCP3004 example, July 2016 by Drew Hill at UC Berkeley
      Reads a single 12-bit sample from the mcp3304 (no error handling)
*/
#include <stdio.h>
#include <inttypes.h>  // uint8_t, etc

#include <wiringPi.h>
#include <wiringPiSPI.h>


// int main()
// {
//   return 0;
// }

uint16_t main(struct wiringPiNodeStruct *node, int pin) 
{
  unsigned char spiData [3] ;
  unsigned char ch ;
  unsigned char chanBits ;
  int chan = pin - node-> pinBase;

  ch=7 ;
  chanBits = ch<<7 ; // shift channel down 7 bits to account for the 7 unknown bits in byte 2

  spiData [0] = 0b00001111 ;
  spiData [1] = ch<<7 ; 
  spiData [2] = 0 ; // "don't care" byte of 0

  wiringPiSPIDataRW ( node->fd, spiData, 3);

  return ((spiData [1] << 8) | spiData [2]) & 0x3FF; // return the two important bytes together
}




/*
 * mcp3004Setup:
 *	Create a new wiringPi device node for an mcp3004 on the Pi's
 *	SPI interface.
 *********************************************************************************
 */

int mcp3304Setup (const int pinBase, int spiChannel)
{
  struct wiringPiNodeStruct *node ;

  if (wiringPiSPISetup (spiChannel, 2000000) < 0)
    return FALSE ;

  node = wiringPiNewNode (pinBase, 8) ;

  node->fd         = spiChannel ;
  node->analogRead = main ;

  return TRUE ;
}