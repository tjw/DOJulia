extern "C" {
#import <Foundation/NSPortCoder.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSColor.h>
}

#import <DOJuliaShared/OWEncoding.h>
#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/map.h>

#import <OmniGameMath/utilities.h>

static INLINE double degToRad(double deg)
{
    return (deg / 180.0) * M_PI;
}

static INLINE quaternion readQuaternion(NSDictionary *dict)
{
    double r, i, j, k;
    
    r = [[dict objectForKey:@"r"] doubleValue];
    i = [[dict objectForKey:@"i"] doubleValue];
    j = [[dict objectForKey:@"j"] doubleValue];
    k = [[dict objectForKey:@"k"] doubleValue];

    return quaternion(r, i, j, k);
}

static INLINE vector readVector(NSDictionary *dict)
{
    double x, y, z;
    
    x = [[dict objectForKey: @"x"] doubleValue];
    y = [[dict objectForKey: @"y"] doubleValue];
    z = [[dict objectForKey: @"z"] doubleValue];

    return vector(x, y, z);
}

static INLINE void readColor(NSDictionary *dict, color_t *c)
{
    c->r = (unsigned char)[[dict objectForKey: @"r"] intValue];
    c->g = (unsigned char)[[dict objectForKey: @"g"] intValue];
    c->b = (unsigned char)[[dict objectForKey: @"b"] intValue];
    c->a = (unsigned char)[[dict objectForKey: @"a"] intValue];
}

static INLINE double doubleValue(id object)
{
    // If you try to get a double by invoking a method on nil, you'll get NaN
    if (!object)
        return 0.0;
    else
        return [object doubleValue];
}


static void mapSet(map *m,
                   vector eye, double focusLength, double fov,
                   double rx, double ry, double rz, double scale,
                   double radius,
                   unsigned int portWidth, unsigned int portHeight)
{
    matrix          Rx, Ry, Rz, S, B;
    double          xWidth;

    ASSERT(focusLength > 0.0);
    ASSERT(fov > 0.0);
    ASSERT(radius > 0.0);
    
    /* Just some trivial parameters */
    m->boundingRadius = radius;
    m->portWidth = portWidth;
    m->portHeight = portHeight;

    /* Compute the composite rotation matrix for rx, ry, and rz */
    Rx.rotateX(rx);
    Ry.rotateY(ry);
    Rz.rotateZ(rz);

    S.scale(scale, scale, scale);
    
    B = S * Rx * Ry * Rz;

    /* Store quaternions used for advancing one unit along x, y, and z under the rotation matrix */
    vector b0, b1, b2;

    b0 = B * vector(1, 0, 0, 0);
    b1 = B * vector(0, 1, 0, 0);
    b2 = B * vector(0, 0, 1, 0);

    m->basis[0] = quaternion(b0.x, b0.y, b0.z, b0.w);
    m->basis[1] = quaternion(b1.x, b1.y, b1.z, b1.w);
    m->basis[2] = quaternion(b2.x, b2.y, b2.z, b2.w);
        
    /* Don't deal with the 'k' component here, this is done in the qrot() code */ 
    ASSERT(m->basis[0].k == 0.0);
    ASSERT(m->basis[1].k == 0.0);
    ASSERT(m->basis[2].k == 0.0);

    fprintf(stderr, "Basis is:\n");
    fprintf(stderr, "B[0] = (%4.8f, %4.8f, %4.8f, %4.8f)\n",
            m->basis[0].r, m->basis[0].i, m->basis[0].j, m->basis[0].k);
    fprintf(stderr, "B[1] = (%4.8f, %4.8f, %4.8f, %4.8f)\n",
            m->basis[1].r, m->basis[1].i, m->basis[1].j, m->basis[1].k);
    fprintf(stderr, "B[2] = (%4.8f, %4.8f, %4.8f, %4.8f)\n",
            m->basis[2].r, m->basis[2].i, m->basis[2].j, m->basis[2].k);


    /* Compute the width of the screen from the focusLength and fov */
    xWidth = tan(fov/2.0) * focusLength;

    /*
       Store the size of the screen in object space.  Set the height to be appropriate
       for a 1.0 aspect ratio.
     */
    m->screenWidth = xWidth;
    m->screenHeight = (xWidth * portHeight) / (double) portWidth;

    /* Store the origin of the eye ray */
    m->ray.origin = quaternion(eye.x, eye.y, eye.z, 0.0);

    /* Figure the lower left hand point of the screen as represented in object space */
    {
	quaternion zDist, center;
        quaternion right, top, cornerOffset;

        /* Go out focusLength units along the z basis vector to find the center of the screen */
        zDist = m->basis[2] * focusLength;     /* focusLength * <z> */
        center = m->ray.origin + zDist;        /* the center of the screen */

        /* Compute the offsets to the right-center and center-top points of the screen */
        right = m->basis[0] * (m->screenWidth / 2.0);
        top   = m->basis[1] * (m->screenHeight / 2.0);

	/* Add the two offsets to find the offset to the upper right corner */
        cornerOffset = right + top;

        /* Finally, subtract the upper-right offset from the center point to find the lower-left point */
        m->lowerLeft = center - cornerOffset;
    }
}


@implementation OWJuliaContext

- initWithDictionary: (NSDictionary *) aDictionary
         frameNumber: (unsigned int) aFrameNumber;
{
    [super init];
    {
	double                      focusLength, fov, scale;
        vector                      eyePoint;

	NSArray                    *orientation;

	orientation = [aDictionary objectForKey:@"orientation"];

	u = readQuaternion([aDictionary objectForKey:@"u"]);

        eyePoint = readVector([aDictionary objectForKey:@"eyePoint"]);
        focusLength = doubleValue([aDictionary objectForKey:@"focusLength"]);
        fov = degToRad(doubleValue([aDictionary objectForKey:@"fov"]));
        nc = [[aDictionary objectForKey:@"imageWidth"] intValue];
        nr = [[aDictionary objectForKey:@"imageHeight"] intValue];
        delta = doubleValue([aDictionary objectForKey:@"delta"]);

        // This screws stuff up
#if 0
        scale = doubleValue([aDictionary objectForKey: @"scaleStart"]) +
            doubleValue([aDictionary objectForKey: @"scaleStep"]) * aFrameNumber;
#else
        scale = 1.0;
#endif
        
        mapSet(&m, eyePoint, focusLength, fov,
               degToRad(doubleValue([orientation objectAtIndex:0])),
               degToRad(doubleValue([orientation objectAtIndex:1])),
               degToRad(doubleValue([orientation objectAtIndex:2])),
               scale, 4.0, nc, nr);
        delta *= m.screenWidth;

        rotation = degToRad(doubleValue([orientation objectAtIndex:3]));
        crot = cos(rotation);
        srot = sin(rotation);
        cnrot = cos(-rotation);
	snrot = sin(-rotation);
    }

    {
	NSArray                    *clippingPlanes;
	unsigned int                planeIndex;

	clippingPlanes = [aDictionary objectForKey:@"clippingPlanes"];
	if (!(numberOfPlanes = [clippingPlanes count]))
	    planes = NULL;
	else {

	    planes = (plane_t *) NSZoneMalloc(NSDefaultMallocZone(), (sizeof(plane_t) * numberOfPlanes));
	    for (planeIndex = 0; planeIndex < numberOfPlanes; planeIndex++) {
		NSDictionary               *planeDict;

		planeDict = [clippingPlanes objectAtIndex:planeIndex];
                planes[planeIndex].normal = readQuaternion([planeDict objectForKey:@"normal"]);
                planes[planeIndex].dist = doubleValue([planeDict objectForKey:@"dist"]);
                planes[planeIndex].opacity = doubleValue([planeDict objectForKey:@"opacity"]);
		planes[planeIndex].clips = [[planeDict objectForKey:@"clips"] intValue];
	    }
	}
    }

    {
	NSArray                    *cycleColorArray;
	unsigned int                cycleColorIndex;

	maxCycleColor = 0;
	cycleColors = NULL;
	if (colorByBasin = [[aDictionary objectForKey:@"colorByBasin"] intValue]) {
	    cycleColorArray = [aDictionary objectForKey:@"cycleColors"];
	    if ([cycleColorArray isKindOfClass:[NSArray class]]) {
		if ((maxCycleColor = [cycleColorArray count])) {
		    cycleColors = malloc(sizeof(color_t) * maxCycleColor);
		    for (cycleColorIndex = 0; cycleColorIndex < maxCycleColor; cycleColorIndex++)
			readColor([cycleColorArray objectAtIndex:cycleColorIndex],
				  &cycleColors[cycleColorIndex]);
		}
	    } else {
		unsigned int                cycleColorIndex;

		maxCycleColor = [(NSString *)cycleColorArray intValue];
                cycleColors = malloc(sizeof(color_t) * maxCycleColor);

		for (cycleColorIndex = 0; cycleColorIndex < maxCycleColor; cycleColorIndex++) {
			NSColor *color;

                        color = [NSColor colorWithCalibratedHue: (float)cycleColorIndex/(float)maxCycleColor
                                                     saturation: 1.0
                                                     brightness: 1.0
                                                          alpha: 1.0];

			cycleColors[cycleColorIndex].r = (unsigned char) (255 * [color redComponent]);
			cycleColors[cycleColorIndex].g = (unsigned char) (255 * [color greenComponent]);
			cycleColors[cycleColorIndex].b = (unsigned char) (255 * [color blueComponent]);
			cycleColors[cycleColorIndex].a = (unsigned char) (255);
		}
	    }
	}
	exteriorColorTightness = [[aDictionary objectForKey:@"exteriorColorTightness"] intValue];
    }


    {
        NSNumber                   *antialiasCutoffNumber;


        maxAntialiasingDepth = [[aDictionary objectForKey: @"maxAntialiasingDepth"] intValue];
        
        if ((antialiasCutoffNumber = [aDictionary objectForKey: @"antialiasCutoff"]))
            antialiasCutoff = doubleValue(antialiasCutoffNumber);
        else
            antialiasCutoff = 0.05;
            
	lookbackStart = [[aDictionary objectForKey:@"lookbackStart"] intValue];
	maxLookback = [[aDictionary objectForKey:@"maxLookback"] intValue];
	lookbackFreq = [[aDictionary objectForKey:@"lookbackFreq"] intValue];

	tileWidth = [[aDictionary objectForKey:@"tileWidth"] intValue];
	tileHeight = [[aDictionary objectForKey:@"tileHeight"] intValue];

	N = [[aDictionary objectForKey:@"N"] intValue];
	/* orbit = (q *) xmalloc(sizeof(q) * (N + 1)); */

	readColor([aDictionary objectForKey:@"background"], &background);

        epsilon = doubleValue([aDictionary objectForKey:@"epsilon"]);
	if ([aDictionary objectForKey:@"overflow"])
            overflow = doubleValue([aDictionary objectForKey:@"overflow"]);
	else
	    overflow = sqrt(MAXDOUBLE);

        clippingBubble = doubleValue([aDictionary objectForKey:@"clippingBubble"]);
        clippingBubble *= clippingBubble;

	filename = [[aDictionary objectForKey:@"filename"] retain];
	if (!filename)
	    filename = @"/tmp/julia.tiff";
    }


    if (tileWidth % 16 || tileHeight % 16) {
	fprintf(stderr, "Rounding tile size to multiples of 16.\n");
	tileWidth = OGMRoundUp(tileWidth, 16);
	tileHeight = OGMRoundUp(tileHeight, 16);
    }

    return self;
}

- (void)dealloc;
{
    [filename release];
    NSZoneFree(NSDefaultMallocZone(), planes);
    NSZoneFree(NSDefaultMallocZone(), cycleColors);
    [super dealloc];
}

/* NSCoding stuff */

- (id)replacementObjectForPortCoder:(NSPortCoder *)coder;
{
    /* Always send bycopy */
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    unsigned int i;

    ENCODE(numberOfPlanes);
    for (i = 0; i < numberOfPlanes; i++)
	ENCODE(planes[i]);

    ENCODE(colorByBasin);
    ENCODE(maxCycleColor);
    for (i = 0; i < maxCycleColor; i++)
	ENCODE(cycleColors[i]);

    ENCODE(m);
    ENCODE(tileWidth);
    ENCODE(tileHeight);
    ENCODE(u);

    ENCODE(dist);
    ENCODE(nr);
    ENCODE(nc);
    ENCODE(n);
    ENCODE(N);
    ENCODE(lookbackStart);
    ENCODE(maxLookback);
    ENCODE(lookbackFreq);
    ENCODE(epsilon);
    ENCODE(delta);
    ENCODE(overflow);
    ENCODE(clippingBubble);
    ENCODE(background);
    ENCODE(maxAntialiasingDepth);
    ENCODE(antialiasCutoff);
    ENCODE(exteriorColorTightness);
    ENCODE(filename);

    ENCODE(rotation);
    ENCODE(crot);
    ENCODE(srot);
    ENCODE(cnrot);
    ENCODE(snrot);
}


- initWithCoder: (NSCoder *) coder;
{
    unsigned int i;

    [super init];

    DECODE(numberOfPlanes);
    if (numberOfPlanes)
	planes = malloc(sizeof(*planes) * numberOfPlanes);
    else
	planes = NULL;
    for (i = 0; i < numberOfPlanes; i++)
	DECODE(planes[i]);

    DECODE(colorByBasin);
    DECODE(maxCycleColor);
    if (maxCycleColor)
	cycleColors = malloc(sizeof(*cycleColors) * maxCycleColor);
    else
	cycleColors = NULL;    
    for (i = 0; i < maxCycleColor; i++)
	DECODE(cycleColors[i]);

    DECODE(m);
    DECODE(tileWidth);
    DECODE(tileHeight);
    DECODE(u);

    DECODE(dist);
    DECODE(nr);
    DECODE(nc);
    DECODE(n);
    DECODE(N);
    DECODE(lookbackStart);
    DECODE(maxLookback);
    DECODE(lookbackFreq);
    DECODE(epsilon);
    DECODE(delta);
    DECODE(overflow);
    DECODE(clippingBubble);
    DECODE(background);
    DECODE(maxAntialiasingDepth);
    DECODE(antialiasCutoff);
    DECODE(exteriorColorTightness);
    DECODE(filename);
    [filename retain];

    DECODE(rotation);
    DECODE(crot);
    DECODE(srot);
    DECODE(cnrot);
    DECODE(snrot);
    
    return self;
}
@end
