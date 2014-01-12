extern "C" {
#import <bsd/libc.h>
}

#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/OWEncoding.h>
#import <DOJuliaShared/Tile.h>

@implementation Tile

- initRect: (NSRect) aRect context: (OWJuliaContext *) aContext
{
    [super init];
    bounds = aRect;
    context = [aContext retain];
    tileData = nil;

    return self;
}

- (void)dealloc;
{
    [tileData release];
    [context release];
    [super dealloc];
}

- (OWJuliaContext *) context
{
    return context;
}


- (NSRect)rect
{
    return bounds;
}

- (void) setTileNum: (ttile_t) num
{
    tileNum = num;
}

- (ttile_t) tileNum
{
    return tileNum;
}

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
     [tileData release];
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
    ENCODE(bounds);
    ENCODE(tileNum);
    ENCODE(frameNumber);

    [coder encodeObject: tileData];
    [coder encodeObject: context];
}

- initWithCoder: (NSCoder *) coder;
{
    [super init];

    DECODE(bounds);
    DECODE(tileNum);
    DECODE(frameNumber);

    tileData = [[coder decodeObject] retain];
    context = [[coder decodeObject] retain];

    return self;
}
@end
