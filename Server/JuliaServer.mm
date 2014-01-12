extern "C" {
#import <Foundation/Foundation.h>
}

#import "Tile.h"
#import "OWJuliaContext.h"

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
    
    // TODO: Get rid of this and the 'static' in the block below
    _operationQueue.maxConcurrentOperationCount = 1;
    
    return self;
}

#pragma mark - JuliaServerProtocol

- (oneway void)provideDataForTile:(bycopy Tile *)aTile forClient:(id <JuliaClientProtocol>)aClient
{
    [_operationQueue addOperationWithBlock:^{
        @try {
#ifdef PROFILE
            static unsigned int         tileCount = 16;
#endif
            
            //#warning Should cache the data object between calls
            if (!aTile)
                return;
            OWJuliaContext *context = [aTile context];
            if (!context)
                return;
                        
            ImageTile *tile = tileNew(context->tileWidth, context->tileHeight);
            
            //#warning General C++ question: This will not call the constructor on these objects.
            static quaternion *orbit = NULL;
            orbit = (quaternion *)realloc(orbit, sizeof(quaternion) * (context->N + 1));
            
            makeTile(context, aTile.bounds, tile, orbit);
            
            aTile.data = tile->pixelData;
            [aClient acceptTile:aTile fromServer:self];
            fprintf(stderr, "Completed tile %p.\n", aTile);
            
            tileFree(tile);
            //[aTile release];
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

