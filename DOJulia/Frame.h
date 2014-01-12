#import <Foundation/NSObject.h>
#import <TIFF/tiffio.h>

@class Tile, OWJuliaContext;

@interface Frame : NSObject
{
    TIFF                       *tif;
    OWJuliaContext             *context;
    NSMutableArray             *tilesToDo;
    unsigned int                frameNumber;
    unsigned int                tilesWide;
    unsigned int                tilesHigh;
}


- initWithConfiguration: (NSDictionary *) configuration
            frameNumber: (unsigned int) aFrameNumber;

+ frameWithConfiguration: (NSDictionary *) configuration
             frameNumber: (unsigned int) aFrameNumber;

- (NSArray *) tilesToDo;
- (void) markTileDone: (Tile *) aTile;

- (OWJuliaContext *) context;
- (unsigned int) tilesWide;
- (unsigned int) tilesHigh;

@end
