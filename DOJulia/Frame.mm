extern "C" {
#import "config.h"
#import "NSArrayExtensions.h"
#import "Frame.h"
}

#import "utilities.h"
#import "JuliaContext.h"
#import "Tile.h"
#import "map.h"


@implementation Frame
{
//    TIFF                       *tif;
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

#if 0
    tif = TIFFOpen([context->filename cString], "w");
    TIFFSetDirectory(tif, 0);
    TIFFSetField(tif, TIFFTAG_IMAGEWIDTH, (int)context->nc);
    TIFFSetField(tif, TIFFTAG_IMAGELENGTH, (int)context->nr);
    TIFFSetField(tif, TIFFTAG_TILEWIDTH, context->tileWidth);
    TIFFSetField(tif, TIFFTAG_TILELENGTH, context->tileHeight);
    TIFFSetField(tif, TIFFTAG_BITSPERSAMPLE, 8);
    TIFFSetField(tif, TIFFTAG_COMPRESSION, COMPRESSION_LZW);
    TIFFSetField(tif, TIFFTAG_PREDICTOR, 2);
    TIFFSetField(tif, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
    TIFFSetField(tif, TIFFTAG_SAMPLESPERPIXEL, 4);
    TIFFSetField(tif, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
    TIFFSetField(tif, TIFFTAG_RESOLUTIONUNIT, RESUNIT_INCH);
#endif
    
    NSRect tileRect = NSMakeRect(0, 0, _context->tileWidth, _context->tileHeight);

    NSSize imageSize;
    imageSize.width = OGMRoundUp(_context->nc, _context->tileWidth);
    imageSize.height = OGMRoundUp(_context->nr, _context->tileHeight);

    _tilesWide = imageSize.width / _context->tileWidth;
    _tilesHigh = imageSize.height / _context->tileHeight;
    fprintf(stderr, "Generating %ld tiles ...\n", _tilesWide * _tilesHigh);

    printf("\n");
    fflush(stdout);


    _tilesToDo = [[NSMutableArray alloc] init];
    /* Generate a list of tile objects to perform */
    for (NSUInteger tileX = 0; tileX < _tilesWide; tileX++) {
	for (NSUInteger tileY = 0; tileY < _tilesHigh; tileY++) {

            // TODO: Should change this to not compute all data for images on edges
	    tileRect.origin.x = tileX * _context->tileWidth;
	    tileRect.origin.y = tileY * _context->tileHeight;

	    Tile *tile = [[Tile alloc] initWithBounds:tileRect context:_context];
	    [tile setFrameNumber:_frameNumber];

            NSLog(@"Not generating TIFF file");
#if 0
	    ttile_t tifTile = TIFFComputeTile(tif, tileRect.origin.x, tileRect.origin.y, 0, 0);
	    [tile setTileNum:tifTile];
#endif
	    [_tilesToDo addObject:tile];
	}
    }

    _tilesToDo = [_tilesToDo randomizedArray];

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

    NSLog(@"No tiled image support currently");
#if 0
    TIFFWriteEncodedTile(tif, [aTile tileNum], [[aTile tileData] bytes],
			 TIFFTileSize(tif));
#endif

    if (![_tilesToDo count]) {
#if 0
	TIFFClose(tif);
	tif = NULL;
#endif
	NSLog(@"Frame %lu done.", _frameNumber);
    }
}


@end
