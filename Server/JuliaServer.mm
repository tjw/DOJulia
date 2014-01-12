extern "C" {
#import <Foundation/Foundation.h>
}

#import "Tile.h"
#import "OWJuliaContext.h"

#import "JuliaServer.h"
#import "makeImage.h"
#import "ImageTile.h"

@implementation JuliaServer

- (oneway void) provideDataForTile: (bycopy Tile *) aTile
                         forClient: (id <JuliaClientProtocol>) aClient
{

    NS_DURING {
#ifdef PROFILE
        static unsigned int         tileCount = 16;
#endif

//#warning Should cache the data object between calls
	if (!aTile)
	    NS_VOIDRETURN;
	OWJuliaContext *context = [aTile context];
	if (!context)
	    NS_VOIDRETURN;

	[(NSDistantObject *) aClient setProtocolForProxy:@protocol(JuliaClientProtocol)];

	ImageTile *tile = tileNew(context->tileWidth, context->tileHeight);

//#warning General C++ question: This will not call the constructor on these objects.
        static quaternion *orbit = NULL;
        orbit = (quaternion *) NSZoneRealloc(NSDefaultMallocZone(), orbit, sizeof(quaternion) * (context->N + 1));
        
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
    } NS_HANDLER {
	NSLog(@"exception raised:%@", [localException reason]);
    } NS_ENDHANDLER;
}


@end

