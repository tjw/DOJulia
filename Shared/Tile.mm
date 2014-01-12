#import "Tile.h"

#import "OWJuliaContext.h"
#import "OWEncoding.h"

@implementation Tile

- initWithBounds:(NSRect)bounds context:(OWJuliaContext *)context;
{
    if (!(self = [super init]))
        return nil;
    
    _bounds = bounds;
    _context = context;

    return self;
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

#pragma mark - NSCoding

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
