
#import "types.h"

class map;
class JuliaContext {
private:
    // Disallow default constructor and copy
    JuliaContext() {};
    JuliaContext(const JuliaContext &);

public:
    const map *m;
    NSUInteger                  tileWidth, tileHeight;
    quaternion                  u;
    unsigned int                nr, nc;
    iteration                   N;
    unsigned int                lookbackStart, maxLookback, lookbackFreq;
    double                      epsilon, delta, overflow;
    double                      clippingBubble;
    color_t                     background;

    unsigned int                maxAntialiasingDepth;
    double                      antialiasCutoff;

    unsigned int                exteriorColorTightness;

    NSUInteger                numberOfPlanes;
    const plane_t                    *planes;

    const NSString                   *filename;

    double                      rotation;	/* in complex plane */
    double                      crot, srot;
    double                      cnrot, snrot;

    NSUInteger                maxCycleColor;
    const color_t                    *cycleColors;
    unsigned int                colorByBasin;
    
    static const JuliaContext *makeContext(NSDictionary *dict, NSUInteger frameNumber);
    ~JuliaContext();
};
