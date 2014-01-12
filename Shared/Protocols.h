
@class Tile;
@class NSData;

@protocol JuliaClientProtocol
- (oneway void) acceptTile: (bycopy Tile *) aTile fromServer: server;
@end

@protocol JuliaServerProtocol
- (oneway void) provideDataForTile: (bycopy Tile *) aTile
                         forClient: (id <JuliaClientProtocol>) aClient;
@end

