
@class Tile;
@protocol JuliaServerProtocol;

@protocol JuliaClientProtocol
- (oneway void)acceptTile:(bycopy Tile *)aTile fromServer:(id <JuliaServerProtocol>)server;
@end

@protocol JuliaServerProtocol
- (oneway void)provideDataForTile:(bycopy Tile *)aTile forClient:(id <JuliaClientProtocol>)aClient;
@end
