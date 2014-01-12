extern "C" {
#import <Foundation/Foundation.h>
#import "OWTiledImage.h"
}

#import <OmniGameMath/utilities.h>

#define IMAGE_AT(x,y)  (images[(y) * tilesWide + (x)])

@implementation OWTiledImage

+ (NSImage *) nullImageTemplate;
{
    static NSImage             *nullImageTemplate = nil;

    if (!nullImageTemplate)
	nullImageTemplate = [NSImage imageNamed:@"NullImage"];
    return nullImageTemplate;
}

- initWithFrame:(NSRect)aRect;
{
    if (![super initWithFrame:aRect])
        return nil;

    tilesWide = 0;
    tilesHigh = 0;
    images = NULL;

    return self;
}

- (void)drawRect:(NSRect)rect;
{
    NSRect                      realRect;
    unsigned int                startX, xCount;
    unsigned int                startY, yCount;
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
}

- (void) setTilesHigh: (unsigned int) aHeight tileHeight: (unsigned int) aTileHeight
            tilesWide: (unsigned int) aWidth  tileWidth:  (unsigned int) aTileWidth;
{
    unsigned int                x, y;
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
}

- (unsigned int) tilesHigh;
{
    return tilesHigh;
}

- (unsigned int) tilesWide;
{
    return tilesWide;
}

- (unsigned int) tileWidth;
{
    return tileWidth;
}

- (unsigned int) tileHeight;
{
    return tileHeight;
}

- (void)setImage:(NSImage *)anImage atX: (unsigned int) tileX y: (unsigned int) tileY;
{
    if (!images)
	return;
    [IMAGE_AT(tileX, tileY) autorelease];
    IMAGE_AT(tileX, tileY) = [anImage retain];
}

- (NSImage *) tileAtX: (unsigned int) x y: (unsigned int) y;
{
    if (!images)
	return nil;
    return IMAGE_AT(x, y);
}

@end

