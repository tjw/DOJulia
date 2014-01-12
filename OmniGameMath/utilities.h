extern "C" {
#import <Foundation/NSGeometry.h>
}


// This implements a modulus operator for positive and negative numbers.
// The normal C '%' operator is not defined for negative numbers
static inline void OGMFloorDivMod(int numerator, int denominator,
                                  int *floor, int *mod)
{
    //ASSERT(Denominator > 0);		// we assume it's positive

    if (numerator >= 0) {
        // positive case, C is okay
        *floor = numerator / denominator;
        *mod = numerator % denominator;
    } else {
        // Numerator is negative, do the right thing
        *floor = -((-numerator) / denominator);
        *mod = (-numerator) % denominator;
        if (*mod) {
            // there is a remainder
            *floor = *floor - 1;
            *mod = denominator - *mod;
        }
    }

    assert(*mod >= 0);
}

// The implements a divide operator that returns the closest
// integer, rather than the normal C semantics of '/' which is
// to round towards zero.  This works for both positive
// and negative numerators (the denominator must be positive)
static inline int OGMClosestDiv(int numerator, int denominator)
{
    int roundingFactor;
    
    assert(denominator > 0);

    roundingFactor = denominator/2;
    if (numerator < 0)
        roundingFactor = -roundingFactor;
    return (numerator + roundingFactor) / denominator;
}


static inline NSUInteger OGMRoundDown(NSUInteger i, NSUInteger m)
{
    if (i % m) {
	i += (i % m);
	i -= m;
    }
    return i;
}

static inline NSUInteger OGMRoundUp(NSUInteger i, NSUInteger m)
{
    if (i % m) {
	i -= (i % m);
	i += m;
    }
    return i;
}

static inline NSPoint OGMSnapPointUp(NSPoint aPoint, NSUInteger x, NSUInteger y)
{
    NSPoint                     newPoint;

    newPoint.x = OGMRoundUp(aPoint.x, x);
    newPoint.y = OGMRoundUp(aPoint.y, y);

    return newPoint;
}

static inline NSPoint OGMSnapPointDown(NSPoint aPoint, NSUInteger x, NSUInteger y)
{
    NSPoint                     newPoint;

    newPoint.x = OGMRoundDown(aPoint.x, x);
    newPoint.y = OGMRoundDown(aPoint.y, y);

    return newPoint;
}

static inline NSRect  OGMSnapRect(NSRect aRect, NSUInteger x, NSUInteger y)
{
    NSRect newRect;
    NSPoint upperRight;

    upperRight.x = aRect.origin.x + aRect.size.width;
    upperRight.y = aRect.origin.y + aRect.size.height;
    upperRight = OGMSnapPointUp(upperRight, x, y);

    newRect.origin = OGMSnapPointDown(aRect.origin, x, y);
    newRect.size.width = upperRight.x - newRect.origin.x;
    newRect.size.height = upperRight.y - newRect.origin.y;

    return newRect;
}
