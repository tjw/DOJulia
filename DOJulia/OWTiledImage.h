#import <AppKit/AppKit.h>


@interface OWTiledImage : NSView

- (void)setTilesHigh:(NSUInteger)aHeight tileHeight:(NSUInteger)aTileHeight
           tilesWide:(NSUInteger)aWidth tileWidth:(NSUInteger)aTileWidth;

- (NSUInteger)tilesHigh;
- (NSUInteger)tilesWide;
- (NSUInteger)tileWidth;
- (NSUInteger)tileHeight;

- (void)setImage:(NSImage *)anImage atX:(NSUInteger)tileX y:(NSUInteger)tileY;
- (NSImage *)tileAtX:(NSUInteger)x y:(NSUInteger)y;

@end
