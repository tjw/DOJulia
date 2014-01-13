
#import "JuliaContext.h"
#import "quaternion.hxx"

#define RADIUS      100000.0

typedef struct {
    dem_label label;
    iteration n;
    double dist;
} julia_result;

julia_result juliaLabel(const JuliaContext *context, quaternion *orbit);
julia_result juliaLabelWithDistance(const JuliaContext *context, quaternion *orbit);

// These version do not compute distance and are optimized for either rotation
// or non-rotation case.
julia_result juliaLabelNoRotation(const JuliaContext *context, quaternion *orbit);
julia_result juliaLabelRotation(const JuliaContext *context, quaternion *orbit);

double juliaPotential(julia_result result, const quaternion *orbit);

static inline double clipToRange(double value, double bottom, double top)
{
    if (value < bottom)
	return bottom;
    else if (value > top)
	return top;
    else
	return value;
}
