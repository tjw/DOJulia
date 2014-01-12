extern "C" {
#import <ansi/math.h>
}

#import <DOJuliaShared/OWJuliaContext.h>
#import <OmniGameMath/quaternion.hxx>

#define RADIUS      100000.0

dem_label       juliaLabel(OWJuliaContext *context, quaternion *orbit);
dem_label       juliaLabelWithDistance(OWJuliaContext *context, quaternion *orbit);

// These version do not compute distance and are optimized for either rotation
// or non-rotation case.
dem_label       juliaLabelNoRotation(OWJuliaContext *context, quaternion *orbit);
dem_label       juliaLabelRotation(OWJuliaContext *context, quaternion *orbit);

double          juliaPotential(OWJuliaContext *context, quaternion *orbit);

static INLINE double clipToRange(double value, double bottom, double top)
{
    if (value < bottom)
	return bottom;
    else if (value > top)
	return top;
    else
	return value;
}
