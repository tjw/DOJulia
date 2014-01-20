
#import "types.h"

class map;
class JuliaContext {
private:
    // Disallow default constructor and copy
    JuliaContext() {};
    JuliaContext(const JuliaContext &);

public:
    const map *m;
    NSUInteger tileWidth, tileHeight;
    quaternion u;
    NSUInteger nr, nc;
    iteration N;
    NSUInteger lookbackStart, maxLookback, lookbackFreq;
    double epsilon, delta, overflow;
    double clippingBubble;
    color_t background;

    NSUInteger maxAntialiasingDepth;
    double antialiasCutoff;

    NSUInteger exteriorColorTightness;

    NSUInteger numberOfPlanes;
    const plane_t *planes;

    double rotation;	/* in complex plane */
    double crot, srot;
    double cnrot, snrot;

    NSUInteger maxCycleColor;
    const color_t *cycleColors;
    bool colorByBasin;
    
    static const JuliaContext *makeContext(NSDictionary *dict, NSUInteger frameNumber);
    ~JuliaContext();
};
