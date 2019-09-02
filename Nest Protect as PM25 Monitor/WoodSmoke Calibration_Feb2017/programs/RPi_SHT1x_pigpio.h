/*
Raspberry Pi SHT1x communication library.
Originally By:      John Burns (www.john.geek.nz)
Date:    01 November 2012
License: CC BY-SA v3.0 - http://creativecommons.org/licenses/by-sa/3.0/

	This is a derivative work based on
	Name: Nice Guy SHT11 library
	By: Daesung Kim
	Date: 04/04/2011
	Source: http://www.theniceguy.net/2722
	License: Unknown - Attempts have been made to contact the author

Modified By: L. Drew Hill, UC Berkeley
Date: 17 January 2017
Modifications: shift GPIO library from the BCM2835 C library to the pigpio C library

*/



// Includes
#include <pigpio.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>

// Defines
// #define	TRUE	1
// #define	FALSE	0
#define SHT1x_DELAY gpioDelay(2)

// Define the Raspberry Pi GPIO Pins for the SHT1x
#define RPI_GPIO_SHT1x_SCK 6	// or GPIO 6 - for drew
#define RPI_GPIO_SHT1x_DATA 13	// or GPIO 13 - for drew
#define RPI_GPIO_SHT1x_VCC 5 	// or GPIO 5 - for drew


/* Macros to toggle port state of SCK and VCC lines. */
#define SHT1x_SCK_LO	gpioWrite(RPI_GPIO_SHT1x_SCK, 0)
#define SHT1x_SCK_HI	gpioWrite(RPI_GPIO_SHT1x_SCK, 1)
	// make Data pin go low, and toggle to "output" state
#define SHT1x_DATA_LO 	gpioWrite(RPI_GPIO_SHT1x_DATA, 0);\
						gpioSetMode(RPI_GPIO_SHT1x_DATA, PI_OUTPUT)
	// make data channel "input" type
#define	SHT1x_DATA_HI 	gpioSetMode(RPI_GPIO_SHT1x_DATA, PI_INPUT)
	// reads the current level on Data pin, and returns either HIGH or LOW. Works for either input or output pin types.
#define SHT1x_GET_BIT 	gpioRead(RPI_GPIO_SHT1x_DATA)

/* Definitions of all known SHT1x commands */
#define SHT1x_MEAS_T	0x03			// Start measuring of temperature. 0000 0000 0000 0011
#define SHT1x_MEAS_RH	0x05			// Start measuring of humidity. 0000 0000 0000 0101
#define SHT1x_STATUS_R	0x07			// Read status register. 0000 0000 0000 0111
#define SHT1x_STATUS_W	0x06			// Write status register. 0000 0000 0000 0110

#define SHT1x_RESET	0x1E			// Perform a sensor soft reset. 0000 0000 0001 1110

/* Enum to select between temperature and humidity measuring */
typedef enum _SHT1xMeasureType {
	SHT1xMeaT	= SHT1x_MEAS_T,		// Temperature
	SHT1xMeaRh	= SHT1x_MEAS_RH		// Humidity
} SHT1xMeasureType;

typedef union 
{
	unsigned short int i;
	float f;
} value;

/* Public Functions ----------------------------------------------------------- */
void SHT1x_Transmission_Start( void );
unsigned char SHT1x_Readbyte( unsigned char sendAck );
unsigned char SHT1x_Sendbyte( unsigned char value );
void SHT1x_InitPins( void );
unsigned char SHT1x_Measure_Start( SHT1xMeasureType type );
unsigned char SHT1x_Get_Measure_Value(unsigned short int * value );
void SHT1x_Reset();
unsigned char SHT1x_Mirrorbyte(unsigned char value);
void SHT1x_Xrc_check(unsigned char value);
void SHT1x_Calc(float *p_humidity ,float *p_temperature);
void SHT1x_CalcDewpoint(float fRH,float fTemp, float *fDP);