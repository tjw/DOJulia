
@class Tile;
@protocol JuliaServerProtocol;

@protocol JuliaClientProtocol
- (void)acceptTile:(Tile *)aTile fromServer:(id <JuliaServerProtocol>)server;
@end

@protocol JuliaServerProtocol
- (void)provideDataForTile:(Tile *)aTile forClient:(id <JuliaClientProtocol>)aClient;
@end
