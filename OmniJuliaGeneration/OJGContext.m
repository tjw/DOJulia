#import <Foundation/NSPortCoder.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSColor.h>

#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/OWEncoding.h>
#import <DOJuliaShared/OWUtil.h>
#import <DOJuliaShared/map-client.h>

static INLINE double degToRad(double deg)
{
    return (deg / 180.0) * M_PI;
}

static INLINE void readQuaternion(NSDictionary *dict, q *quat)
{
    quat->r = [[dict objectForKey:@"r"] doubleValue];
    quat->i = [[dict objectForKey:@"i"] doubleValue];
    quat->j = [[dict objectForKey:@"j"] doubleValue];
    quat->k = [[dict objectForKey:@"k"] doubleValue];
}

static INLINE void readPoint(NSDictionary *dict, point *p)
{
    p->x = [[dict objectForKey: @"x"] doubleValue];
    p->y = [[dict objectForKey: @"y"] doubleValue];
    p->z = [[dict objectForKey: @"z"] doubleValue];
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


@implementation OWJuliaContext

- initWithDictionary: (NSDictionary *) aDictionary
         frameNumber: (unsigned int) aFrameNumber;
{
    [super init];
    {
	double                      focusLength, fov;
        point                       eyePoint;

	NSArray                    *orientation;

	orientation = [aDictionary objectForKey:@"orientation"];

	readQuaternion([aDictionary objectForKey:@"u"], &u);

	readPoint([aDictionary objectForKey:@"eyePoint"], &eyePoint);
        focusLength = doubleValue([aDictionary objectForKey:@"focusLength"]);
        fov = degToRad(doubleValue([aDictionary objectForKey:@"fov"]));
        nc = [[aDictionary objectForKey:@"imageWidth"] intValue];
        nr = [[aDictionary objectForKey:@"imageHeight"] intValue];
        delta = doubleValue([aDictionary objectForKey:@"delta"]);

        mapSet(&m, eyePoint, focusLength, fov,
               degToRad(doubleValue([orientation objectAtIndex:0])),
               degToRad(doubleValue([orientation objectAtIndex:1])),
               degToRad(doubleValue([orientation objectAtIndex:2])),
               4.0, nc, nr);
        delta *= m.screenWidth;

#ifdef ROTATION
        rotation = degToRad(doubleValue([orientation objectAtIndex:3]));
        crot = cos(rotation);
        srot = sin(rotation);
        cnrot = cos(-rotation);
	snrot = sin(-rotation);
#endif
    }

    {
	NSArray                    *clippingPlanes;
	unsigned int                planeIndex;

	clippingPlanes = [aDictionary objectForKey:@"clippingPlanes"];
	if (!(numberOfPlanes = [clippingPlanes count]))
	    planes = NULL;
	else {

	    planes = (plane_t *) xmalloc(sizeof(plane_t) * numberOfPlanes);
	    for (planeIndex = 0; planeIndex < numberOfPlanes; planeIndex++) {
		NSDictionary               *planeDict;

		planeDict = [clippingPlanes objectAtIndex:planeIndex];
		readQuaternion([planeDict objectForKey:@"normal"], &planes[planeIndex].normal);
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

			cycleColors[cycleColorIndex].r = 255 * [color redComponent];
			cycleColors[cycleColorIndex].g = 255 * [color greenComponent];
			cycleColors[cycleColorIndex].b = 255 * [color blueComponent];
			cycleColors[cycleColorIndex].a = 255;
		}
	    }
	}
	exteriorColorTightness = [[aDictionary objectForKey:@"exteriorColorTightness"] intValue];
    }


    {
	NSString                   *castingMethodName;
	NSNumber                   *maximumCastsNumber, *minimumCastsNumber, *castSettleNumber;

	castingMethodName = [aDictionary objectForKey:@"castingMethod"];
	maximumCastsNumber = [aDictionary objectForKey:@"maximumCasts"];
	minimumCastsNumber = [aDictionary objectForKey:@"minimumCasts"];
	castSettleNumber = [aDictionary objectForKey:@"castSettle"];

	minimumCasts = [minimumCastsNumber intValue];
	if (!minimumCastsNumber)
	    minimumCasts = 1;
	maximumCasts = [maximumCastsNumber intValue];
	if (!maximumCastsNumber)
	    maximumCasts = 1;

        castSettle = doubleValue(castSettleNumber);

	if ([castingMethodName isEqualToString:@"static"])
	    castingMethod = castStatic;
	else if ([castingMethodName isEqualToString:@"random"])
	    castingMethod = castRandom;
	else if ([castingMethodName isEqualToString:@"adaptive"])
	    castingMethod = castAdaptive;
	else {
	    castingMethod = castStatic;
	    minimumCasts = 1;
	    maximumCasts = 1;
	}

	NSLog(@"Casting method = (%d,%d,%d)", castingMethod, minimumCasts, maximumCasts);


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
	tileWidth = OWRoundUp(tileWidth, 16);
	tileHeight = OWRoundUp(tileHeight, 16);
    }

    return self;
}

- (void)dealloc;
{
    [filename release];
    planes = xrealloc(planes, 0);
    cycleColors = xrealloc(cycleColors, 0);
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
    ENCODE(castingMethod);
    ENCODE(minimumCasts);
    ENCODE(maximumCasts);
    ENCODE(castSettle);
    ENCODE(actualNumberOfCasts);
    ENCODE(exteriorColorTightness);
    ENCODE(filename);

#ifdef ROTATION
    ENCODE(rotation);
    ENCODE(crot);
    ENCODE(srot);
    ENCODE(cnrot);
    ENCODE(snrot);
#endif
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
    DECODE(castingMethod);
    DECODE(minimumCasts);
    DECODE(maximumCasts);
    DECODE(castSettle);
    DECODE(actualNumberOfCasts);
    DECODE(exteriorColorTightness);
    DECODE(filename);
    [filename retain];

#ifdef ROTATION
    DECODE(rotation);
    DECODE(crot);
    DECODE(srot);
    DECODE(cnrot);
    DECODE(snrot);
#endif

    return self;
}
@end
