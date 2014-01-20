extern "C" {
#import "Frame.h"
}

#import "utilities.h"
#import "JuliaContext.h"
#import "Tile.h"
#import "map.h"


@implementation Frame
{
    NSMutableArray *_tilesToDo;
}

+ (instancetype)frameWithConfiguration:(NSDictionary *)configuration frameNumber:(NSUInteger)frameNumber;
{
    return [[self alloc] initWithConfiguration:configuration frameNumber:frameNumber];
}

- initWithConfiguration:(NSDictionary *)configuration frameNumber:(NSUInteger)frameNumber;
{
    if (!(self = [super init]))
        return nil;

    _frameNumber = frameNumber;

    _context = JuliaContext::makeContext(configuration, frameNumber);

    NSRect tileRect = NSMakeRect(0, 0, _context->tileWidth, _context->tileHeight);

    NSSize imageSize;
    imageSize.width = OGMRoundUp(_context->nc, _context->tileWidth);
    imageSize.height = OGMRoundUp(_context->nr, _context->tileHeight);

    _tilesWide = imageSize.width / _context->tileWidth;
    _tilesHigh = imageSize.height / _context->tileHeight;
    fprintf(stderr, "Generating %ld tiles ...\n", _tilesWide * _tilesHigh);

    printf("\n");
    fflush(stdout);


    // Generate a list of tile objects to perform
    _tilesToDo = [[NSMutableArray alloc] init];
    for (NSUInteger tileX = 0; tileX < _tilesWide; tileX++) {
	for (NSUInteger tileY = 0; tileY < _tilesHigh; tileY++) {

            // TODO: Should change this to not compute all data for images on edges
	    tileRect.origin.x = tileX * _context->tileWidth;
	    tileRect.origin.y = tileY * _context->tileHeight;

	    Tile *tile = [[Tile alloc] initWithBounds:tileRect context:_context];
	    [tile setFrameNumber:_frameNumber];

	    [_tilesToDo addObject:tile];
	}
    }

    return self;
}

- (void)dealloc;
{
    if (_context)
        delete _context;
}

@synthesize tilesToDo = _tilesToDo;

- (void)markTileDone:(Tile *)tile;
{
    NSUInteger tileIndex = [_tilesToDo indexOfObjectIdenticalTo:tile];
    if (tileIndex == NSNotFound) {
	NSLog(@"Useless tile %p", tile);
        return;
    }
    [_tilesToDo removeObjectAtIndex:tileIndex];

    if ([_tilesToDo count] == 0)
	NSLog(@"Frame %lu done.", _frameNumber);
}

@end
