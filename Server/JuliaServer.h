extern "C" {
#import <Foundation/NSObject.h>
#import "Protocols.h"
}

@interface JuliaServer : NSObject <JuliaServerProtocol>

+ (instancetype)sharedServer;

@end
