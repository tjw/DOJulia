#import "OWJuliaContext.h"
#import "types.h"

#import "matrix.hxx"
#import "quaternion.hxx"
#import "line.hxx"

class map {
public:
    quaternion basis[3];                 /* defines a unit */
    double screenWidth, screenHeight;    /* in 'units'     */
    double boundingRadius;               /* sphere holding set, in 'units' */
    line ray;                            /* eyePoint to curent point on screen */
    quaternion lowerLeft;                /* lower left hand corner of screen */
    unsigned int portWidth, portHeight;  /* in pixels */
    
    inline map() {
        
    };
    inline ~map() {
        
    }
};


#define _MAXDEV 0.0000001

