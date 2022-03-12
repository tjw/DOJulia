extern "C" {
#import <Foundation/Foundation.h>
#import <OmniAppKit/OATrackingLoop.h>
#import <OmniFoundation/OFGeometry.h>
#import <OmniBase/OBUtilities.h>

#import "TiledImageView.h"
}

#import "utilities.h"

#define IMAGE_VIEW_AT(x,y)  (_imageViews[(y) * _tilesWide + (x)])

@interface SelectionView : NSView
@end

@implementation SelectionView

- (BOOL)wantsUpdateLayer;
{
    return YES;
}

- (void)updateLayer;
{
    self.layer.borderColor = [[NSColor redColor] CGColor];
    self.layer.borderWidth = 1;
    self.layer.zPosition = 1;
}

@end

@interface TileImageView : NSImageView
@property(nonatomic) NSUInteger tileX;
@property(nonatomic) NSUInteger tileY;
@end
@implementation TileImageView

- (NSView *)hitTest:(NSPoint)aPoint;
{
    return nil;
}
- (BOOL)mouse:(NSPoint)aPoint inRect:(NSRect)aRect;
{
    return NO;
}

@end

@implementation TiledImageView
{
    NSLayoutConstraint *_widthConstraint;
    NSLayoutConstraint *_heightConstraint;

    SelectionView *_selectionView;
    
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

    self.translatesAutoresizingMaskIntoConstraints = NO;

    if (!_widthConstraint) {
        _widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:_tilesWide*_tileWidth];
        _widthConstraint.active = YES;
    } else {
        _widthConstraint.constant = _tilesWide*_tileWidth;
    }

    if (!_heightConstraint) {
        _heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:_tilesHigh*_tileHeight];
        _heightConstraint.active = YES;
    } else {
        _heightConstraint.constant = _tilesHigh*_tileHeight;
    }

    [self needsUpdateConstraints];
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

- (void)clearSelection;
{
    [_selectionView removeFromSuperview];
    _selectionView = nil;
}

#pragma mark - NSView subclass

- (BOOL)isFlipped;
{
    return YES;
}

- (void)layout;
{
    for (TileImageView *imageView in _imageViews) {
        NSUInteger tileX = imageView.tileX;
        NSUInteger tileY = imageView.tileY;
        
        CGRect tileFrame = CGRectMake(tileX * _tileWidth, tileY * _tileHeight, _tileWidth, _tileHeight);
        imageView.frame = tileFrame;
    }
    
    [super layout];
}

#pragma mark - NSResponder

- (void)mouseDown:(NSEvent *)theEvent;
{
    OATrackingLoop *loop = [self trackingLoopForMouseDown:theEvent];

    if (!_selectionView) {
        CGPoint pt = loop.initialMouseDownPointInView;
        _selectionView = [[SelectionView alloc] initWithFrame:CGRectMake(pt.x, pt.y, 1, 1)];
        [self addSubview:_selectionView positioned:NSWindowBelow relativeTo:nil];
    }
    
    loop.dragged = ^(OATrackingLoop *loop_){
        _selectionView.frame = OFRectFromPoints(loop_.initialMouseDownPointInView, loop_.currentMouseDraggedPointInView);
    };

    loop.up = ^(OATrackingLoop *loop_){
        id <TiledImageViewDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(tiledImageView:didSelectRect:)])
            [delegate tiledImageView:self didSelectRect:_selectionView.frame];
    };
    
    [loop run];
}

@end

