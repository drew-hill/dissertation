/* 
infinite for loop for use with Nest Protect pm gizmos 
written by Drew Hill at UC Berkeley, July 2016
*/

#include <stdio.h> 	// used for printf() statements
#include <wiringPi.h>
#include <ads1115_read.h> // include the function for reading photodetector!

// define pins by broadcom chip number
const int ir_in_pin = 17;
const int ir_out_pin = 23;


int main() {
	wiringPiSetupGpio(); // initialize wiringPi

	pinMode(ir_in_pin, INPUT); 	// IR LED input
	pinMode(ir_out_pin, OUTPUT); // IR LED output

	printf("Nest PM program is running! Press CTRL+C to quit.\n")

	// infinite for loop:
	for(;;)
	{
		if (digitalRead(ir_in_pin))
		{

		}	
	}	

}

