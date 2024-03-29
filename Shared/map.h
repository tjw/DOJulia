#import "JuliaContext.h"
#import "types.h"

#import "matrix.hxx"
#import "quaternion.hxx"
#import "line.hxx"

class map {
private:
    // Disallow default constructor and copy
    map() {};
    map(const map &);
    
public:
    quaternion basis[3];                 /* defines a unit */
    double screenWidth, screenHeight;    /* in 'units'     */
    double boundingRadius;               /* sphere holding set, in 'units' */
    quaternion eyePoint;
    quaternion lowerLeft;                /* lower left hand corner of screen */
    NSUInteger portWidth, portHeight;  /* in pixels */
    
    static const map *makeMap(vector eye, double focusLength, double fov,
                              double rx, double ry, double rz, double scale,
                              double radius,
                              NSUInteger portWidth, NSUInteger portHeight);
    inline ~map() {
        
    }
    
    quaternion screenPoint(double screenX, double screenY) const;
};


#define _MAXDEV 0.0000001

