extern "C" {
#import <OmniFoundation/OmniUtilities.h>
#import <OmniFoundation/assertions.h>
#import <BoundaryTracking/BTController.h>
}

#import <BoundaryTracking/BTSparsePointSet.H>
#import <BoundaryTracking/BTPointStack.H>

#define CANDIDATE_STACK  ((BTPointStack *)candidateStack)
#define TO_PROCESS_STACK ((BTPointStack *)toProcessStack)
#define BOUNDARY_STACK   ((BTPointStack *)boundaryStack)
#define POINT_SET        ((BTSparsePointSet *)pointSet)


#define TIMER
#ifdef TIMER
#warning Timer code enabled!

#import <OmniTimer/OmniTimerNode.H>
OmniTimerNode totalTimer(@"Total Tile Time", NULL);
OmniTimerNode processPointsTimer(@"Process Points Timer", &totalTimer);
OmniTimerNode processBoundaryPointsTimer(@"Process Boundary Points Timer", &totalTimer);
OmniTimerNode pointSetTimer(@"Point Set Timer", &totalTimer);

#define TOTAL_START     totalTimer.start()
#define TOTAL_STOP      totalTimer.stop()
#define PROCESS_START   processPointsTimer.start()
#define PROCESS_STOP    processPointsTimer.stop()
#define BOUNDARY_START  processBoundaryPointsTimer.start()
#define BOUNDARY_STOP   processBoundaryPointsTimer.stop()
#define POINT_SET_START pointSetTimer.start()
#define POINT_SET_STOP  pointSetTimer.stop()

#else
#define TOTAL_START
#define TOTAL_STOP
#define PROCESS_START
#define PROCESS_STOP
#define BOUNDARY_START
#define BOUNDARY_STOP
#define POINT_SET_START
#define POINT_SET_STOP
#endif


@implementation BTController

- init;
{
    pointSet = new BTSparsePointSet();

    candidateStack = new BTPointStack();
    toProcessStack = new BTPointStack();
    boundaryStack = new BTPointStack();
    totalBoundaryPointsProcessed = 0;
    
    return self;
}


- (void) addBoundaryPoint: (BTPoint) point;
{
    // We'll just add this point to the candidateBoundaryPointQueue.  As it turns out, it should
    // end up having an exterior neighbor.  If it doesn't, then we'll get a degenerate
    // boundary.  Would probably be good to alert the caller to this condition with an
    // informative error message.  The only feedback they will get right now it that
    // their boundary has zero points

    point.state = BTPointInside;
    POINT_SET->recordPointState(point);
    CANDIDATE_STACK->pushPoint(point);
}

// We have a 3x3x3 cube of neighbors = 27 with the center left out.
// This could end up wasting up to 25 entries ... a pretty small percentage, really
#define MAX_NEIGHBOR_COUNT (26)

static inline void _addNeighbor(BTSparsePointSet *pointSet, BTPoint point,
                                BTPointState state, BTPointState newState, BTPointStack *stack)
{
    if (pointSet->stateForPoint(point) == state) {
        if (state != newState) {
            point.state = newState;
            pointSet->recordPointState(point);
        }
        stack->pushPoint(point);
    }
}

// Returns the actual number of neigbors added
static void _addNeighborsWithState(BTSparsePointSet *pointSet, BTPoint center,
                                   BTPointState state, BTPointState newState,
                                   BTPointStack *stack)
{
    BTPoint      neighbor;

    neighbor = center;
    neighbor.state = newState; // don't blindly copy the old state of the center point

    // Note, when we are calculating neighbor coordinates, we'll let each component
    // overflow or underflow, so we are sort of working in a weird 3d torus.

    // The top plane of neighbors
    neighbor.z++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x++; _addNeighbor(pointSet, neighbor, state, newState, stack);

    // The center doughnut of neighbors
    neighbor.z--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x++; _addNeighbor(pointSet, neighbor, state, newState, stack);

    // The bottom plane of neighbors
    neighbor.z--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y++; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.x--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y--; _addNeighbor(pointSet, neighbor, state, newState, stack);
    neighbor.y++;
    neighbor.x++; _addNeighbor(pointSet, neighbor, state, newState, stack);
}

static BOOL _isBoundaryPoint(BTSparsePointSet *pointSet, BTPoint center)
{
    BTPoint neighbor;
    
    neighbor = center;

    // Note, when we are calculating neighbor coordinates, we'll let each component
    // overflow or underflow, so we are sort of working in a weird 3d torus.

    // The top plane of neighbors
    neighbor.z++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;

    // The center doughnut of neighbors
    neighbor.z--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;

    // The bottom plane of neighbors
    neighbor.z--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.x--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y--; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;
    neighbor.y++;
    neighbor.x++; if (pointSet->stateForPoint(neighbor) == BTPointOutside) return YES;

    return NO;
}

- (void) _sendUnprocessedBoundaryPoints;
{

    totalBoundaryPointsProcessed += BOUNDARY_STACK->count();
    
    while (!BOUNDARY_STACK->isEmpty()) {
        BTPoint *boundaryPoint;
        unsigned int boundaryCount;

        BOUNDARY_STACK->getPopablePoints(&boundaryPoint, &boundaryCount);
        [self processBoundaryPoints: boundaryPoint count: boundaryCount];
        BOUNDARY_STACK->popPoints(boundaryCount);
    }

    [self processedBoundaryPoints];

    NSLog(@"Total Processed boundary points = %d,"
          @"points to process = %d, current candidate count = %d",
          totalBoundaryPointsProcessed, TO_PROCESS_STACK->count(), CANDIDATE_STACK->count());
}

- (void) processPoints;
{
    BTPointStack  oldCandidateStack, *tmpStack;
    BTPointStack *previousToProcessStack1, *previousToProcessStack2, *previousToProcessStack3, *previousToProcessStack4, *previousToProcessStack5;
    BTPoint      *candidatePoints;
    unsigned int  candidateCount, pointIndex;

#warning This fouth stack would not be necessary if I marked all of the boundary points before deciding on new candidates as noted below.  The fifth is probably necessary due to the positioning of the removal code in the loop.
    previousToProcessStack1 = new BTPointStack();
    previousToProcessStack2 = new BTPointStack();
    previousToProcessStack3 = new BTPointStack();
    previousToProcessStack4 = new BTPointStack();
    previousToProcessStack5 = new BTPointStack();

    TOTAL_START;
    
    // Keep looping until we haven't added any more candidates by the end of the loop
    while (!CANDIDATE_STACK->isEmpty()) {

        NSLog(@"Candidate count = %d", CANDIDATE_STACK->count());
        //CANDIDATE_STACK->print("candidateStack", NO);

        // Enqueue all of the neighbors of our candidates so that we can process them
        // and determine whether they really are boundary points
        while (!CANDIDATE_STACK->isEmpty()) {
            CANDIDATE_STACK->getPopablePoints(&candidatePoints, &candidateCount);

            pointIndex = candidateCount;
            ASSERT(pointIndex);
            while (pointIndex--) {
                POINT_SET_START;
                _addNeighborsWithState(pointSet, *candidatePoints,
                                       BTPointStateUnknown, BTPointCurrentlyProcessing,
                                       TO_PROCESS_STACK);
                POINT_SET_STOP;
                candidatePoints++;
            }

            oldCandidateStack.pushPoints(candidatePoints - candidateCount, candidateCount);
            //oldCandidateStack.print("oldCandidateStack (building)", NO);
            CANDIDATE_STACK->popPoints(candidateCount);
        }

        //oldCandidateStack.print("oldCandidateStack", NO);

        NSLog(@"\tProcess count = %d", TO_PROCESS_STACK->count());
        //TO_PROCESS_STACK->print("toProcessStack", NO);

        // Any points that were processed three loops ago are guaranteed to be past
        // the 'wavefront' of boundary candidacy due to the breadth first nature
        // of our algorithm.  This means that we can forget about the points altogether,
        // keeping our pointSet small and tidy.
        while (!previousToProcessStack5->isEmpty()) {
            BTPoint      *processPoints;
            unsigned int  processCount, processIndex;

            previousToProcessStack5->getPopablePoints(&processPoints, &processCount);

#ifdef REMOVE_OLD_POINTS
            processIndex = processCount;
            while (processIndex--) {
                POINT_SET->forgetPointState(*processPoints);
                processPoints++;
            }
#endif
            
            previousToProcessStack5->popPoints(processCount);
        }

        // Age the previousToProcessStacks
        tmpStack = previousToProcessStack5;
        previousToProcessStack5 = previousToProcessStack4;
        previousToProcessStack4 = previousToProcessStack3;
        previousToProcessStack3 = previousToProcessStack2;
        previousToProcessStack2 = previousToProcessStack1;
        previousToProcessStack1 = tmpStack;

        // We're going to load it with the points currently in TO_PROCESS_STACK
        ASSERT(!previousToProcessStack1->count());
        
        // Process all of the points in toProcessStack
        while (!TO_PROCESS_STACK->isEmpty()) {
            BTPoint      *processPoints;
            unsigned int  processCount;

            TO_PROCESS_STACK->getPopablePoints(&processPoints, &processCount);

            PROCESS_START;
            [self processPoints: processPoints count: processCount];
            PROCESS_STOP;
            
            //TO_PROCESS_STACK->print("toProcessStack (after processing)", YES);

            // Store the computed states
            pointIndex = processCount;
            while (pointIndex--) {
                // the state might be 'BTPointCurrentlyProcessing' since that is the
                // same thing as 'outside'
                ASSERT(processPoints->state != BTPointStateUnknown);

                POINT_SET->recordPointState(*processPoints);

                processPoints++;
            }

            previousToProcessStack1->pushPoints(processPoints - processCount, processCount);
            TO_PROCESS_STACK->popPoints(processCount);
        }

        // Loop through the old candidates.  Now that all of their neighbors have been processed
        // we can either toss them or put them on the boundary list.  When we put a new point
        // on the boundary, we'll enqueue its exterior neighbors on the candidates stack
        // (hence the need for the oldCandidateStack

        while (!oldCandidateStack.isEmpty()) {
            oldCandidateStack.getPopablePoints(&candidatePoints, &candidateCount);
            pointIndex = candidateCount;
            ASSERT(pointIndex);

            while (pointIndex--) {
                BOOL isBoundary;

                POINT_SET_START;
                isBoundary = _isBoundaryPoint((BTSparsePointSet *)pointSet, *candidatePoints);
                POINT_SET_STOP;
                
                if (isBoundary) {

#warning We should mark all the points as boundary points before looking for new candidates.  Otherwise, new boundary points may get enqueued as candidates again (although they will have no eligible neighbors, presumably).
                    if (POINT_SET->stateForPoint(*candidatePoints) != BTPointBoundary) {
                        ASSERT(POINT_SET->stateForPoint(*candidatePoints) == BTPointInside);
                        // This will prevent this from being nominated as a candidate again.
                        candidatePoints->state = BTPointBoundary;
                        POINT_SET->recordPointState(*candidatePoints);

                        BOUNDARY_STACK->pushPoint(*candidatePoints);
                        
                        // Enqueue inside neighbors as candidates
                        POINT_SET_START;
                        _addNeighborsWithState(pointSet, *candidatePoints,
                                               BTPointInside, BTPointInside,
                                               CANDIDATE_STACK);
                        POINT_SET_STOP;
                    }
                }

                candidatePoints++;
            }

            oldCandidateStack.popPoints(candidateCount);
        }

        NSLog(@"\tBoundary point count = %d", BOUNDARY_STACK->count());


        // Send all of the newly discovered boundary points to be processed
        // if we have at least a page worth
        if (BOUNDARY_STACK->count() >= 16 * BTPointStack::pointsPerPage()) {
            BOUNDARY_START;
            [self _sendUnprocessedBoundaryPoints];
            BOUNDARY_STOP;
        }
        
#ifdef TIMER
        // Report the partial results
        TOTAL_STOP;
        totalTimer.reportResults();
        TOTAL_START;
#endif
    }

    BOUNDARY_START;
    // Send any remaining points
    [self _sendUnprocessedBoundaryPoints];
    BOUNDARY_STOP;
    
    delete previousToProcessStack1;
    delete previousToProcessStack2;
    delete previousToProcessStack3;
    delete previousToProcessStack4;
    delete previousToProcessStack5;

#ifdef TIMER
    TOTAL_STOP;
    totalTimer.reportResults();
#endif

}

- (void) processedBoundaryPoints;
{
}

- (void) processBoundaryPoints: (BTPoint *) points count: (unsigned int) count;
{
    OmniRequestConcreteImplementation(isa, _cmd);
}

- (void) processPoints: (BTPoint *) points count: (unsigned int) count;
{
    OmniRequestConcreteImplementation(isa, _cmd);
}

@end
