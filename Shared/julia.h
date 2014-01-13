
#import "OWJuliaContext.h"
#import "quaternion.hxx"

#define RADIUS      100000.0

dem_label       juliaLabel(const OWJuliaContext *context, quaternion *orbit);
dem_label       juliaLabelWithDistance(const OWJuliaContext *context, quaternion *orbit);

// These version do not compute distance and are optimized for either rotation
// or non-rotation case.
dem_label       juliaLabelNoRotation(const OWJuliaContext *context, quaternion *orbit);
dem_label       juliaLabelRotation(const OWJuliaContext *context, quaternion *orbit);

double          juliaPotential(const OWJuliaContext *context, quaternion *orbit);

static inline double clipToRange(double value, double bottom, double top)
{
    if (value < bottom)
	return bottom;
    else if (value > top)
	return top;
    else
	return value;
}
