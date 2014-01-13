extern "C" {
#import <Foundation/NSPortCoder.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSColor.h>
}

#import "OWEncoding.h"
#import "OWJuliaContext.h"
#import "map.h"

#import "utilities.h"

static inline double degToRad(double deg)
{
    return (deg / 180.0) * M_PI;
}

static inline quaternion readQuaternion(NSDictionary *dict)
{
    double r, i, j, k;
    
    r = [[dict objectForKey:@"r"] doubleValue];
    i = [[dict objectForKey:@"i"] doubleValue];
    j = [[dict objectForKey:@"j"] doubleValue];
    k = [[dict objectForKey:@"k"] doubleValue];

    return quaternion(r, i, j, k);
}

static inline vector readVector(NSDictionary *dict)
{
    double x, y, z;
    
    x = [[dict objectForKey: @"x"] doubleValue];
    y = [[dict objectForKey: @"y"] doubleValue];
    z = [[dict objectForKey: @"z"] doubleValue];

    return vector(x, y, z);
}

static inline void readColor(NSDictionary *dict, color_t *c)
{
    c->r = (unsigned char)[[dict objectForKey: @"r"] intValue];
    c->g = (unsigned char)[[dict objectForKey: @"g"] intValue];
    c->b = (unsigned char)[[dict objectForKey: @"b"] intValue];
    c->a = (unsigned char)[[dict objectForKey: @"a"] intValue];
}

static inline double doubleValue(id object)
{
    // If you try to get a double by invoking a method on nil, you'll get NaN
    if (!object)
        return 0.0;
    else
        return [object doubleValue];
}



@implementation OWJuliaContext

- initWithDictionary:(NSDictionary *)aDictionary frameNumber:(NSUInteger)aFrameNumber;
{
    if (!(self = [super init]))
        return nil;
    
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
        
        if (m)
            delete m;
        m = map::makeMap(eyePoint, focusLength, fov,
                         degToRad(doubleValue([orientation objectAtIndex:0])),
                         degToRad(doubleValue([orientation objectAtIndex:1])),
                         degToRad(doubleValue([orientation objectAtIndex:2])),
                         scale, 4.0, nc, nr);
        delta *= m->screenWidth;

        rotation = degToRad(doubleValue([orientation objectAtIndex:3]));
        crot = cos(rotation);
        srot = sin(rotation);
        cnrot = cos(-rotation);
	snrot = sin(-rotation);
    }

    {
	NSArray *clippingPlanes = aDictionary[@"clippingPlanes"];

        plane_t *readingPlanes = NULL;
	if (!(numberOfPlanes = [clippingPlanes count]))
	    readingPlanes = NULL;
	else {
	    readingPlanes = (plane_t *) NSZoneMalloc(NSDefaultMallocZone(), (sizeof(plane_t) * numberOfPlanes));
	    for (NSUInteger planeIndex = 0; planeIndex < numberOfPlanes; planeIndex++) {
		NSDictionary *planeDict = clippingPlanes[planeIndex];
                readingPlanes[planeIndex].normal = readQuaternion([planeDict objectForKey:@"normal"]);
                readingPlanes[planeIndex].dist = doubleValue([planeDict objectForKey:@"dist"]);
                readingPlanes[planeIndex].opacity = doubleValue([planeDict objectForKey:@"opacity"]);
		readingPlanes[planeIndex].clips = [[planeDict objectForKey:@"clips"] intValue];
	    }
	}
        planes = readingPlanes;
    }

    {
	NSArray                    *cycleColorArray;
	unsigned int                cycleColorIndex;

	maxCycleColor = 0;
	color_t *readingColors = NULL;
	if ((colorByBasin = [[aDictionary objectForKey:@"colorByBasin"] intValue])) {
	    cycleColorArray = [aDictionary objectForKey:@"cycleColors"];
	    if ([cycleColorArray isKindOfClass:[NSArray class]]) {
		if ((maxCycleColor = [cycleColorArray count])) {
		    readingColors = (color_t *)malloc(sizeof(color_t) * maxCycleColor);
		    for (cycleColorIndex = 0; cycleColorIndex < maxCycleColor; cycleColorIndex++)
			readColor([cycleColorArray objectAtIndex:cycleColorIndex],
				  &readingColors[cycleColorIndex]);
		}
	    } else {
		unsigned int                cycleColorIndex;

		maxCycleColor = [(NSString *)cycleColorArray intValue];
                readingColors = (color_t *)malloc(sizeof(color_t) * maxCycleColor);

		for (cycleColorIndex = 0; cycleColorIndex < maxCycleColor; cycleColorIndex++) {
			NSColor *color;

                        color = [NSColor colorWithCalibratedHue: (float)cycleColorIndex/(float)maxCycleColor
                                                     saturation: 1.0
                                                     brightness: 1.0
                                                          alpha: 1.0];

			readingColors[cycleColorIndex].r = (unsigned char) (255 * [color redComponent]);
			readingColors[cycleColorIndex].g = (unsigned char) (255 * [color greenComponent]);
			readingColors[cycleColorIndex].b = (unsigned char) (255 * [color blueComponent]);
			readingColors[cycleColorIndex].a = (unsigned char) (255);
		}
	    }
	}
        cycleColors = readingColors;
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
	    overflow = sqrt(DBL_MAX);

        clippingBubble = doubleValue([aDictionary objectForKey:@"clippingBubble"]);
        clippingBubble *= clippingBubble;

	filename = [[aDictionary objectForKey:@"filename"] copy];
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
    if (planes)
        free((void *)planes);
    if (cycleColors)
        free((void *)cycleColors);
}

/* NSCoding stuff */

- (void)encodeWithCoder:(NSCoder *)coder;
{
    abort(); // we should no longer be doing bycopy, but we might want code to make an immutable copy
#if 0
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
#endif
}


- initWithCoder: (NSCoder *) coder;
{
    abort(); // we should no longer be doing bycopy, but we might want code to make an immutable copy
#if 0
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
#endif
}

@end
