extern "C" {
#import <Foundation/NSPortCoder.h>
#import <Foundation/NSArray.h>
#import <AppKit/NSColor.h>
}

#import "OWEncoding.h"
#import "JuliaContext.h"
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

const JuliaContext *JuliaContext::makeContext(NSDictionary *dict, NSUInteger frameNumber)
{
    JuliaContext *ctx = new JuliaContext();

    {
	double                      focusLength, fov, scale;
        vector                      eyePoint;

	NSArray *orientation = [dict objectForKey:@"orientation"];

	ctx->u = quaternion((NSDictionary *)dict[@"u"]);

        eyePoint = readVector([dict objectForKey:@"eyePoint"]);
        focusLength = doubleValue([dict objectForKey:@"focusLength"]);
        fov = degToRad(doubleValue([dict objectForKey:@"fov"]));
        ctx->nc = [[dict objectForKey:@"imageWidth"] intValue];
        ctx->nr = [[dict objectForKey:@"imageHeight"] intValue];
        ctx->delta = doubleValue([dict objectForKey:@"delta"]);

        // This screws stuff up
#if 0
        scale = doubleValue([dict objectForKey: @"scaleStart"]) +
            doubleValue([dict objectForKey: @"scaleStep"]) * aFrameNumber;
#else
        scale = 1.0;
#endif
        
        ctx->m = map::makeMap(eyePoint, focusLength, fov,
                              degToRad(doubleValue([orientation objectAtIndex:0])),
                              degToRad(doubleValue([orientation objectAtIndex:1])),
                              degToRad(doubleValue([orientation objectAtIndex:2])),
                              scale, 4.0, ctx->nc, ctx->nr);
        ctx->delta *= ctx->m->screenWidth;

        double rotation = degToRad(doubleValue([orientation objectAtIndex:3]));
        ctx->rotation = rotation;
        ctx->crot = cos(rotation);
        ctx->srot = sin(rotation);
        ctx->cnrot = cos(-rotation);
	ctx->snrot = sin(-rotation);
    }

    {
	NSArray *clippingPlanes = dict[@"clippingPlanes"];

        plane_t *readingPlanes = NULL;
	if (!(ctx->numberOfPlanes = [clippingPlanes count]))
	    readingPlanes = NULL;
	else {
	    readingPlanes = (plane_t *) NSZoneMalloc(NSDefaultMallocZone(), (sizeof(plane_t) * ctx->numberOfPlanes));
	    for (NSUInteger planeIndex = 0; planeIndex < ctx->numberOfPlanes; planeIndex++) {
		NSDictionary *planeDict = clippingPlanes[planeIndex];
                readingPlanes[planeIndex].normal = readQuaternion([planeDict objectForKey:@"normal"]);
                readingPlanes[planeIndex].dist = doubleValue([planeDict objectForKey:@"dist"]);
                readingPlanes[planeIndex].opacity = doubleValue([planeDict objectForKey:@"opacity"]);
		readingPlanes[planeIndex].clips = [[planeDict objectForKey:@"clips"] intValue];
	    }
	}
        ctx->planes = readingPlanes;
    }

    {
	NSArray                    *cycleColorArray;
	unsigned int                cycleColorIndex;

	ctx->maxCycleColor = 0;
	color_t *readingColors = NULL;
	if ((ctx->colorByBasin = [[dict objectForKey:@"colorByBasin"] boolValue])) {
	    cycleColorArray = [dict objectForKey:@"cycleColors"];
	    if ([cycleColorArray isKindOfClass:[NSArray class]]) {
		if ((ctx->maxCycleColor = [cycleColorArray count])) {
		    readingColors = (color_t *)malloc(sizeof(color_t) * ctx->maxCycleColor);
		    for (cycleColorIndex = 0; cycleColorIndex < ctx->maxCycleColor; cycleColorIndex++)
			readColor([cycleColorArray objectAtIndex:cycleColorIndex],
				  &readingColors[cycleColorIndex]);
		}
	    } else {
		unsigned int                cycleColorIndex;

		ctx->maxCycleColor = [(NSString *)cycleColorArray intValue];
                readingColors = (color_t *)malloc(sizeof(color_t) * ctx->maxCycleColor);

		for (cycleColorIndex = 0; cycleColorIndex < ctx->maxCycleColor; cycleColorIndex++) {
			NSColor *color;

                        color = [NSColor colorWithCalibratedHue: (float)cycleColorIndex/(float)ctx->maxCycleColor
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
        ctx->cycleColors = readingColors;
	ctx->exteriorColorTightness = [[dict objectForKey:@"exteriorColorTightness"] intValue];
    }


    {
        NSNumber                   *antialiasCutoffNumber;


        ctx->maxAntialiasingDepth = [[dict objectForKey: @"maxAntialiasingDepth"] intValue];
        
        if ((antialiasCutoffNumber = [dict objectForKey: @"antialiasCutoff"]))
            ctx->antialiasCutoff = doubleValue(antialiasCutoffNumber);
        else
            ctx->antialiasCutoff = 0.05;
            
	ctx->lookbackStart = [[dict objectForKey:@"lookbackStart"] intValue];
	ctx->maxLookback = [[dict objectForKey:@"maxLookback"] intValue];
	ctx->lookbackFreq = [[dict objectForKey:@"lookbackFreq"] intValue];

	ctx->tileWidth = [[dict objectForKey:@"tileWidth"] intValue];
	ctx->tileHeight = [[dict objectForKey:@"tileHeight"] intValue];

	ctx->N = [[dict objectForKey:@"N"] intValue];
	/* orbit = (q *) xmalloc(sizeof(q) * (N + 1)); */

	readColor([dict objectForKey:@"background"], &ctx->background);

        ctx->epsilon = doubleValue([dict objectForKey:@"epsilon"]);
	if ([dict objectForKey:@"overflow"])
            ctx->overflow = doubleValue([dict objectForKey:@"overflow"]);
	else
	    ctx->overflow = sqrt(DBL_MAX);

        ctx->clippingBubble = doubleValue([dict objectForKey:@"clippingBubble"]);
        ctx->clippingBubble *= ctx->clippingBubble;
    }


    if (ctx->tileWidth % 16 || ctx->tileHeight % 16) {
	fprintf(stderr, "Rounding tile size to multiples of 16.\n");
	ctx->tileWidth = OGMRoundUp(ctx->tileWidth, 16);
	ctx->tileHeight = OGMRoundUp(ctx->tileHeight, 16);
    }

    return ctx;
}

JuliaContext::~JuliaContext()
{
    if (planes)
        free((void *)planes);
    if (cycleColors)
        free((void *)cycleColors);
}
