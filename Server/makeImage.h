extern "C" {
#import <Foundation/NSGeometry.h>
}

#import <DOJuliaShared/types.h>
#import "tile.h"

class quaternion;
@class OWJuliaContext;

void makeTile(OWJuliaContext *context, NSRect tileRect, tile_t *tile, quaternion *orbit);
