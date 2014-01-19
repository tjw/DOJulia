extern "C" {
#import <Foundation/Foundation.h>
#import "TiledImageView.h"
}

#import "utilities.h"

#define IMAGE_VIEW_AT(x,y)  (_imageViews[(y) * _tilesWide + (x)])

@interface TileImageView : NSImageView
@property(nonatomic) NSUInteger tileX;
@property(nonatomic) NSUInteger tileY;
@end
@implementation TileImageView
@end

@implementation TiledImageView
{
    NSUInteger _tilesWide;
    NSUInteger _tileWidth;
    
    NSUInteger _tilesHigh;
    NSUInteger _tileHeight;
    
    NSArray *_imageViews;
    NSImage *_nullImage;
}

+ (NSImage *)nullImageTemplate;
{
    static NSImage *nullImageTemplate = nil;
    
    if (!nullImageTemplate)
	nullImageTemplate = [NSImage imageNamed:@"NullImage"];
    return nullImageTemplate;
}

- (void)setTilesHigh:(NSUInteger)aHeight tileHeight:(NSUInteger)aTileHeight
           tilesWide:(NSUInteger)aWidth tileWidth:(NSUInteger)aTileWidth;
{
    if (_imageViews && aHeight && aWidth) {
	NSLog(@"Cannot set number of tiles on instance with images loaded");
	return;
    } else if (!aHeight && !aWidth) {
        for (TileImageView *imageView in _imageViews)
            [imageView removeFromSuperview];
        _imageViews = nil;
    }
    
    _tilesHigh = aHeight;
    _tilesWide = aHeight;
    _tileWidth = aTileWidth;
    _tileHeight = aTileHeight;

    _nullImage = [[[self class] nullImageTemplate] copy];
    [_nullImage setSize:NSMakeSize(_tileWidth, _tileHeight)];
    
    NSMutableArray *imageViews = [NSMutableArray array];
    for (NSUInteger y = 0; y < _tilesHigh; y++) {
        for (NSUInteger x = 0; x < _tilesWide; x++) {
            TileImageView *imageView = [[TileImageView alloc] initWithFrame:CGRectMake(0, 0, _tileWidth, _tileHeight)];
            imageView.tileX = x;
            imageView.tileY = y;
            imageView.image = _nullImage;
            [imageViews addObject:imageView];
            [self addSubview:imageView];
        }
    }
    _imageViews = [imageViews copy];

    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout:YES];
}

- (void)setImage:(__unsafe_unretained NSImage *)image atX:(NSUInteger)tileX y:(NSUInteger)tileY;
{
    if (!_imageViews)
	return;
    
    TileImageView *imageView = IMAGE_VIEW_AT(tileX, tileY);
    imageView.image = image;
}

- (NSImage *)tileAtX:(NSUInteger)x y:(NSUInteger)y;
{
    abort();
#if 0
    if (!images)
	return nil;
    return IMAGE_AT(x, y);
#endif
}

#pragma mark - NSView subclass

- (BOOL)isFlipped;
{
    return YES;
}

- (CGSize)intrinsicContentSize;
{
    return CGSizeMake(_tileWidth * _tilesWide, _tileHeight * _tilesHigh);
}

- (void)layout;
{
    [super layout];
    
    for (TileImageView *imageView in _imageViews) {
        NSUInteger tileX = imageView.tileX;
        NSUInteger tileY = imageView.tileY;
        
        CGRect tileFrame = CGRectMake(tileX * _tileWidth, tileY * _tileHeight, _tileWidth, _tileHeight);
        imageView.frame = tileFrame;
    }
}

@end

