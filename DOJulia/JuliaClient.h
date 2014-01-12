#import <AppKit/AppKit.h>
#import <DOJuliaShared/Protocols.h>


@class NSString;
@class NSMutableArray;
@class NSMutableDictionary;

@interface JuliaClient : NSObject <JuliaClientProtocol>
{
    NSMutableDictionary        *configuration;
    NSString                   *filenameFormat;
    unsigned int                stepCount;
    double                      startRr, startRi, startRj, startRk;
    double                      stepRr, stepRi, stepRj, stepRk;

    NSMutableArray             *serverArray;
    NSMutableDictionary        *serverTable;
    NSMutableDictionary        *serverStatsDict;
    NSMutableArray             *tiles;
    NSMutableArray             *frames;

    id                          delegate;
}

- init;

- (void)setDelegate:(id)aDelegate;

- (void) readConfigurationFromFile: (NSString *) filename;
- (void) computeAnimation;

- (NSArray *) frames;

@end


@interface NSObject (JuliaClientDelegate)
- (void) juliaClient: (JuliaClient *) aClient didAcceptTile: (Tile *) aTile;
@end
