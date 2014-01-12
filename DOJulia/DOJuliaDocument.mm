extern "C" {
#import <AppKit/NSGraphics.h>
#import "DOJuliaController.h"
#import "DOJuliaDocument.h"
#import "JuliaClient.h"
#import "Frame.h"
#import "OWTiledImage.h"
}

#import <DOJuliaShared/OWJuliaContext.h>
#import <DOJuliaShared/Tile.h>


@implementation DOJuliaDocument

+ (void) load
{
    DOJuliaController *controller;

    controller = (DOJuliaController *)[DOJuliaController sharedInstance];
    [controller setDefaultDocumentClass:self];
    [controller registerDocumentClass:self forFileExtension:[self fileExtension]];
}

+ (NSString *) fileExtension;
{
    return @"julia";
}

- (void) dealloc;
{
    [client release];
    [super dealloc];
}

- (BOOL) readFromPath: (NSString *) aPath;
{
    Frame *aFrame = nil;
    OWJuliaContext *context;

    client = [[JuliaClient alloc] init];
    [client setDelegate:self];
    [client readConfigurationFromFile:aPath];
    if ([[client frames] count])
	aFrame = [[client frames] objectAtIndex: 0];
    if (!aFrame)
	return NO;

    context = [aFrame context];

    [[tileView window] setDepthLimit:NSBestDepth(NSCalibratedRGBColorSpace, 8, 24, NO, NULL)];
    [tileView setTilesHigh: [aFrame tilesHigh] tileHeight: context->tileHeight
                 tilesWide: [aFrame tilesWide] tileWidth: context->tileWidth];
    return YES;
}

- startComputing: sender;
{
    [client computeAnimation];
    return self;
}

- stopComputing: sender;
{
    return self;
}

/* JuliaClient delegate messages */
- (void) juliaClient: (JuliaClient *) aClient didAcceptTile: (Tile *) aTile;
{
    NSImage                    *image;
    NSBitmapImageRep           *imageRep;
    NSRect                      rect;

    rect = [aTile rect];

#warning Can we not just pass a NULL?
    {
	unsigned char *conversion_tmp[5] = {NULL}; 
	conversion_tmp[0] = NULL; 
	imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&conversion_tmp[0]
                                                    pixelsWide: (unsigned int)rect.size.width
                                                    pixelsHigh: (unsigned int)rect.size.height
                                                 bitsPerSample:8
                                               samplesPerPixel:4
                                                      hasAlpha:YES
                                                      isPlanar:NO
                                                colorSpaceName:NSDeviceRGBColorSpace
                                                   bytesPerRow:0
                                                  bitsPerPixel:0];
    };
    bcopy([[aTile tileData] bytes], [imageRep bitmapData], [[aTile tileData] length]);

    image = [[NSImage alloc] init];
    [image addRepresentation:imageRep];
    [image setDataRetained:YES];
    [tileView setImage:image
                   atX: (unsigned int)(rect.origin.x / [tileView tileWidth])
                     y: (unsigned int)(rect.origin.y / [tileView tileHeight])];
    [image release];
    [tileView display];
}

@end
