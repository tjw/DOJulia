#import <AppKit/AppKit.h>


@interface TiledImageView : NSView

- (void)setTilesHigh:(NSUInteger)aHeight tileHeight:(NSUInteger)aTileHeight
           tilesWide:(NSUInteger)aWidth tileWidth:(NSUInteger)aTileWidth;

@property(nonatomic,readonly) NSUInteger tilesHigh;
@property(nonatomic,readonly) NSUInteger tilesWide;
@property(nonatomic,readonly) NSUInteger tileWidth;
@property(nonatomic,readonly) NSUInteger tileHeight;

- (void)setImage:(NSImage *)image atX:(NSUInteger)tileX y:(NSUInteger)tileY;
- (NSImage *)tileAtX:(NSUInteger)x y:(NSUInteger)y;

@end
