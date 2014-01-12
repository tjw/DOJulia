extern "C" {
#import <Foundation/NSData.h>
}

#import <DOJuliaShared/types.h>
#import "tile.h"



void   tileFree(tile_t *t)
{
    if (!t)
	return;
    [t->pixelData release];
    NSZoneFree(NSDefaultMallocZone(), t);
}


tile_t *tileNew(int rows, int cols)
{
    tile_t              *ret;

    ret = (tile_t *)NSZoneMalloc(NSDefaultMallocZone(), sizeof(tile_t));

    ret->nr = rows;
    ret->nc = cols;
    ret->pixelData = [[NSMutableData alloc] initWithLength: sizeof(color_t) * ret->nr * ret->nc];
    ret->pixelBytes = [ret->pixelData mutableBytes];

    return ret;
}


