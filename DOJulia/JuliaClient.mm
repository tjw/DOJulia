extern "C" {
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "config.h"
#import "JuliaClient.h"
#import "Frame.h"
}

#import "Tile.h"

@interface JuliaClient (Private)
- (void) _setupFrames;
@end

@implementation JuliaClient

- init
{
    abort();
#if 0
    NSString                   *serverString, *serverName;
    NSArray                    *serverNames;
    NSEnumerator               *serverNameEnum;
    id                          server;


    if (!(self = [super init]))
        return nil;

    serverString = [[NSString alloc] initWithContentsOfFile:@"server.list"];
    serverNames = [serverString propertyList];

    /* Later, init this from some network query */
    serverArray = [[NSMutableArray alloc] init];
    serverTable = [[NSMutableDictionary alloc] init];
    serverStatsDict = [[NSMutableDictionary alloc] init];

    serverNameEnum = [serverNames objectEnumerator];
    while ((serverName = [serverNameEnum nextObject])) {
        server = [NSConnection rootProxyForConnectionWithRegisteredName:@"JuliaServer"
                                                                   host:serverName];
	if (server) {
	    [server setProtocolForProxy:@protocol(JuliaServerProtocol)]; 

	    NSLog(@"connected to %@", serverName);
	    [serverArray addObject:server];

            [server retain];
	    [serverTable setObject:serverName forKey: [NSValue valueWithNonretainedObject: server]];

	    [serverStatsDict setObject:[NSNumber numberWithInt:0]
	     forKey:serverName];
	}
    }

    return self;
#endif
}

- (void)setDelegate:(id)aDelegate;
{
    delegate = aDelegate;
}

- (NSArray *) frames;
{
    [self _setupFrames];
    return frames;
}

- (void)readConfigurationFromFileURL:(NSURL *)fileURL;
{
    configuration = [[NSMutableDictionary alloc] initWithContentsOfFile:@"template.julia"];
    filenameFormat = [configuration objectForKey:@"filenameFormat"];
    NSArray *orientationStep = [configuration objectForKey:@"orientationStep"];
    NSArray *orientationStart = [configuration objectForKey:@"orientationStart"];
    stepCount = [[configuration objectForKey:@"stepCount"] intValue];

    startRr = [[orientationStart objectAtIndex:0] doubleValue];
    startRi = [[orientationStart objectAtIndex:1] doubleValue];
    startRj = [[orientationStart objectAtIndex:2] doubleValue];
    startRk = [[orientationStart objectAtIndex:3] doubleValue];

    stepRr = [[orientationStep objectAtIndex:0] doubleValue];
    stepRi = [[orientationStep objectAtIndex:1] doubleValue];
    stepRj = [[orientationStep objectAtIndex:2] doubleValue];
    stepRk = [[orientationStep objectAtIndex:3] doubleValue];

}

- (void) resumeAnimation
{
    id                  server;
    Tile               *tile;

    if (![tiles count])
	/* Done! */
	return;

    if (![serverArray count]) {
	/*
	 * We'll get called again when there if a server becomes available.  Perhaps
	 * we should try connecting to servers we haven't heard from in a
	 * while here? 
	 */
	return;
    }

    server = [serverArray lastObject];
    [serverArray removeLastObject];

    /* Rotate the tiles in the list each time so we try them all */
    tile = [tiles objectAtIndex: 0];
    [tiles removeObjectAtIndex: 0];
    [server provideDataForTile:tile forClient: self];
    [tiles addObject: tile];
}

- (void) _setupFrames;
{
    unsigned int                stepIndex;

    if (frames)
	return;

    tiles = [[NSMutableArray alloc] init];
    frames = [[NSMutableArray alloc] init];

    for (stepIndex = 0; stepIndex < stepCount; stepIndex++) {
	NSString                   *filename;
	NSMutableArray             *orientation;
	NSMutableDictionary        *dict;
	Frame                      *newFrame;

	dict = [configuration mutableCopy];

	/* setup the filename for this frame */
	filename = [NSString stringWithFormat:filenameFormat, stepIndex + 1];
	[dict setObject:filename forKey:@"filename"];

	/* setup the orientation for this frame */
	orientation = [NSMutableArray array];
	[orientation addObject:[NSNumber numberWithDouble:startRr + stepIndex * stepRr]];
	[orientation addObject:[NSNumber numberWithDouble:startRi + stepIndex * stepRi]];
	[orientation addObject:[NSNumber numberWithDouble:startRj + stepIndex * stepRj]];
	[orientation addObject:[NSNumber numberWithDouble:startRk + stepIndex * stepRk]];
	[dict setObject:orientation forKey:@"orientation"];

	newFrame = [Frame frameWithConfiguration:dict frameNumber:stepIndex];
	[frames addObject:newFrame];
	[tiles addObjectsFromArray:[newFrame tilesToDo]];
    }
}

- (void) computeAnimation;
{
    [self _setupFrames];

    /* Give one tile to each server to start */
    while ([tiles count] && [serverArray count])
	[self resumeAnimation];
}

- (void) done
{
    abort();
#if 0
    NSEnumerator               *keyEnum;
    NSString                   *key;
    NSString                   *object;

    keyEnum = [serverTable keyEnumerator];
    while ((key = [keyEnum nextObject])) {
        object = [[serverTable objectForKey: key] nonretainedObjectValue];
	NSLog(@"Server:%@ completed %d tiles", object, [serverStatsDict objectForKey:object]);
    }
#endif
}


/* JuliaClientProtocol */
- (oneway void) acceptTile: (bycopy Tile *) aTile fromServer: server;
{
    abort();
#if 0
    int                         count;
    id                          tile = nil;
    unsigned int                frameNumber;
    ttile_t                     tileNum;

    frameNumber = [aTile frameNumber];
    tileNum = [aTile tileNum];

    count = [tiles count];
    while (count--) {
	tile = [tiles objectAtIndex:count];
	if ([tile tileNum] == tileNum &&
	    [tile frameNumber] == frameNumber) {
	    /* tile wasn't alread done */
	    NSString                   *serverName = @"Unknown";
	    int                         tilesCompleted;

	    tilesCompleted = [[serverStatsDict objectForKey:server] intValue] + 1;
#if 0
	    serverName = [serverTable objectForKey:server];
	    [serverStatsDict setObject:[NSNumber numberWithInt:tilesCompleted]
	     forKey:serverName];
#endif
	    [tiles removeObject:tile];
	    [delegate juliaClient: self didAcceptTile: aTile];
            [[frames objectAtIndex: frameNumber] markTileDone: aTile];
	    NSLog(@"%@ completed tile %d (%d total)."
		  @"  %d tiles left.\n", serverName, [aTile tileNum],
		  tilesCompleted, [tiles count]);
	    break;
	}
    }
   
    [serverArray addObject:server];
    [self resumeAnimation];
#endif
}

@end
