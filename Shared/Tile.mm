#import "Tile.h"

#import "OWJuliaContext.h"
#import "OWEncoding.h"

@implementation Tile

- initRect: (NSRect) aRect context: (OWJuliaContext *) aContext
{
    abort();
#if 0
    [super init];
    bounds = aRect;
    context = [aContext retain];
    tileData = nil;

    return self;
#endif
}

- (OWJuliaContext *) context
{
    return context;
}


- (NSRect)rect
{
    return bounds;
}

//- (void) setTileNum: (ttile_t) num
//{
//    tileNum = num;
//}
//
//- (ttile_t) tileNum
//{
//    return tileNum;
//}

- (void) setFrameNumber: (unsigned int) aFrameNumber;
{
    frameNumber = aFrameNumber;
}

- (unsigned int) frameNumber;
{
    return frameNumber;
}

- (void) setTileData: (NSData *) data;
{
     if (data == tileData)
         return;
     tileData = [data copy];
}

- (NSData *) tileData;
{
    return tileData;
}

/* NSCoding stuff */

- (id)replacementObjectForPortCoder:(NSPortCoder *)coder;
{
    /* Always send bycopy */
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    abort();
#if 0
    ENCODE(bounds);
    ENCODE(tileNum);
    ENCODE(frameNumber);

    [coder encodeObject: tileData];
    [coder encodeObject: context];
#endif
}

- initWithCoder: (NSCoder *) coder;
{
    abort();
#if 0
    [super init];

    DECODE(bounds);
    DECODE(tileNum);
    DECODE(frameNumber);

    tileData = [[coder decodeObject] retain];
    context = [[coder decodeObject] retain];

    return self;
#endif
}
@end
