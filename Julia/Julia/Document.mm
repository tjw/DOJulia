//
//  Document.m
//  Julia
//
//  Created by Timothy J. Wood on 1/12/14.
//  Copyright (c) 2014 The Omni Group. All rights reserved.
//

#import "Document.h"

extern "C" {
#import <AppKit/NSGraphics.h>
#import "DOJuliaController.h"
#import "JuliaClient.h"
#import "Frame.h"
#import "OWTiledImage.h"
}

#import "OWJuliaContext.h"
#import "Tile.h"

@implementation Document
{
    id                          tileView;
    JuliaClient                *client;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (IBAction)startComputing:(id)sender;
{
    [client computeAnimation];
}

- (IBAction)stopComputing:(id)sender;
{
}

#pragma mark - JuliaClient delegate

- (void) juliaClient: (JuliaClient *) aClient didAcceptTile: (Tile *) aTile;
{
    NSImage                    *image;
    NSBitmapImageRep           *imageRep;
    NSRect                      rect;
    
    rect = [aTile rect];
    
    // #warning Can we not just pass a NULL?
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
    [tileView display];
}

#pragma mark - NSDocument subclass

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;
{
    Frame *aFrame = nil;
    OWJuliaContext *context;
    
    client = [[JuliaClient alloc] init];
    [client setDelegate:self];
    [client readConfigurationFromFileURL:url];
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

@end
