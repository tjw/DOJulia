#import "ImageTile.h"

extern "C" {
#import <Foundation/NSData.h>
}

#import "types.h"

void tileFree(ImageTile *t)
{
    if (!t)
	return;
    if (t->pixelData)
        CFRelease(t->pixelData); // This owns the bytes
}


ImageTile *tileNew(NSUInteger rows, NSUInteger cols)
{
    ImageTile *tile = (ImageTile *)calloc(1, sizeof(*tile));

    tile->nr = rows;
    tile->nc = cols;
    
    CFIndex pixelDataSize = sizeof(color_t) * tile->nr * tile->nc;
    tile->pixelData = CFDataCreateMutable(kCFAllocatorDefault, pixelDataSize);
    CFDataSetLength(tile->pixelData, pixelDataSize);
    
    tile->pixelBytes = (color_t *)CFDataGetMutableBytePtr(tile->pixelData);

    return tile;
}


