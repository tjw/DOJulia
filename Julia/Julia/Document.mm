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
#import "TiledImageView.h"
}

#import "OWJuliaContext.h"
#import "Tile.h"

@interface Document () <JuliaClientDelegate>
@property(nonatomic,strong) IBOutlet TiledImageView *tiledImageView;
@end

@implementation Document
{
    JuliaClient *client;
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

#pragma mark - JuliaClientDelegate

- (void)juliaClient:(JuliaClient *)aClient didAcceptTile:(Tile *)tile;
{
    NSRect rect = tile.bounds;
    
    // #warning Can we not just pass a NULL?
    NSBitmapImageRep *imageRep;
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
    bcopy([[tile data] bytes], [imageRep bitmapData], [[tile data] length]);
    
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:imageRep];
    [image setDataRetained:YES];
    [_tiledImageView setImage:image
                          atX:(NSUInteger)(rect.origin.x / [_tiledImageView tileWidth])
                            y:(NSUInteger)(rect.origin.y / [_tiledImageView tileHeight])];
}

#pragma mark - NSDocument subclass

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController;
{
    // TODO: Move this into a window controller subclass
    [super windowControllerDidLoadNib:windowController];
    [self _updateImageView];
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
    
    client = [[JuliaClient alloc] init];
    [client setDelegate:self];
    if (![client readConfigurationFromFileURL:url error:outError])
        return NO;
    
    [self _updateImageView];

    return YES;
}

- (void)_updateImageView;
{
    if (client == nil || _tiledImageView == nil)
        // Have to both have the document and window loaded
        return;
    
    Frame *aFrame = nil;
    if ([[client frames] count])
	aFrame = [[client frames] objectAtIndex: 0];
    assert(aFrame);
    
    OWJuliaContext *context = [aFrame context];
    [_tiledImageView setTilesHigh:[aFrame tilesHigh] tileHeight:context->tileHeight tilesWide:[aFrame tilesWide] tileWidth:context->tileWidth];
}

@end
