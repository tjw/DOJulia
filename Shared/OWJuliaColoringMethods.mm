extern "C" {
#import <stdio.h>
}


#import "OWJuliaColoringMethods.h"

#define PRINT

#ifdef PRINT
static BOOL print = NO;
#endif

const iteration OWJuliaNoCycle = (iteration)~0;

static inline int cmp(double a, double b)
{
    if (a < b)
	return -1;
    else if (a > b)
	return 1;
    else
	return 0;
}


iteration OWJuliaFindCycleLength(quaternion *orbit, iteration len, double precisionSquared)
{
    iteration  i;
    quaternion tmp;
    
    if (len <= 1)
        return OWJuliaNoCycle;

    /* find cycle length */
#ifdef PRINT
    if (print) {
        printf("find cycle len:\n");
        fflush(stdout);
    }
#endif

    for (i = len - 1; i > 0; i--) {
        double                      diff;

#ifdef PRINT
        if (print) {
            printf("%ld <%f, %f, %f, %f>", i, orbit[i].r, orbit[i].i, orbit[i].j, orbit[i].k);
        }
#endif
        tmp = orbit[len] - orbit[i];
        diff = tmp.magnitudeSquared();
#ifdef PRINT
        if (print)
            printf(" %.10f, %.10f\n", diff, precisionSquared);
#endif
        if (diff < precisionSquared)
            break;
    }
#ifdef PRINT
    if (print)
        fflush(stdout);
#endif


    if (i == 0)			/* no cycle, or at least, we don't trust it */
        return OWJuliaNoCycle;
    return len - i;
}

iteration OWJuliaFindCycle(quaternion *orbit, iteration len, double oDelta)
{
    iteration                   i, cycleLen, firstDelta, myBasin, basinZero;
    quaternion                  tmp;

    if (len <= 1)
	return OWJuliaNoCycle;

    len--;
    oDelta *= oDelta;

    cycleLen = OWJuliaFindCycleLength(orbit, len, oDelta);
    if (cycleLen == OWJuliaNoCycle)
        return cycleLen;
    
#ifdef PRINT
    if (print) {
        printf("cycleLen = %ld\n\n\n", cycleLen);
        fflush(stdout);

        for (i = len; i > len - cycleLen; i--) {
            printf("%ld <%f, %f, %f, %f>\n", i, orbit[i].r, orbit[i].i, orbit[i].j, orbit[i].k);
            fflush(stdout);
        }
    }
#endif

    /* find first point in orbit within oDelta of the last point in cycle */
    for (i = 0; i < len; i++) {
        tmp = orbit[len] - orbit[i];
	if (tmp.magnitudeSquared() < oDelta)
	    break;
    }
    firstDelta = i;

    /*
     * step back in orbit and cycle to find first point within delta of any
     * point on the cycle. 
     */
    for (i = 0; i < cycleLen; i++) {
        tmp = orbit[len - i] - orbit[firstDelta - i];
        if (tmp.magnitudeSquared() < oDelta)
	    break;
    }
    /* should be the fixed point for the basin containing orbit[0] */
    myBasin = firstDelta - i;

    /*
     * number the fixed points starting at zero for the one with the lowest r
     * coordinate (in case of tie use i, then j and k). 
     */
    basinZero = len;
    for (i = len - 1; i > len - cycleLen; i--) {
	int                         c;

	c = cmp(orbit[i].r, orbit[basinZero].r);
	if (c < 0)
	    basinZero = i;
	else if (c == 0) {
	    c = cmp(orbit[i].i, orbit[basinZero].i);
	    if (c < 0)
		basinZero = i;
	    else if (c == 0) {
		c = cmp(orbit[i].j, orbit[basinZero].j);
		if (c < 0)
		    basinZero = i;
		else if (c == 0) {
		    c = cmp(orbit[i].k, orbit[basinZero].k);
		    if (c < 0)
			basinZero = i;
		}
	    }
	}
    }

    /* return the offset from basinZero as the basin number */
    iteration ret = (basinZero < i) ? (basinZero - i) :
      (cycleLen - basinZero + i) % cycleLen;
#ifdef PRINT
    if (print) {
        printf("len:%ld first:%ld basin:%ld zero:%ld offset:%lu\n",
               cycleLen, firstDelta, myBasin, basinZero, ret);
        fflush(stdout);
    }
#endif
    return ret;
}

