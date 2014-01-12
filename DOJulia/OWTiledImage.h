#import <AppKit/AppKit.h>


@interface OWTiledImage : NSView

- initWithFrame:(NSRect)aRect;
- (void)drawRect:(NSRect)rect;

- (void) setTilesHigh: (unsigned int) aHeight tileHeight: (unsigned int) aTileHeight
            tilesWide: (unsigned int) aWidth  tileWidth:  (unsigned int) aTileWidth;

- (unsigned int) tilesHigh;
- (unsigned int) tilesWide;
- (unsigned int) tileWidth;
- (unsigned int) tileHeight;

- (void)setImage:(NSImage *)anImage atX: (unsigned int) tileX y: (unsigned int) tileY;
- (NSImage *) tileAtX: (unsigned int) x y: (unsigned int) y;

@end
