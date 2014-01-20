extern "C" {
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "JuliaClient.h"
#import "Frame.h"
}

#import "JuliaServer.h"
#import "Tile.h"

@implementation JuliaClient
{
    NSMutableDictionary *_configuration;
    NSString *_filenameFormat;
    NSUInteger _stepCount;
    quaternion _startR, _stepR;
    
    JuliaServer *_server;
    NSUInteger _tilesCompleted;
    
    NSMutableArray *_tiles;
    NSMutableArray *_frames;
}

- init
{
    if (!(self = [super init]))
        return nil;

    _server = [JuliaServer sharedServer];

    return self;
}

@synthesize delegate = _weak_delegate;

- (NSArray *)frames;
{
    [self _setupFrames];
    return _frames;
}

- (BOOL)readConfigurationFromFileURL:(NSURL *)fileURL error:(NSError **)outError;
{
    NSData *configurationData = [[NSData alloc] initWithContentsOfURL:fileURL options:0 error:outError];
    if (!configurationData)
        return NO;
    
    _configuration = [NSPropertyListSerialization propertyListWithData:configurationData options:NSPropertyListMutableContainersAndLeaves format:NULL error:outError];
    if (!_configuration)
        return NO;
    
    _filenameFormat = [_configuration objectForKey:@"filenameFormat"];
    NSArray *orientationStep = [_configuration objectForKey:@"orientationStep"];
    NSArray *orientationStart = [_configuration objectForKey:@"orientationStart"];
    _stepCount = [[_configuration objectForKey:@"stepCount"] unsignedLongValue];

    _startR = quaternion([[orientationStart objectAtIndex:0] doubleValue],
                         [[orientationStart objectAtIndex:1] doubleValue],
                         [[orientationStart objectAtIndex:2] doubleValue],
                         [[orientationStart objectAtIndex:3] doubleValue]);

    _stepR = quaternion([[orientationStep objectAtIndex:0] doubleValue],
                        [[orientationStep objectAtIndex:1] doubleValue],
                        [[orientationStep objectAtIndex:2] doubleValue],
                        [[orientationStep objectAtIndex:3] doubleValue]);

    return YES;
}

- (void)resumeAnimation
{
    if ([_tiles count] == 0)
        return; // Done!

    // Submit all the pending tiles
    for (Tile *tile in _tiles)
        [_server provideDataForTile:tile forClient:self];
}

- (void)_setupFrames;
{
    if (_frames)
	return;

    _tiles = [[NSMutableArray alloc] init];
    _frames = [[NSMutableArray alloc] init];

    for (NSUInteger stepIndex = 0; stepIndex < _stepCount; stepIndex++) {
	NSMutableDictionary *dict = [_configuration mutableCopy];

	/* setup the filename for this frame */
	NSString *filename = [NSString stringWithFormat:_filenameFormat, stepIndex + 1];
	[dict setObject:filename forKey:@"filename"];

	/* setup the orientation for this frame */
        quaternion R = _startR + _stepR * stepIndex;
	NSMutableArray *orientation = [NSMutableArray array];
	[orientation addObject:[NSNumber numberWithDouble:R.r]];
	[orientation addObject:[NSNumber numberWithDouble:R.i]];
	[orientation addObject:[NSNumber numberWithDouble:R.j]];
	[orientation addObject:[NSNumber numberWithDouble:R.k]];
	[dict setObject:orientation forKey:@"orientation"];

	Frame *newFrame = [Frame frameWithConfiguration:dict frameNumber:stepIndex];
	[_frames addObject:newFrame];
	[_tiles addObjectsFromArray:[newFrame tilesToDo]];
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

    NSUInteger tileIndex = [_tiles indexOfObjectIdenticalTo:aTile];
    if (tileIndex != NSNotFound) {
        /* tile wasn't alread done (if we start submitting to multiple servers again) */
        _tilesCompleted++;

        [_tiles removeObjectAtIndex:tileIndex];
        [_weak_delegate juliaClient:self didAcceptTile:aTile];
        [_frames[frameNumber] markTileDone:aTile];
        //NSLog(@"Completed tile %p (%lu total).  %lu tiles left.\n", aTile, _tilesCompleted, [tiles count]);
    }

    // We submit all tiles up front right now
    //[self resumeAnimation];
}

@end
