#import "ImageTile.h"

extern "C" {
#import <Foundation/NSData.h>
}

#import "types.h"

void tileFree(ImageTile *t)
{
    abort();
#if 0
    if (!t)
	return;
    [t->pixelData release];
    NSZoneFree(NSDefaultMallocZone(), t);
#endif
}


ImageTile *tileNew(int rows, int cols)
{
    abort();
#if 0
    ImageTile              *ret;

    ret = (ImageTile *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(ImageTile));

    ret->nr = rows;
    ret->nc = cols;
    ret->pixelData = [[NSMutableData alloc] initWithLength: sizeof(color_t) * ret->nr * ret->nc];
    ret->pixelBytes = [ret->pixelData mutableBytes];

    return ret;
#endif
}


