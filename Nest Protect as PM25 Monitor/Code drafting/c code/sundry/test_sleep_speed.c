// attribute [http://stackoverflow.com/questions/16275444/how-to-print-time-difference-in-accuracy-of-milliseconds-and-nanoseconds]


// NOTE!! Under strain, the RPi will double in speed; these times will be halved

#include <stdarg.h>
#include <unistd.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include <wiringPi.h>



void main(void)
{
        struct timespec tstart={0,0}, tend={0,0};
        clock_gettime(CLOCK_MONOTONIC, &tstart);
        
        // one nanosecond... about 120 µs
        // nanosleep((const struct timespec[]){{0, 1L}}, NULL);  

        // one microsecond... about 120µs
        // usleep(1);

        // one microsecond -- wiringPi ... between ~ 20 - 75 µs
        // delayMicroseconds(1);

        // 10000 clock ticks... about 118 µsec and very consistent
        // for(int i = 0; i <=  10000; i++ );    
        
        //  // 1000 clock ticks... about 12 µsec and very consistent
        // for(int i = 0; i <=  1000; i++ );    
         
        //8000 clock ticks... about 94 µsec and very consistent
        for(int i = 0; i <=  12000; i++ );    

        clock_gettime(CLOCK_MONOTONIC, &tend);
        printf("some_long_computation took about %.6f seconds\n",
           ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
           ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));
}