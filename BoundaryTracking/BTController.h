/* BoundaryTracker.h created by bungi on Thu 24-Apr-1997 */

#import <Foundation/NSObject.h>
#import <BoundaryTracking/BTPoint.h>

@interface BTController : NSObject
{
    void         *pointSet;
    void         *candidateStack;
    void         *toProcessStack;
    void         *boundaryStack;

    unsigned int  totalBoundaryPointsProcessed;
}

- init;
// Initializes the receiver;

- (void) addBoundaryPoint: (BTPoint) point;
// This should be used to add the relatively few initial boundary points.

- (void) processPoints: (BTPoint *) points count: (unsigned int) count;
// This should be subclassed to process all of the points in the array.  The results of
// the processing should be placed in the same array.

- (void) processBoundaryPoints: (BTPoint *) points count: (unsigned int) count;
// This is called for the boundary points as they are found

- (void) processedBoundaryPoints;
// This is called at the end of each batch of boundary points (calls to -processBoundaryPoints:count:)

- (void) processPoints;
// Performs the boundary tracking algorithm on the points currently enqueued.

@end
