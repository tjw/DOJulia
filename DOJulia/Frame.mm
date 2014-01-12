extern "C" {
#import "config.h"
#import "NSArrayExtensions.h"
#import "Frame.h"
}

#import "utilities.h"
#import "OWJuliaContext.h"
#import "Tile.h"
#import "map.h"


@implementation Frame
{
//    TIFF                       *tif;
    OWJuliaContext             *context;
    NSMutableArray             *tilesToDo;
    unsigned int                frameNumber;
    unsigned int                tilesWide;
    unsigned int                tilesHigh;
}


- initWithConfiguration: (NSDictionary *) configuration
            frameNumber: (unsigned int) aFrameNumber;
{
    abort();
#if 0
    int                         tileX, tileY;
    NSRect                      tileRect;
    NSSize                      imageSize;
    id                          tile;

    [super init];

    frameNumber = aFrameNumber;

    context = [[OWJuliaContext alloc] initWithDictionary: configuration frameNumber: aFrameNumber];

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

    tileRect.origin.x = 0.0;
    tileRect.origin.y = 0.0;
    tileRect.size.width = context->tileWidth;
    tileRect.size.height = context->tileHeight;

    imageSize.width = OGMRoundUp(context->nc, context->tileWidth);
    imageSize.height = OGMRoundUp(context->nr, context->tileHeight);

    tilesWide = imageSize.width / context->tileWidth;
    tilesHigh = imageSize.height / context->tileHeight;
    fprintf(stderr, "Generating %d tiles ...\n", tilesWide * tilesHigh);

    printf("\n");
    fflush(stdout);


    tilesToDo = [[NSMutableArray alloc] init];
    /* Generate a list of tile objects to perform */
    for (tileX = 0; tileX < tilesWide; tileX++) {
	for (tileY = 0; tileY < tilesHigh; tileY++) {
	    ttile_t                     tifTile;

#warning Should change this to not compute all data for images on edges
	    tileRect.origin.x = tileX * context->tileWidth;
	    tileRect.origin.y = tileY * context->tileHeight;

	    tile = [[Tile alloc] initRect:tileRect context:context];
	    [tile setFrameNumber:frameNumber];

	    tifTile = TIFFComputeTile(tif, tileRect.origin.x,
				      tileRect.origin.y, 0, 0);
	    [tile setTileNum:tifTile];
	    [tilesToDo addObject:tile];
	}
    }

    [tilesToDo autorelease];
    tilesToDo = [[tilesToDo randomizedArray] retain];

    return self;
#endif
}

- (OWJuliaContext *) context;
{
    return context;
}

- (unsigned int) tilesWide;
{
    return tilesWide;
}

- (unsigned int) tilesHigh;
{
    return tilesHigh;
}

+ frameWithConfiguration: (NSDictionary *) configuration
             frameNumber: (unsigned int) aFrameNumber;
{
    return [[self alloc] initWithConfiguration:configuration frameNumber:aFrameNumber];
}

- (NSArray *) tilesToDo;
{
    return tilesToDo;
}

- (void) markTileDone: (Tile *) aTile;
{
    abort();
#if 0
    NSEnumerator               *tileEnum;
    Tile                       *myTile;
    BOOL                        found = NO;


    /*
     * The tile that we get back might be a bycopy version of the one we
     * have, must check the tile number to determine equality 
     */
    tileEnum = [tilesToDo objectEnumerator];
    while ((myTile = [tileEnum nextObject])) {
	if ([myTile tileNum] == [aTile tileNum]) {
	    [tilesToDo removeObjectIdenticalTo:myTile];
	    found = YES;
	    break;
	}
    }

    if (!found) {
	NSLog(@"Useless tile %d", [aTile tileNum]);
        return;
    }

    TIFFWriteEncodedTile(tif, [aTile tileNum], [[aTile tileData] bytes],
			 TIFFTileSize(tif));

    if (![tilesToDo count]) {
	TIFFClose(tif);
	tif = NULL;
	NSLog(@"Frame %d done.", frameNumber);
    }
#endif
}


@end
