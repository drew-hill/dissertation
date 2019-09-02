/* 
  MODIFIED July 2016 by Drew Hill at UC Berkeley FROM:
      ADS1115_sample.c - 12/9/2013. Written by David Purdie as part of the openlabtools initiative
      Initiates and reads a single sample from the ADS1115 (without error handling)
*/
#include <stdio.h>
#include "ads1115_read.c"

int main(void) {
  char result = read_ads();
  printf(result); //print float with 4 decimal places
}
 