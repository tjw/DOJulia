extern "C" {
#import <ansi/stdio.h>
}

#define TIMER
#ifdef TIMER
#warning Timer code enabled!

#import <OmniTimer/OmniTimerNode.H>
OmniTimerNode tileTimer(@"Total Tile Time", NULL);
OmniTimerNode juliaTimer(@"Julia Label Timer", &tileTimer);
#endif

#import <DOJuliaShared/types.h>
#import <DOJuliaShared/line.hxx>
#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/julia.h>
#import <DOJuliaShared/OWJuliaNormalApproximation.h>
#import <DOJuliaShared/OWJuliaColoringMethods.h>

#import "tile.h"
#import "makeImage.h"


color_t         clear  = {0, 0, 0, 0};
color_t         smoke  = {0, 0, 0, 128};

color_t         white  = {255, 255, 255, 255};
color_t         black  = {0, 0, 0, 255};
color_t         ltgrey = {169, 171, 171, 255};
color_t         dkgrey = {86, 86, 86, 255};
color_t         red    = {255, 0, 0, 255};

static unsigned int basinMissCount = 0;  // number of times the basin couldn't be determined

static INLINE double ipow(double x, unsigned int i)
{
    double                      result = x;

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
static INLINE void setColor(color_t *result, color_t *base, double mag)
{
  /* make a color from it */
  result->r = (unsigned char) (mag * base->r);
  result->g = (unsigned char) (mag * base->g);
  result->b = (unsigned char) (mag * base->b);
  result->a = base->a;
}

/* 0 is totally transparent */
static INLINE void compositeColor(color_t *back, color_t *front)
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
static INLINE void hsiToColor(double h, double s, double i, color_t *c)
{
    NSColor *result;

#warning This probably could not be any slower
    result = [NSColor colorWithCalibratedHue: h saturation: s brightness: i alpha: 1.0];
    c->r = (unsigned char) (255 * [result redComponent]);
    c->g = (unsigned char) (255 * [result greenComponent]);
    c->b = (unsigned char) (255 * [result blueComponent]);
}

#define PLANE_DEWOOGLY_FACTOR (0.0000001)
static INLINE BOOL isNegativePlane(plane_t *plane, const quaternion &point)
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

static plane_t *findNegativeClippingPlane(OWJuliaContext *context, const quaternion &point)
{
    unsigned int                count;
    plane_t                    *plane;

    count = context->numberOfPlanes;
    while (count--) {
	plane = &context->planes[count];
	if (plane->clips && isNegativePlane(plane, point))
	    return plane;
    }
    return NULL;
}

static BOOL lineIntersectsWithPlane(plane_t *plane, line *line, quaternion *intersection)
{
    double                      mvv, vo, vd;

    if (fabs(vd = plane->normal.dot(line->direction)) < PLANE_DEWOOGLY_FACTOR)
	return NO;

    vo = plane->normal.dot(line->origin);
    mvv = plane->dist * plane->normal.dot(plane->normal);

    *intersection = line->quaternionAtDistance((mvv - vo) / vd);
    return YES;
}

static plane_t *makePointNonNegative(OWJuliaContext *context, quaternion *point, line *line)
{
    unsigned int                count;
    plane_t                    *lastPlaneHit = NULL, *plane;

    count = context->numberOfPlanes;
    while (count--) {
	plane = &context->planes[count];
        if (plane->clips && isNegativePlane(plane, *point)) {
            if (lineIntersectsWithPlane(plane, line, point))
		lastPlaneHit = plane;
	}
    }
    return lastPlaneHit;
}

typedef struct {
    BOOL       didHit;       // YES iff the ray hit an object
    color_t    color;        // the color of the object that was hit (the background color on a miss)
    quaternion intersection; // the point at which the intersection occured (point far away on a miss)
} rayResult_t;


#warning Try this optimization
// Should keep a list of unbounding spheres that cover the last ray.  This way, for each step
// along the ray can first check if we are still in one of the unbounding spheres.  If so,
// we just step to the far intersection (and then see if we are in the next unbounding sphere).
// Once we get outside the spheres, we are either in the set, or the ray has moved enough
// that we need to cache new unbounding spheres.  It seems likely that it will be almost as
// fast to simple discard all unbounding spheres past that point on the ray (since they should
// be smaller if we are indeed going to hit the object).  Care must be taken to correctly
// process the case in which he have a near pass -- that is, the last *un*bounding sphere puts
// us outside of the *bounding* spehere.

static void castRay(OWJuliaContext *context, quaternion *orbit, rayResult_t *result)
{
    dem_label                   label;
    plane_t                    *plane;

    /*
     * If we start out on the negative side of any planes, jump up to the
     * intersection of the ray and the plane 
     */
    plane = makePointNonNegative(context, orbit, &context->m.ray);
    
    /* step along the ray until we hit a surface or go out of the clipping bubble */

    do {
        plane_t *negativePlane;

        negativePlane = findNegativeClippingPlane(context, *orbit);
        if (orbit->magnitudeSquared() >= context->clippingBubble || negativePlane) {
            // missed
            result->didHit       = NO;
            result->color        = context->background;
            result->intersection = orbit[0]; // dunno if there is a useful value for this or not yet
            return;
	}

#ifdef TIMER
        juliaTimer.start();
#endif
        label = juliaLabelWithDistance(context, orbit);
#ifdef TIMER
        juliaTimer.stop();
#endif
        
	if (label == IN_SET) {
            unsigned int basinIndex;

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
                basinIndex = OWJuliaFindCycle(orbit, context->n, context->delta);
                if (basinIndex == OWJuliaNoCycle) {
                    basinMissCount++;
                    if (basinMissCount && !(basinMissCount % 100)) {
                        fprintf(stderr, "Undetermined basin count = %d\n", basinMissCount);
                    }
                } else {
                    result->didHit       = YES;
                    result->color        = context->cycleColors[basinIndex];
                    result->intersection = orbit[0];
                    return;
                }
            } else  {
                result->didHit       = YES;
                result->color        = white;
                result->intersection = orbit[0];
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
        *orbit -= context->m.ray.direction * max(context->delta, context->dist);
    } while (YES);
}



/*
 * Returns TRUE if the ray set by this will intersect the unbounding volume,
 * returns FALSE if it won't, so no points on the ray will need to be
 * evaluated. 
 */

static int setLineDestinationForScreenPoint(OWJuliaContext *context,
                                            double x, double y,
                                            quaternion *orbit)
{
    quaternion   xOffset, yOffset;
    double       xUnits, yUnits, b, c, r, tmp;
    quaternion   d, e;

    xUnits = ((double)x / (double)context->m.portWidth) * context->m.screenWidth;
    yUnits = ((double)y / (double)context->m.portHeight) * context->m.screenHeight;

    xOffset = context->m.basis[0] * xUnits;
    yOffset = context->m.basis[1] * yUnits;
    orbit[0] = context->m.lowerLeft + xOffset + yOffset;

    context->m.ray.setDirection(orbit[0]);

    if (orbit->magnitudeSquared() >= context->m.boundingRadius * context->m.boundingRadius) {
	/* Try to advance orbit so it's on surface of bounding volume. */
	d = context->m.ray.direction;
	e = context->m.ray.origin;
        r = context->m.boundingRadius;

	b = 2.0 * d.dot(e);
	c = e.dot(e) - r * r;

	tmp = b * b - 4.0 * c;
	if (tmp <= 0.0)
	    return 0;			    /* No intersection */

        orbit[0] = context->m.ray.quaternionAtDistance((-b + sqrt(tmp)) / 2.0);
    }
    
    return 1;
}

typedef struct {
	    double                      dist;
	    color_t                     color;
} planeIntersection_t;

static int compareByDistance(const void *a, const void *b)
{
    const planeIntersection_t  *intersection1 = a;
    const planeIntersection_t  *intersection2 = b;

    if (intersection1->dist < intersection2->dist)
	return -1;
    else if (intersection1->dist > intersection2->dist)
	return 1;
    else
	return 0;
}


static void makeRay(OWJuliaContext *context,
                    double xOffset, double yOffset,
                    NSRect tileRect, tile_t *tile, quaternion *orbit,
                    rayResult_t *result)
{

    if (setLineDestinationForScreenPoint(context,
					 xOffset + tileRect.origin.x,
					 yOffset + tileRect.origin.y,
                                         orbit)) {
        result->didHit       = NO;
        result->color        = context->background;
        result->intersection = orbit[0];  // dunno if this is useful
    }

    castRay(context, orbit, result);

#if 0 // this is the old version ... most of this stuff is disabled for now
    color_t                     baseColor;
    dem_label                   label;
    double                      mag = 0.0;

    label = NOT_CLOSE;
    if (setLineDestinationForScreenPoint(context,
                                         xOffset + tileRect.origin.x,
                                         yOffset + tileRect.origin.y,
                                         orbit))
        mag = castRay(context, orbit, &label);

    /* Set up the base color */
    switch (label) {
    case IN_SET:
	 /* Color by basin */ {
	    unsigned int                basinIndex;

	    basinIndex = OWJuliaFindCycle(orbit, context->n, context->delta);
	    if (basinIndex == OWJuliaNoCycle || basinIndex >= context->maxCycleColor)
		baseColor = black;
	    else
		setColor(&baseColor, &context->cycleColors[basinIndex], mag);
	}
	break;
    case NOT_CLOSE:
        /* Color with background */
	baseColor = context->background;
	break;
    default:
        /* Color with surface color */
	setColor(&baseColor, &white, mag);
	break;
    }

    /* Add on any colors for intersection with transparent planes */
    {
	unsigned int                planeIndex, intersectionCount = 0;
        quaternion                  intersection, baseOrbit = *orbit;
	planeIntersection_t         planeIntersections[context->numberOfPlanes + 1];

	for (planeIndex = 0; planeIndex < context->numberOfPlanes; planeIndex++) {
	    if (!context->planes[planeIndex].clips &&
		lineIntersectsWithPlane(&context->planes[planeIndex], &context->m.ray,
					&intersection)) {
                planeIntersections[intersectionCount].dist = context->m.ray.origin.distanceSquared(intersection);

		/* Now we need to find the distance from the set of the intersection point */
		*orbit = intersection;
                juliaLabelWithDistance(context, orbit);

		if (context->dist > 0.0) {
		    double y;

		    y = ipow(1.0 / (context->dist + 1.0), context->exteriorColorTightness);
		    /*printf("ipow(%g,%d) = %g\n", context->dist, context->exteriorColorTightness, y);*/

		    hsiToColor(y, 1.0, 1.0,
			       &planeIntersections[intersectionCount].color);

#warning Should have another parameter for this		    
		    y = ipow(1.0 / (context->dist + 1.0), context->exteriorColorTightness / 2);
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
	    planeIntersections[intersectionCount].dist = context->m.ray.origin.distanceSquared(baseOrbit);
	    intersectionCount++;

	    qsort(planeIntersections, intersectionCount, sizeof(planeIntersection_t), compareByDistance);

	    while(intersectionCount--)
		compositeColor(&baseColor, &planeIntersections[intersectionCount].color);
	}
    }

    return baseColor;
#endif
    
}

extern int juliaCalls, juliaIterations;

void makeTile(OWJuliaContext *context, NSRect tileRect, tile_t *tile, quaternion *orbit)
{
    double        xOffset, yOffset;
    rayResult_t  *bottomCorners, *topCorners, *tmp;
    unsigned int  i, j;

#ifdef TIMER
    tileTimer.start();
#endif

    // Determine the fixed attractor cycle for this set.
    {
        dem_label label;
        unsigned int cycleLength;
        
        orbit[0] = quaternion(0, 0, 0, 0);

        label = juliaLabel(context, orbit);
        if (label != IN_SET) {
            fprintf(stderr, "The point <0, 0, 0, 0> is not in the set.\n");
            return;
        }

        cycleLength = OWJuliaFindCycleLength(orbit, context->n, context->delta);
        if (cycleLength == OWJuliaNoCycle) {
            fprintf(stderr, "Couldn't determine the cycle length starting from <0, 0, 0, 0>\n");
            return;
        } else
            fprintf(stderr, "Cycle length = %d\n", cycleLength);
    }
    
#if 0
#warning Testing a single ray in the center of the image
    while (1)
        makeRay(context, tileRect.size.width/2.0, tileRect.size.height/2.0, tileRect, tile, orbit);
#endif

    /* For a N wide tile, we'll need N+1 samples */
    bottomCorners = NSZoneMalloc(NSDefaultMallocZone(), sizeof(*bottomCorners) * (unsigned int)(tileRect.size.width + 1));
    topCorners  = NSZoneMalloc(NSDefaultMallocZone(), sizeof(*topCorners) * (unsigned int)(tileRect.size.width + 1));

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

#warning Fix the antialiazing code
            // Should really have several cases for the various combinations of only three points
            // being 'hits'.  In each case, we could provide a better normal approximation.
            // When subdividing, many cases could end at the 3-hits base cases.  We could
            // maybe assume 75% opacity in these cases too.
            
            // This is a really lame average but this is just a testing step anyway
            if (!lowerLeft->didHit && !lowerRight->didHit && !upperLeft->didHit && !upperRight->didHit) {
                *pixel = context->background;
            } else {
                unsigned int r, g, b;
                quaternion eyeToLowerLeft, up, right;
                vector eyeToLowerLeftVector, upVector, rightVector, normal;
                double lightMagnitude;
                
                // Sum the color across the pixel
                r = lowerLeft->color.r + lowerRight->color.r + upperLeft->color.r + upperRight->color.r;
                g = lowerLeft->color.g + lowerRight->color.g + upperLeft->color.g + upperRight->color.g;
                b = lowerLeft->color.b + lowerRight->color.b + upperLeft->color.b + upperRight->color.b;

                // Build a pseudo gradient using the intersection points on the lowerLeft,
                // lowerRight and upperLeft corners.

                // the quaternion vector from lowerLeft to the eyepoint
                eyeToLowerLeft = (context->m.ray.origin - lowerLeft->intersection).normalized();

                // convert this quaternion vector to a vector in the basis for our three dimensional subspace
                eyeToLowerLeftVector = vector(eyeToLowerLeft.dot(context->m.basis[0]),
                                              eyeToLowerLeft.dot(context->m.basis[1]),
                                              eyeToLowerLeft.dot(context->m.basis[2])).normalized();
                                              
                // Convert the differences between lowerLeft and each of upperLeft and lowerRight
                // to vectors in our basis
                up = upperLeft->intersection - lowerLeft->intersection;
                upVector = vector(up.dot(context->m.basis[0]),
                                  up.dot(context->m.basis[1]),
                                  up.dot(context->m.basis[2])).normalized();
                right = lowerRight->intersection - lowerLeft->intersection;
                rightVector = vector(right.dot(context->m.basis[0]),
                                     right.dot(context->m.basis[1]),
                                     right.dot(context->m.basis[2])).normalized();

                // get the normal to the plane defined by upVector and rightVector
                normal = upVector.cross(rightVector);

                // dot the normal and the eye point to get the magnitude of the light source
                lightMagnitude = normal.dot(eyeToLowerLeftVector);


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

        printf("%d\n", j);
    }

    NSZoneFree(NSDefaultMallocZone(), topCorners);
    NSZoneFree(NSDefaultMallocZone(), bottomCorners);

#ifdef TIMER
    tileTimer.stop();
    tileTimer.reportResults();
#endif

    NSLog(@"julia calls = %d, julia iterations = %d, basinMissCount = %d", juliaCalls, juliaIterations, basinMissCount);
    juliaCalls = 0;
}

