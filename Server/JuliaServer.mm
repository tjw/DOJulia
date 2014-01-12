extern "C" {
#import <Foundation/Foundation.h>
}

#import <DOJuliaShared/Tile.h>
#import <DOJuliaShared/OWJuliaContext.h>

#import "JuliaServer.h"
#import "makeImage.h"
#import "tile.h"

@implementation JuliaServer

- (oneway void) provideDataForTile: (bycopy Tile *) aTile
                         forClient: (id <JuliaClientProtocol>) aClient
{

    NS_DURING {
#ifdef PROFILE
        static unsigned int         tileCount = 16;
#endif

	OWJuliaContext             *context;
	tile_t                     *tile;
	static quaternion          *orbit = NULL;

#warning Should cache the data object between calls
	if (!aTile)
	    NS_VOIDRETURN;
	context = [aTile context];
	if (!context)
	    NS_VOIDRETURN;

	[(NSDistantObject *) aClient setProtocolForProxy:@protocol(JuliaClientProtocol)];

	tile = tileNew(context->tileWidth, context->tileHeight);

#warning General C++ question: This will not call the constructor on these objects.
        orbit = (quaternion *) NSZoneRealloc(NSDefaultMallocZone(), orbit, sizeof(quaternion) * (context->N + 1));
	makeTile(context, [aTile rect], tile, orbit);

        [aTile setTileData: tile->pixelData];
	[aClient acceptTile:aTile fromServer:self];
	fprintf(stderr, "Completed tile %ld.\n", [aTile tileNum]);

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

