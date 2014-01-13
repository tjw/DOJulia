#import "Tile.h"

#import "JuliaContext.h"
#import "OWEncoding.h"

@implementation Tile

- initWithBounds:(NSRect)bounds context:(const JuliaContext *)context;
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

- (void)encodeWithCoder:(NSCoder *)coder;
{
    abort(); // we should no longer be doing bycopy, but we might want code to make an immutable copy
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
    abort(); // we should no longer be doing bycopy, but we might want code to make an immutable copy
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
