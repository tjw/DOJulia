#import <DOJuliaShared/types.h>

extern const unsigned int OWJuliaNoCycle;

unsigned int OWJuliaFindCycleLength(quaternion *orbit, iteration len, double precisionSquared);
unsigned int OWJuliaFindCycle(quaternion *orbit, iteration len, double oDelta);
