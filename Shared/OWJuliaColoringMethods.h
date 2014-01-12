#import "types.h"

extern const iteration OWJuliaNoCycle;

iteration OWJuliaFindCycleLength(quaternion *orbit, iteration len, double precisionSquared);
iteration OWJuliaFindCycle(quaternion *orbit, iteration len, double oDelta);
