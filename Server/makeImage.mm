
//#define TIMER
#ifdef TIMER
#warning Timer code enabled!

#import <OmniTimer/OmniTimerNode.H>
OmniTimerNode tileTimer(@"Total Tile Time", NULL);
OmniTimerNode juliaTimer(@"Julia Label Timer", &tileTimer);
#endif

#import "types.h"
#import "line.hxx"
#import "JuliaContext.h"
#import "julia.h"
#import "OWJuliaNormalApproximation.h"
#import "OWJuliaColoringMethods.h"
#import "map.h"
#import "tile.h"
#import "makeImage.h"


static const color_t clear  = {0, 0, 0, 0};
static const color_t smoke  = {0, 0, 0, 128};

const color_t white  = {255, 255, 255, 255};
const color_t black  = {0, 0, 0, 255};
const color_t ltgrey = {169, 171, 171, 255};
const color_t dkgrey = {86, 86, 86, 255};
static const color_t red    = {255, 0, 0, 255};

//static unsigned int basinMissCount = 0;  // number of times the basin couldn't be determined

static inline double ipow(double x, unsigned long i)
{
    double result = x;

    if (!i)
	return 1.0;
    i--;
    while (i) {
	if (i & 0x1) {
	    result *= x;
	    i ^= 0x1;
	} else {
	    result *= result;
	    i >>= 1;
	}
    }
    return result;
}

/* Use Lambertian shading, ka = 1.0, one light source at eye point */
static inline void setColor(color_t *result, const color_t *base, double mag)
{
  /* make a color from it */
  result->r = (unsigned char) (mag * base->r);
  result->g = (unsigned char) (mag * base->g);
  result->b = (unsigned char) (mag * base->b);
  result->a = base->a;
}

/* 0 is totally transparent */
static inline void compositeColor(color_t *back, const color_t *front)
{
    unsigned int                frontTransparency, newA;

    frontTransparency = 256 - front->a;

    back->r = (front->r * front->a + back->r * frontTransparency) / 256;
    back->g = (front->g * front->a + back->g * frontTransparency) / 256;
    back->b = (front->b * front->a + back->b * frontTransparency) / 256;
    newA = ((unsigned int)front->a + (unsigned int)back->a);
    if (newA > 255)
	newA = 255;
    back->a = newA;
}

#import <AppKit/AppKit.h>

/* Assumes 0.0 <= {h, s, i} <= 1.0 */
static inline void hsiToColor(double h, double s, double i, color_t *c)
{
    NSColor *result;

    // TODO: This probably could not be any slower
    result = [NSColor colorWithCalibratedHue: h saturation: s brightness: i alpha: 1.0];
    c->r = (unsigned char) (255 * [result redComponent]);
    c->g = (unsigned char) (255 * [result greenComponent]);
    c->b = (unsigned char) (255 * [result blueComponent]);
}

#define PLANE_DEWOOGLY_FACTOR (0.0000001)
static inline BOOL isNegativePlane(const plane_t *plane, const quaternion &point)
{
    quaternion difference;

    /*
     * Since there is a small amount of error with placing a point on the
     * negative side of a plane, we can't compare to zero here.  The number
     * we compare against was chosen by experimentation on what got rid of
     * the 'plane-woogliness' 
     */
    difference = (plane->normal * plane->dist) - point;

    
    return difference.dot(plane->normal) < -PLANE_DEWOOGLY_FACTOR;
}

static const plane_t *findNegativeClippingPlane(const JuliaContext *context, const quaternion &point)
{
    NSUInteger count = context->numberOfPlanes;
    while (count--) {
	const plane_t *plane = &context->planes[count];
	if (plane->clips && isNegativePlane(plane, point))
	    return plane;
    }
    return NULL;
}

static BOOL lineIntersectsWithPlane(const plane_t *plane, const line *line, quaternion *intersection)
{
    double mvv, vo, vd;

    if (fabs(vd = plane->normal.dot(line->direction)) < PLANE_DEWOOGLY_FACTOR)
	return NO;

    vo = plane->normal.dot(line->origin);
    mvv = plane->dist * plane->normal.dot(plane->normal);

    *intersection = line->quaternionAtDistance((mvv - vo) / vd);
    return YES;
}

#if 0
static const plane_t *makePointNonNegative(const JuliaContext *context, quaternion *point, const line *line)
{
    const plane_t *lastPlaneHit = NULL;

    NSUInteger count = context->numberOfPlanes;
    while (count--) {
	const plane_t *plane = &context->planes[count];
        if (plane->clips && isNegativePlane(plane, *point)) {
            if (lineIntersectsWithPlane(plane, line, point))
		lastPlaneHit = plane;
	}
    }
    return lastPlaneHit;
}
#endif

typedef struct {
    BOOL       didHit;       // YES iff the ray hit an object
    color_t    color;        // the color of the object that was hit (the background color on a miss)
    quaternion intersection; // the point at which the intersection occured (point far away on a miss)
    
    julia_result julia; // The result parameters from the hit point, if didHit is true.
} rayResult_t;


// TODO: Try this optimization
// Should keep a list of unbounding spheres that cover the last ray.  This way, for each step
// along the ray can first check if we are still in one of the unbounding spheres.  If so,
// we just step to the far intersection (and then see if we are in the next unbounding sphere).
// Once we get outside the spheres, we are either in the set, or the ray has moved enough
// that we need to cache new unbounding spheres.  It seems likely that it will be almost as
// fast to simple discard all unbounding spheres past that point on the ray (since they should
// be smaller if we are indeed going to hit the object).  Care must be taken to correctly
// process the case in which he have a near pass -- that is, the last *un*bounding sphere puts
// us outside of the *bounding* spehere.

static void castRay(const JuliaContext *context, line ray, quaternion *orbit, rayResult_t *rayResult)
{
    /*
     * If we start out on the negative side of any planes, jump up to the
     * intersection of the ray and the plane 
     */
//    const plane_t *plane = makePointNonNegative(context, orbit, &ray);
    
    /* step along the ray until we hit a surface or go out of the clipping bubble */

    do {
        const plane_t *negativePlane = findNegativeClippingPlane(context, *orbit);
        if (orbit->magnitudeSquared() >= context->clippingBubble || negativePlane) {
            // missed
            rayResult->didHit       = NO;
            rayResult->color        = context->background;
            rayResult->intersection = orbit[0]; // dunno if there is a useful value for this or not yet
            return;
	}

#ifdef TIMER
        juliaTimer.start();
#endif
        julia_result result = juliaLabelWithDistance(context, orbit);
#ifdef TIMER
        juliaTimer.stop();
#endif
        
	if (result.label == IN_SET) {
            iteration basinIndex;

#if 0
	    if (plane) {
                quaternion tmp, tmp2;

                tmp = *orbit - context->m.ray.origin;
                tmp = tmp.normalized();
                tmp2 = plane->normal.normalized();

                return fabs(tmp.dot(tmp2));
	    }
#endif
            

            if (context->colorByBasin) {
                basinIndex = OWJuliaFindCycle(orbit, result.n, context->delta);
                if (basinIndex == OWJuliaNoCycle) {
//                    basinMissCount++;
//                    if (basinMissCount && !(basinMissCount % 100)) {
//                        fprintf(stderr, "Undetermined basin count = %d\n", basinMissCount);
//                    }
                } else {
                    rayResult->didHit = YES;
                    rayResult->color = context->cycleColors[basinIndex];
                    rayResult->intersection = orbit[0];
                    rayResult->julia = result;
                    return;
                }
            } else  {
                rayResult->didHit = YES;
                rayResult->color = white;
                rayResult->intersection = orbit[0];
                rayResult->julia = result;
                return;
            }
        }
#if 0 // just keep stepping
        else if (context->dist < context->delta) {
            //mag = OWJuliaNormalDotApproximation(context, orbit);
            if (context->dist < 0.0)
                mag = 0.0;
            else if (context->dist > 1.0)
                mag = 1.0;
            else
                mag = pow(context->dist, 0.25);
	    return mag;
	}
#endif
        
        /* This sign here is really non-intuitive.  In fact, I think it is plain wrong, but it works */
        *orbit -= ray.direction * MAX(context->delta, result.dist);
    } while (YES);
}



/*
 * Returns TRUE if the ray set by this will intersect the unbounding volume,
 * returns FALSE if it won't, so no points on the ray will need to be
 * evaluated. 
 */

static int setLineDestinationForScreenPoint(const JuliaContext *context,
                                            line *ray,
                                            double x, double y,
                                            quaternion *orbit)
{
    const map *m = context->m;
    
    quaternion screenPoint = m->screenPoint(x, y);
    ray->origin = m->eyePoint;
    ray->setDirectionFromDestination(screenPoint);
    orbit[0] = screenPoint;
    
    if (orbit->magnitudeSquared() >= m->boundingRadius * m->boundingRadius) {
	/* Try to advance orbit so it's on surface of bounding volume. */
	quaternion d = ray->direction;
	quaternion e = ray->origin;
        double r = m->boundingRadius;

	double b = 2.0 * d.dot(e);
	double c = e.dot(e) - r * r;

	double tmp = b * b - 4.0 * c;
	if (tmp <= 0.0)
	    return 0;			    /* No intersection */

        orbit[0] = ray->quaternionAtDistance((-b + sqrt(tmp)) / 2.0);
    }
    
    return 1;
}

typedef struct {
	    double                      dist;
	    color_t                     color;
} planeIntersection_t;

static int compareByDistance(const void *a, const void *b)
{
    const planeIntersection_t *intersection1 = (const planeIntersection_t *)a;
    const planeIntersection_t *intersection2 = (const planeIntersection_t *)b;

    if (intersection1->dist < intersection2->dist)
	return -1;
    else if (intersection1->dist > intersection2->dist)
	return 1;
    else
	return 0;
}

static void makeRay(const JuliaContext *context,
                    double xOffset, double yOffset,
                    NSRect tileRect, ImageTile *tile, quaternion *orbit,
                    rayResult_t *result)
{
#if 0
    line ray;
    if (setLineDestinationForScreenPoint(context, &ray,
					 xOffset + tileRect.origin.x,
					 yOffset + tileRect.origin.y,
                                         orbit)) {
        result->didHit       = NO;
        result->color        = context->background;
        result->intersection = orbit[0];  // dunno if this is useful
    }

    //NSLog(@"Running ray %@", ray.toString());
    castRay(context, ray, orbit, result);
#else
    line ray;
    if (setLineDestinationForScreenPoint(context, &ray,
                                         xOffset + tileRect.origin.x,
                                         yOffset + tileRect.origin.y,
                                         orbit)) {
        result->didHit       = NO;
        result->color        = context->background;
        result->intersection = orbit[0];  // dunno if this is useful
    }
    castRay(context, ray, orbit, result);
    
    if (!result->didHit) {
        result->color = context->background;
        return;
    }
    
    /* Set up the base color */
    color_t baseColor;
    switch (result->julia.label) {
        case IN_SET: {
            /* Color by basin */
            if (context->colorByBasin) {
                iteration basinIndex = OWJuliaFindCycle(orbit, result->julia.n, context->delta);
                if (basinIndex == OWJuliaNoCycle || basinIndex >= context->maxCycleColor)
                    baseColor = black;
                else {
                    baseColor = context->cycleColors[basinIndex];
                }
            } else {
                /* Color with surface color */
                baseColor = white;
            }
        }
            break;
        case NOT_CLOSE:
            /* Color with background */
            baseColor = context->background;
            break;
        default:
            /* Color with surface color */
            baseColor = white;
            break;
    }
    
    /* Add on any colors for intersection with transparent planes */
    {
	unsigned int                planeIndex, intersectionCount = 0;
        quaternion                  intersection, baseOrbit = *orbit;
	planeIntersection_t         planeIntersections[context->numberOfPlanes + 1];

	for (planeIndex = 0; planeIndex < context->numberOfPlanes; planeIndex++) {
	    if (!context->planes[planeIndex].clips &&
		lineIntersectsWithPlane(&context->planes[planeIndex], &ray,
					&intersection)) {
                planeIntersections[intersectionCount].dist = ray.origin.distanceSquared(intersection);

		/* Now we need to find the distance from the set of the intersection point */
		*orbit = intersection;
                juliaLabelWithDistance(context, orbit);

		if (result->julia.dist > 0.0) {
		    double y;

		    y = ipow(1.0 / (result->julia.dist + 1.0), context->exteriorColorTightness);
		    /*printf("ipow(%g,%d) = %g\n", context->dist, context->exteriorColorTightness, y);*/

		    hsiToColor(y, 1.0, 1.0,
			       &planeIntersections[intersectionCount].color);

#warning Should have another parameter for this		    
		    y = ipow(1.0 / (result->julia.dist + 1.0), context->exteriorColorTightness / 2);
		    planeIntersections[intersectionCount].color.a =
		      (unsigned char)((context->planes[planeIndex].opacity * y) * 255);
		    /*printf("a(%g) = %d\n", y, planeIntersections[intersectionCount].color.a);*/
		} else
		    planeIntersections[intersectionCount].color = smoke;

		intersectionCount++;
	    }
	}

	if (intersectionCount) {
	    planeIntersections[intersectionCount].color = baseColor;
	    planeIntersections[intersectionCount].dist = ray.origin.distanceSquared(baseOrbit);
	    intersectionCount++;

	    qsort(planeIntersections, intersectionCount, sizeof(planeIntersection_t), compareByDistance);

	    while(intersectionCount--)
		compositeColor(&baseColor, &planeIntersections[intersectionCount].color);
	}
    }

    result->color = baseColor;
#endif
    
}

//extern int juliaCalls, juliaIterations;

void makeTile(const JuliaContext *context, NSRect tileRect, ImageTile *tile, quaternion *orbit)
{
    double        xOffset, yOffset;
    rayResult_t *tmp;
    unsigned int  i, j;

    const map *m = context->m;
    
#ifdef TIMER
    tileTimer.start();
#endif

    // Determine the fixed attractor cycle for this set.
    {
        orbit[0] = quaternion(0, 0, 0, 0);

        julia_result result = juliaLabel(context, orbit);
        if (result.label != IN_SET) {
            fprintf(stderr, "The point <0, 0, 0, 0> is not in the set.\n");
            return;
        }

        iteration cycleLength = OWJuliaFindCycleLength(orbit, result.n, context->delta);
        if (cycleLength == OWJuliaNoCycle) {
            fprintf(stderr, "Couldn't determine the cycle length starting from <0, 0, 0, 0>\n");
            return;
        } else {
            //fprintf(stderr, "Cycle length = %lu\n", cycleLength);
        }
    }
    
#if 0
#warning Testing a single ray in the center of the image
    while (1)
        makeRay(context, tileRect.size.width/2.0, tileRect.size.height/2.0, tileRect, tile, orbit);
#endif

    /* For a N wide tile, we'll need N+1 samples */
    rayResult_t *bottomCorners = (rayResult_t *)malloc(sizeof(*bottomCorners) * (unsigned int)(tileRect.size.width + 1));
    rayResult_t *topCorners  = (rayResult_t *)malloc(sizeof(*topCorners) * (unsigned int)(tileRect.size.width + 1));

    /* Fill out the first row */
    yOffset = -0.5;
    xOffset = -0.5;
    for (i = 0; i <= tileRect.size.width; i++) {
        makeRay(context, xOffset, yOffset, tileRect, tile, orbit, &bottomCorners[i]);
        xOffset += 1.0;
    }

    /* Now, fill out each successive row, swapping the bottomCorners and topCorners on each row. */
    for (j = 0; j < tileRect.size.height; j++) {
        // Setup the starting offset for this row
        yOffset =  0.5 + j;
        xOffset = -0.5;

        // Compute the colors of the corners on the top of this row
        for (i = 0; i <= tileRect.size.width; i++) {
            makeRay(context, xOffset, yOffset, tileRect, tile, orbit, &topCorners[i]);
            xOffset += 1.0;
        }

        // Now that we have all of the corners for this row, average the corner values
        // and fill in the pixels;
        for (i = 0; i < tileRect.size.width; i++) {
            rayResult_t *lowerLeft, *lowerRight, *upperLeft, *upperRight;
            color_t *pixel = tilePixel(tile, i, j);
            
            lowerLeft  = &bottomCorners[i];
            lowerRight = &bottomCorners[i+1];
            upperLeft  = &topCorners[i];
            upperRight = &topCorners[i+1];

            // TODO: Fix the antialiazing code
            // Should really have several cases for the various combinations of only three points
            // being 'hits'.  In each case, we could provide a better normal approximation.
            // When subdividing, many cases could end at the 3-hits base cases.  We could
            // maybe assume 75% opacity in these cases too.
            
            // This is a really lame average but this is just a testing step anyway
            if (!lowerLeft->didHit && !lowerRight->didHit && !upperLeft->didHit && !upperRight->didHit) {
                *pixel = context->background;
            } else {
                // Build a pseudo gradient using the intersection points on the lowerLeft,
                // lowerRight and upperLeft corners.

                // the quaternion vector from lowerLeft to the eyepoint
                quaternion eyeToLowerLeft = (m->eyePoint - lowerLeft->intersection).normalized();

                // convert this quaternion vector to a vector in the basis for our three dimensional subspace
                vector eyeToLowerLeftVector = vector(eyeToLowerLeft.dot(m->basis[0]),
                                                     eyeToLowerLeft.dot(m->basis[1]),
                                                     eyeToLowerLeft.dot(m->basis[2])).normalized();
                                              
                // Convert the differences between lowerLeft and each of upperLeft and lowerRight
                // to vectors in our basis
                quaternion up = upperLeft->intersection - lowerLeft->intersection;
                vector upVector = vector(up.dot(m->basis[0]),
                                         up.dot(m->basis[1]),
                                         up.dot(m->basis[2])).normalized();
                quaternion right = lowerRight->intersection - lowerLeft->intersection;
                vector rightVector = vector(right.dot(m->basis[0]),
                                            right.dot(m->basis[1]),
                                            right.dot(m->basis[2])).normalized();

                // get the normal to the plane defined by upVector and rightVector
                vector normal = upVector.cross(rightVector);

                // dot the normal and the eye point to get the magnitude of the light source
                double lightMagnitude = normal.dot(eyeToLowerLeftVector);

                // Sum the color across the pixel
                unsigned r = lowerLeft->color.r + lowerRight->color.r + upperLeft->color.r + upperRight->color.r;
                unsigned g = lowerLeft->color.g + lowerRight->color.g + upperLeft->color.g + upperRight->color.g;
                unsigned b = lowerLeft->color.b + lowerRight->color.b + upperLeft->color.b + upperRight->color.b;
                
                // Shade and average
                pixel->r = (unsigned int)(r * lightMagnitude) / 4;
                pixel->g = (unsigned int)(g * lightMagnitude) / 4;
                pixel->b = (unsigned int)(b * lightMagnitude) / 4;
                pixel->a = 255;
            }
        }

        // The top now becomes the bottom and the bottom can be used for the next top.
        tmp = topCorners;
        topCorners = bottomCorners;
        bottomCorners = tmp;

        //printf("j = %d\n", j);
    }

    NSZoneFree(NSDefaultMallocZone(), topCorners);
    NSZoneFree(NSDefaultMallocZone(), bottomCorners);

#ifdef TIMER
    tileTimer.stop();
    tileTimer.reportResults();
#endif

    //NSLog(@"julia calls = %d, julia iterations = %d, basinMissCount = %d", juliaCalls, juliaIterations, basinMissCount);
    //juliaCalls = 0;
}

