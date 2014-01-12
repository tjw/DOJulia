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
    int                         tileWidth, tileHeight;
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

    unsigned int                numberOfPlanes;
    plane_t                    *planes;

    NSString                   *filename;

    double                      rotation;	/* in complex plane */
    double                      crot, srot;
    double                      cnrot, snrot;

    unsigned int                maxCycleColor;
    color_t                    *cycleColors;
    unsigned int                colorByBasin;
}

- initWithDictionary: (NSDictionary *) aDictionary
         frameNumber: (unsigned int) aFrameNumber;
@end

