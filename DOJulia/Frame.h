#import <Foundation/NSObject.h>

@class Tile;
class JuliaContext;

@interface Frame : NSObject

+ (instancetype)frameWithConfiguration:(NSDictionary *)configuration frameNumber:(NSUInteger)frameNumber;

- initWithConfiguration:(NSDictionary *)configuration frameNumber:(NSUInteger)frameNumber;

@property(nonatomic,readonly) const JuliaContext *context;
@property(nonatomic,readonly) NSUInteger frameNumber;
@property(nonatomic,readonly) NSUInteger tilesWide;
@property(nonatomic,readonly) NSUInteger tilesHigh;
@property(nonatomic,readonly) NSArray *tilesToDo;

- (void)markTileDone:(Tile *)tile;

@end
