extern "C" {
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "config.h"
#import "JuliaClient.h"
#import "Frame.h"
}

#import "JuliaServer.h"
#import "Tile.h"

@implementation JuliaClient
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
    
    id <JuliaClientDelegate> delegate;
}

- init
{
    if (!(self = [super init]))
        return nil;

    /* Later, init this from some network query */
    serverArray = [[NSMutableArray alloc] init];
    serverTable = [[NSMutableDictionary alloc] init];
    serverStatsDict = [[NSMutableDictionary alloc] init];

    JuliaServer *server = [JuliaServer sharedServer];
    if (server) {
        [serverArray addObject:server];

        NSString *serverName = @"localhost";
        [serverTable setObject:serverName forKey:[NSValue valueWithNonretainedObject: server]];

        [serverStatsDict setObject:[NSNumber numberWithInt:0] forKey:serverName];
    }

    return self;
}

- (void)setDelegate:(id <JuliaClientDelegate>)aDelegate;
{
    delegate = aDelegate;
}

- (NSArray *) frames;
{
    [self _setupFrames];
    return frames;
}

- (BOOL)readConfigurationFromFileURL:(NSURL *)fileURL error:(NSError **)outError;
{
    NSData *configurationData = [[NSData alloc] initWithContentsOfURL:fileURL options:0 error:outError];
    if (!configurationData)
        return NO;
    
    configuration = [NSPropertyListSerialization propertyListWithData:configurationData options:NSPropertyListMutableContainersAndLeaves format:NULL error:outError];
    if (!configuration)
        return NO;
    
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

    return YES;
}

- (void) resumeAnimation
{
    id                  server;
    Tile               *tile;

    if (![tiles count])
	/* Done! */
	return;

    if (![serverArray count]) {
        NSLog(@"No servers available");
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


#pragma mark - JuliaClientProtocol

- (void)acceptTile:(Tile *)aTile fromServer:(id <JuliaServerProtocol>)server;
{
    //ttile_t                     tileNum = [aTile tileNum];

    NSUInteger frameNumber = [aTile frameNumber];

    NSUInteger tileIndex = [tiles indexOfObjectIdenticalTo:aTile];
    if (tileIndex != NSNotFound) {
        /* tile wasn't alread done */
        NSString *serverName = @"Unknown";
        
        NSUInteger tilesCompleted = [[serverStatsDict objectForKey:server] unsignedIntegerValue] + 1;
#if 0
        serverName = [serverTable objectForKey:server];
        [serverStatsDict setObject:[NSNumber numberWithInteger:tilesCompleted] forKey:serverName];
#endif
        [tiles removeObjectAtIndex:tileIndex];
        [delegate juliaClient:self didAcceptTile:aTile];
        [frames[frameNumber] markTileDone:aTile];
        NSLog(@"%@ completed tile %p (%lu total).  %lu tiles left.\n", serverName, aTile, tilesCompleted, [tiles count]);
    }

    [serverArray addObject:server];
    [self resumeAnimation];
}

@end
