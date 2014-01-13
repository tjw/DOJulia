extern "C" {
#import <Foundation/Foundation.h>
}

#import "types.h"

class JuliaContext;

@interface Tile : NSObject <NSCoding>

- initWithBounds:(NSRect)bounds context:(const JuliaContext *)context;

@property(nonatomic,readonly) NSRect bounds;
@property(nonatomic,readonly) const JuliaContext *context;

//- (void) setTileNum: (ttile_t) num;
//- (ttile_t) tileNum;

@property(nonatomic) NSUInteger frameNumber;
@property(nonatomic,copy) NSData *data;

@end
