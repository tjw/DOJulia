extern "C" {
#import <Foundation/Foundation.h>
//#import <TIFF/tiffio.h>
}

#import "types.h"

@class OWJuliaContext;

@interface Tile : NSObject <NSCoding>
{
    NSRect                      bounds;
//    ttile_t                     tileNum;
    unsigned int                frameNumber;

    NSData                     *tileData;

    OWJuliaContext             *context;
}

- initRect: (NSRect) aRect context: (OWJuliaContext *) context;
- (NSRect) rect;

- (OWJuliaContext *) context;

//- (void) setTileNum: (ttile_t) num;
//- (ttile_t) tileNum;

- (void) setFrameNumber: (unsigned int) aFrameNumber;
- (unsigned int) frameNumber;

- (void) setTileData: (NSData *) data;
- (NSData *) tileData;
@end
