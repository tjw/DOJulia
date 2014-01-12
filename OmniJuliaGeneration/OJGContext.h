#import <DOJuliaShared/types.h>

@interface OWJuliaContext : NSObject
{
    @public
      map m;
    int                         tileWidth, tileHeight;
    q                           u;
    double                      dist;
    int                         nr, nc;
    iteration                   n, N;
    int                         lookbackStart;
    int                         maxLookback;
    int                         lookbackFreq;
    double                      epsilon, delta, overflow;
    double                      clippingBubble;
    color_t                     background;

    castingMethod_t             castingMethod;
    int                         minimumCasts;
    int                         maximumCasts;
    double                      castSettle;
    int                         actualNumberOfCasts;

    unsigned int                exteriorColorTightness;

    unsigned int                numberOfPlanes;
    plane_t                    *planes;

    NSString                   *filename;

#ifdef ROTATION
    double                      rotation;	/* in complex plane */
    double                      crot, srot;
    double                      cnrot, snrot;

#endif

    int                         maxCycleColor;
    color_t                    *cycleColors;
    int                         colorByBasin;
}

- initWithDictionary: (NSDictionary *) aDictionary
         frameNumber: (unsigned int) aFrameNumber;
@end
