extern "C" {
#import <Foundation/Foundation.h>
#import "OWTiledImage.h"
}

#import "utilities.h"

#define IMAGE_AT(x,y)  (images[(y) * tilesWide + (x)])

@implementation OWTiledImage
{
    NSUInteger                tilesWide;
    NSUInteger                tileWidth;
    NSUInteger                tilesHigh;
    NSUInteger                tileHeight;
//    NSImage                   **images;
    NSImage                    *nullImage;
}

+ (NSImage *) nullImageTemplate;
{
    static NSImage             *nullImageTemplate = nil;

    if (!nullImageTemplate)
	nullImageTemplate = [NSImage imageNamed:@"NullImage"];
    return nullImageTemplate;
}

- initWithFrame:(NSRect)aRect;
{
    abort();
#if 0
    if (![super initWithFrame:aRect])
        return nil;

    tilesWide = 0;
    tilesHigh = 0;
    images = NULL;

    return self;
#endif
}

- (void)drawRect:(NSRect)rect;
{
    abort();
#if 0
    NSRect                      realRect;
    NSUInteger                startX, xCount;
    NSUInteger                startY, yCount;
    int                         x, y;

    if (!images)
        return;

    realRect = OGMSnapRect(rect, tileWidth, tileHeight);

    startX = realRect.origin.x / tileWidth;
    startY = realRect.origin.y / tileHeight;
    xCount = realRect.size.width / tileWidth;
    yCount = realRect.size.height / tileWidth;

    for (x = startX; x < startX + xCount; x++) {
	for (y = startY + yCount - 1; y >= 0; y--) {
	    NSImage                    *image;
	    NSPoint                     aPoint;

	    image = IMAGE_AT(x, y);
	    aPoint.x = x * tileWidth;
	    aPoint.y = (tilesHigh - y - 1) * tileHeight;
	    [image compositeToPoint:aPoint operation:NSCompositeCopy];
	    /*[[image lastRepresentation] drawAt: &aPoint];*/
	}
    }
#endif
}

- (void)setTilesHigh:(NSUInteger)aHeight tileHeight:(NSUInteger)aTileHeight
           tilesWide:(NSUInteger)aWidth tileWidth:(NSUInteger)aTileWidth;
{
    abort();
#if 0
    NSUInteger                x, y;
    NSSize                      imageSize;

    if (images && aHeight && aWidth) {
	NSLog(@"Cannot set number of tiles on instance with images loaded");
	return;
    } else if (!aHeight && !aWidth) {
	NSLog(@"Not releasing images");
	free(images);
    }
    tilesHigh = aHeight;
    tilesWide = aHeight;
    images = calloc(sizeof(NSImage *), aHeight * aWidth);

    tileWidth = aTileWidth;
    tileHeight = aTileHeight;

    nullImage = [[[self class] nullImageTemplate] copyWithZone:[self zone]];
    [nullImage setScalesWhenResized:YES];
    [nullImage recache];
    imageSize.width = tileWidth;
    imageSize.height = tileHeight;
    [nullImage setSize:imageSize];

    for (x = 0; x < tilesWide; x++)
	for (y = 0; y < tilesHigh; y++)
	    [self setImage:nullImage atX:x y:y];

    [self setFrameSize:NSMakeSize(tileWidth * tilesWide, tileHeight * tilesHigh)];
#endif
}

- (NSUInteger) tilesHigh;
{
    return tilesHigh;
}

- (NSUInteger) tilesWide;
{
    return tilesWide;
}

- (NSUInteger) tileWidth;
{
    return tileWidth;
}

- (NSUInteger) tileHeight;
{
    return tileHeight;
}

- (void)setImage:(NSImage *)anImage atX:(NSUInteger)tileX y:(NSUInteger)tileY;
{
    abort();
#if 0
    if (!images)
	return;
    [IMAGE_AT(tileX, tileY) autorelease];
    IMAGE_AT(tileX, tileY) = [anImage retain];
#endif
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

