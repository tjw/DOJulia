extern "C" {
#import <Foundation/Foundation.h>
}

#import "types.h"

@class OWJuliaContext;

@interface Tile : NSObject <NSCoding>

- initWithBounds:(NSRect)bounds context:(OWJuliaContext *)context;

@property(nonatomic,readonly) NSRect bounds;
@property(nonatomic,readonly) OWJuliaContext *context;

//- (void) setTileNum: (ttile_t) num;
//- (ttile_t) tileNum;

@property(nonatomic) NSUInteger frameNumber;
@property(nonatomic,copy) NSData *data;

@end
