extern "C" {
#import <Foundation/Foundation.h>
}

#import "Tile.h"
#import "JuliaContext.h"

#import "JuliaServer.h"
#import "makeImage.h"
#import "ImageTile.h"

@implementation JuliaServer
{
    NSOperationQueue *_operationQueue;
}

+ (instancetype)sharedServer;
{
    static JuliaServer *sharedServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedServer = [[self alloc] init];
    });
    return sharedServer;
}

- init;
{
    if (!(self = [super init]))
        return nil;
    
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.name = @"com.omnigroup.JuliaServer";
    //_operationQueue.maxConcurrentOperationCount = 1;
    
    return self;
}

#pragma mark - JuliaServerProtocol

- (void)provideDataForTile:(Tile *)aTile forClient:(id <JuliaClientProtocol>)aClient
{
    [_operationQueue addOperationWithBlock:^{
        @try {
#ifdef PROFILE
            static unsigned int         tileCount = 16;
#endif
            
            if (!aTile)
                return;
            const JuliaContext *context = [aTile context];
            if (!context)
                return;
                        
            ImageTile *tile = tileNew(context->tileWidth, context->tileHeight);
            
            quaternion *orbit = (quaternion *)malloc(sizeof(quaternion) * (context->N + 1));
            makeTile(context, aTile.bounds, tile, orbit);
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                aTile.data = (__bridge NSData *)tile->pixelData;
                [aClient acceptTile:aTile fromServer:self];
            
                tileFree(tile);
                free(orbit);
                //[aTile release];
            }];
#ifdef PROFILE
            if (!--tileCount)
                exit(0);
#endif
        } @catch (NSException *exc) {
            NSLog(@"exception raised:%@", [exc reason]);
        }
    }];
}


@end

