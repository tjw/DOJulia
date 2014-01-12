extern "C" {
#import <ansi/limits.h>
#import <bsd/libc.h>
#import <stdio.h>
#import <OmniFoundation/assertions.h>
}

#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/types.h>
#import <DOJuliaShared/inline.h>

#import <OmniGameMath/matrix.hxx>
#import <OmniGameMath/quaternion.hxx>
#import <DOJuliaShared/line.hxx>

typedef struct _map {
    quaternion basis[3];                 /* defines a unit */
    double screenWidth, screenHeight;    /* in 'units'     */
    double boundingRadius;               /* sphere holding set, in 'units' */
    line ray;                            /* eyePoint to curent point on screen */
    quaternion lowerLeft;                /* lower left hand corner of screen */
    unsigned int portWidth, portHeight;  /* in pixels */
} map;


#define _MAXDEV 0.0000001

