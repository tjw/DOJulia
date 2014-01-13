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
    
    JuliaServer *_server;
    NSUInteger _tilesCompleted;
    
    NSMutableArray             *tiles;
    NSMutableArray             *frames;
    
    id <JuliaClientDelegate> delegate;
}

- init
{
    if (!(self = [super init]))
        return nil;

    _server = [JuliaServer sharedServer];

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

- (void)resumeAnimation
{
    if (![tiles count])
	/* Done! */
	return;

    // Submit all the pending tiles
    for (Tile *tile in tiles)
        [_server provideDataForTile:tile forClient:self];
}

- (void)_setupFrames;
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
        /* tile wasn't alread done (if we start submitting to multiple servers again) */
        _tilesCompleted++;

        [tiles removeObjectAtIndex:tileIndex];
        [delegate juliaClient:self didAcceptTile:aTile];
        [frames[frameNumber] markTileDone:aTile];
        //NSLog(@"Completed tile %p (%lu total).  %lu tiles left.\n", aTile, _tilesCompleted, [tiles count]);
    }

    // We submit all tiles up front right now
    //[self resumeAnimation];
}

@end
