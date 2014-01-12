/* JTController.m created by bungi on Sat 26-Apr-1997 */

extern "C" {
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSImage.h>
#import "JTController.h"
}

#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/OWJuliaColoringMethods.h>
#import <DOJuliaShared/julia.h>
#import <OmniGameMath/quaternion.hxx>

#define BOUNDARY_TRACKING_CENTER (BT_MAX_EDGE_SIZE / 2)
#define ORBIT                    ((quaternion *)orbit)
#define BOUNDARY_ZBUFFER         ((zbuffer *)boundaryZBuffer)

static inline quaternion quaternionForPoint(OWJuliaContext *context, BTPoint point, double scale)
{
    return
    context->m.basis[0] * (((double)point.x - BOUNDARY_TRACKING_CENTER) / scale) +
    context->m.basis[1] * (((double)point.y - BOUNDARY_TRACKING_CENTER) / scale) +
    context->m.basis[2] * (((double)point.z - BOUNDARY_TRACKING_CENTER) / scale);
}

static inline BTPoint pointForQuaternion(OWJuliaContext *context, quaternion q, double scale)
{
    BTPoint point;

    point.x = (unsigned int)(scale * q.dot(context->m.basis[0]) + BOUNDARY_TRACKING_CENTER);
    point.y = (unsigned int)(scale * q.dot(context->m.basis[1]) + BOUNDARY_TRACKING_CENTER);
    point.z = (unsigned int)(scale * q.dot(context->m.basis[2]) + BOUNDARY_TRACKING_CENTER);
        
    return point;
}

// This is a simple zbuffer class for use in producing images.
// Will need to move this code later.

class zbuffer {
    unsigned int  _width, _height;
    unsigned int *_depths;

    inline unsigned int *_depthPointer(unsigned int x, unsigned int y) {
        return _depths + (y * _width + x);
    }
        
public:

    inline zbuffer(unsigned int width, unsigned int height) {
        _width  = width;
        _height = height;
        _depths = (unsigned int *)NSZoneCalloc(NSDefaultMallocZone(), 1, sizeof(*_depths) * _width * _height);
    }

    inline ~zbuffer() {
        NSZoneFree(NSDefaultMallocZone(), _depths);
    }

    inline void setDepth(unsigned int x, unsigned int y, unsigned int depth) {
        unsigned int currentDepth;

        currentDepth = *_depthPointer(x, y);
        if (currentDepth < depth)
            *_depthPointer(x, y) = depth;
    }

    inline unsigned int depth(unsigned int x, unsigned int y) {
        return *_depthPointer(x, y);
    }
};


@implementation JTController

- (void) applicationDidFinishLaunching: (NSNotification *) notification;
{
}


#define JULIA


- (void) start: (id) sender;
{
    BTPoint      insidePoint;
    unsigned int cycleLength;
    
    BOUNDARY_ZBUFFER = new zbuffer(BT_MAX_EDGE_SIZE, BT_MAX_EDGE_SIZE);

#ifndef JULIA
    insidePoint.x = BOUNDARY_TRACKING_CENTER;
    insidePoint.y = BOUNDARY_TRACKING_CENTER;
    insidePoint.z = 10;
#else
    NSDictionary *contextDictionary;
    dem_label     label;
    BTPoint       point;
    
    contextDictionary = [[NSDictionary alloc] initWithContentsOfFile: @"template.julia"];

    scale = [[contextDictionary objectForKey: @"scaleStart"] doubleValue];
    
    context = [[OWJuliaContext alloc] initWithDictionary: contextDictionary frameNumber: 0];
    orbit = NSZoneMalloc(NSDefaultMallocZone(), sizeof(quaternion) * (context->N + 1));
    
    /* Find one of the attractors */
    ORBIT[0] = quaternion(0.0, 0.0, 0.0, 0.0);

    label = juliaLabel(context, ORBIT);
    if (label != IN_SET) {
        NSLog(@"The point <0, 0, 0, 0> is not in the set");
        return;
    }

    cycleLength = OWJuliaFindCycleLength(ORBIT, context->n, context->delta);
    if (cycleLength == OWJuliaNoCycle) {
        NSLog(@"Cannot determine the cycle length starting from <0, 0, 0, 0>.  "
              @"Iteration count may be too low or delta to low.");
        return;
    }

    basin = [[contextDictionary objectForKey: @"basin"] intValue] % cycleLength;

    NSLog(@"Tracking in basin %d", basin);
    
    /* This should map to one of the basins of attraction */
    insidePoint = pointForQuaternion(context, ORBIT[context->n - cycleLength + basin], scale);

    /* Make sure the rounding introduced by this didn't eject us from the set or even its current basin */
    ORBIT[0] = quaternionForPoint(context, insidePoint, scale);
    label = juliaLabel(context, ORBIT);
    if (label != IN_SET) {
        NSLog(@"Rounding error caused the basin to not be in the set");
        return;
    }

    unsigned int newBasin = OWJuliaFindCycle(ORBIT, context->N, context->delta);
    if (basin != newBasin) {
        NSLog(@"Rounding error caused the basin to change to %d", newBasin);
        basin = newBasin;
    }
    
    /* Now, find a boundary point, but moving in the +x direction until we are no longer in the set */
    point = insidePoint;
    do {
        insidePoint = point;
        point.x++;

        ORBIT[0] = quaternionForPoint(context, point, scale);
        label = juliaLabel(context, ORBIT);
    } while (label == IN_SET &&
             basin == OWJuliaFindCycle(ORBIT, context->N, context->delta));
#endif

    outputFile = fopen("/tmp/points.boundary", "w");
    
    /* The last inside point is on the boundary.  Add this to our starting set. */
    [self addBoundaryPoint: insidePoint];

    /* Start tracking! */
    [self processPoints];

    fclose(outputFile);
}

// Any point within a certain orthogonal distance is in the set
- (void) processPoints: (BTPoint *) points count: (unsigned int) count;
{
#ifndef JULIA
    while (count--) {

#define SQUARE_WIDTH (100)
        
        if (points->z == 10 &&
            points->x < BOUNDARY_TRACKING_CENTER + SQUARE_WIDTH && points->x > BOUNDARY_TRACKING_CENTER - SQUARE_WIDTH &&
            points->y < BOUNDARY_TRACKING_CENTER + SQUARE_WIDTH && points->y > BOUNDARY_TRACKING_CENTER - SQUARE_WIDTH)
            points->state = BTPointInside;
        else
            points->state = BTPointOutside;
            
        points++;
    }
#else
    while (count--) {
        dem_label label;
        
        ORBIT[0] = quaternionForPoint(context, *points, scale);

        label = juliaLabel(context, ORBIT);
        if (label == IN_SET &&
            OWJuliaFindCycle(ORBIT, context->N, context->delta) == basin)
            points->state = BTPointInside;
        else
            points->state = BTPointOutside;

        points++;
    }
#endif
}

#if 1

// This version just writes the points to the output file
- (void) processBoundaryPoints: (BTPoint *) points count: (unsigned int) count;
{
    if (fwrite(points, sizeof(BTPoint), count, outputFile) != count) {
        NSLog(@"Failed to write the requested points");
    }
}

#else

- (void) processBoundaryPoints: (BTPoint *) points count: (unsigned int) count;
{
    while (count--) {
        // Later we'll probably want to do some perspective
        BOUNDARY_ZBUFFER->setDepth(points->x, points->y, points->z);
        points++;
    }
}

- (void) processedBoundaryPoints;
{
    unsigned int      x, y;
    unsigned char    *imageBytes;

    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                       pixelsWide: BT_MAX_EDGE_SIZE
                                                       pixelsHigh: BT_MAX_EDGE_SIZE
                                                    bitsPerSample: 8
                                                  samplesPerPixel: 1
                                                         hasAlpha: NO
                                                         isPlanar: NO
                                                   colorSpaceName: NSCalibratedWhiteColorSpace
                                                      bytesPerRow: 0
                                                     bitsPerPixel: 0];

    image = [[NSImage alloc] initWithSize: NSMakeSize(BT_MAX_EDGE_SIZE, BT_MAX_EDGE_SIZE)];
    [image addRepresentation: imageRep];

    [imageView setFrameSize: [image size]];
    [imageView setImage: image];

    [imageRep release];
    [image release];
    
    imageBytes = [imageRep bitmapData];

    /*
     Compute an image by constructing a normal from the zbuffer.  Leave the edges alone
     to avoid having to deal with the the normal there.
     */

    vector toEye(0, 0, 1);
    
    for (y = 1; y < BT_MAX_EDGE_SIZE - 1; y++) {
        unsigned char *imageSpan;

        imageSpan = imageBytes + y * BT_MAX_EDGE_SIZE + 1;
        
        for (x = 1; x < BT_MAX_EDGE_SIZE - 1; x++) {
            unsigned int depth, upperDepth, rightDepth;
            vector       center, right, up, normal;
            double       lightMagnitude;
            
            depth      = BOUNDARY_ZBUFFER->depth(x, y);
            rightDepth = BOUNDARY_ZBUFFER->depth(x + 1, y);
            upperDepth = BOUNDARY_ZBUFFER->depth(x, y + 1);

            center = vector(0, 0, depth);
            right  = vector(1, 0, rightDepth) - center;
            up     = vector(0, 1, upperDepth) - center;

            if (center.z == 0 && up.z == 0 && right.z == 0) {
                // Don't bother doing the cross or normalization -- these are way slow
                lightMagnitude = 0.0;
            } else {
                right = right.normalized();
                up    = up.normalized();

                normal = up.cross(right);

                lightMagnitude = 1.0 - normal.dot(toEye);
            }

            *imageSpan = (unsigned char) (lightMagnitude * 255);
            imageSpan++;
        }
    }
         
    [imageView display];
    [[NSDPSContext currentContext] wait];
}
#endif

@end
