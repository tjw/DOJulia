extern "C" {
#import <Foundation/NSGeometry.h>
}

#import "types.h"
#import "ImageTile.h"

class quaternion;
class JuliaContext;

void makeTile(const JuliaContext *context, NSRect tileRect, ImageTile *tile, quaternion *orbit);
