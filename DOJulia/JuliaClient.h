#import <Foundation/NSObject.h>

#import "Protocols.h"

@class JuliaClient;

@protocol JuliaClientDelegate <NSObject>
- (void)juliaClient:(JuliaClient *)aClient didAcceptTile:(Tile *)aTile;
@end

@interface JuliaClient : NSObject <JuliaClientProtocol>

- (void)setDelegate:(id <JuliaClientDelegate>)aDelegate;

- (BOOL)readConfigurationFromFileURL:(NSURL *)fileURL error:(NSError **)outError;
- (void)computeAnimation;

- (NSArray *) frames;

@end
