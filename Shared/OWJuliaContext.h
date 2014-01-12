extern "C" {
#import <Foundation/NSObject.h>
}

#import "types.h"
#import "map.h"

@class NSString, NSDictionary;

@interface OWJuliaContext : NSObject
{
@public
    map                         m;
    NSUInteger                  tileWidth, tileHeight;
    quaternion                  u;
    double                      dist;
    unsigned int                nr, nc;
    iteration                   n, N;
    unsigned int                lookbackStart, maxLookback, lookbackFreq;
    double                      epsilon, delta, overflow;
    double                      clippingBubble;
    color_t                     background;

    unsigned int                maxAntialiasingDepth;
    double                      antialiasCutoff;

    unsigned int                exteriorColorTightness;

    NSUInteger                numberOfPlanes;
    plane_t                    *planes;

    NSString                   *filename;

    double                      rotation;	/* in complex plane */
    double                      crot, srot;
    double                      cnrot, snrot;

    NSUInteger                maxCycleColor;
    color_t                    *cycleColors;
    unsigned int                colorByBasin;
}

- initWithDictionary:(NSDictionary *)aDictionary frameNumber:(NSUInteger)aFrameNumber;

@end

