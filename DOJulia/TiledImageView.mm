extern "C" {
#import <Foundation/Foundation.h>
#import "TiledImageView.h"
}

#import "utilities.h"

#define IMAGE_AT(x,y)  (_images[(y) * _tilesWide + (x)])

@implementation TiledImageView
{
    NSUInteger                _tilesWide;
    NSUInteger                _tileWidth;
    NSUInteger                _tilesHigh;
    NSUInteger                _tileHeight;
    __unsafe_unretained NSImage **_images;
    NSImage                    *_nullImage;
}

+ (NSImage *) nullImageTemplate;
{
    static NSImage             *nullImageTemplate = nil;

    if (!nullImageTemplate)
	nullImageTemplate = [NSImage imageNamed:@"NullImage"];
    return nullImageTemplate;
}

- (void)drawRect:(NSRect)rect;
{
    if (!_images)
        return;

    NSRect realRect = OGMSnapRect(rect, _tileWidth, _tileHeight);

    NSUInteger startX = realRect.origin.x / _tileWidth;
    NSUInteger startY = realRect.origin.y / _tileHeight;
    NSUInteger xCount = realRect.size.width / _tileWidth;
    NSUInteger yCount = realRect.size.height / _tileWidth;

    for (NSUInteger x = startX; x < startX + xCount; x++) {
        for (NSUInteger y = startY; y < startY + yCount; y++) {
	    __unsafe_unretained NSImage *image = IMAGE_AT(x, y);
            NSPoint point;
	    point.x = x * _tileWidth;
	    point.y = (_tilesHigh - y - 1) * _tileHeight;
	    [image compositeToPoint:point operation:NSCompositeCopy];
	    /*[[image lastRepresentation] drawAt: &aPoint];*/
	}
    }
}

- (CGSize)intrinsicContentSize;
{
    return CGSizeMake(_tileWidth * _tilesWide, _tileHeight * _tilesHigh);
}

- (void)setTilesHigh:(NSUInteger)aHeight tileHeight:(NSUInteger)aTileHeight
           tilesWide:(NSUInteger)aWidth tileWidth:(NSUInteger)aTileWidth;
{
    if (_images && aHeight && aWidth) {
	NSLog(@"Cannot set number of tiles on instance with images loaded");
	return;
    } else if (!aHeight && !aWidth) {
	NSLog(@"Not releasing images");
	free(_images);
    }
    _tilesHigh = aHeight;
    _tilesWide = aHeight;
    _images = (__unsafe_unretained NSImage **)calloc(sizeof(NSImage *), aHeight * aWidth);

    _tileWidth = aTileWidth;
    _tileHeight = aTileHeight;

    _nullImage = [[[self class] nullImageTemplate] copy];
    [_nullImage setSize:NSMakeSize(_tileWidth, _tileHeight)];

    for (NSUInteger x = 0; x < _tilesWide; x++)
	for (NSUInteger y = 0; y < _tilesHigh; y++)
	    [self setImage:_nullImage atX:x y:y];

    [self invalidateIntrinsicContentSize];
}

- (void)setImage:(__unsafe_unretained NSImage *)image atX:(NSUInteger)tileX y:(NSUInteger)tileY;
{
    if (!_images)
	return;
    
    __unsafe_unretained NSImage *oldImage = IMAGE_AT(tileX, tileY);
    if (oldImage == image)
        return;
    
    if (oldImage)
        CFRelease((__bridge CFTypeRef)oldImage);
    if (image)
        CFRetain((__bridge CFTypeRef)image);
    IMAGE_AT(tileX, tileY) = image;
    
    [self setNeedsDisplay:YES];
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

@end

