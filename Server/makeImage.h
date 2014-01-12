extern "C" {
#import <Foundation/NSGeometry.h>
}

#import "types.h"
#import "ImageTile.h"

class quaternion;
@class OWJuliaContext;

void makeTile(OWJuliaContext *context, NSRect tileRect, ImageTile *tile, quaternion *orbit);
