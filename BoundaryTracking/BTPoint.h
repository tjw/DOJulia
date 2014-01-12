/* BTPoint.h created by bungi on Sat 26-Apr-1997 */

typedef enum _BTPointState {
    BTPointStateUnknown         = 0,
    BTPointCurrentlyProcessing  = 1,  // 1 means currently processing if the point has not been processed yet.
    BTPointOutside              = 1,  // 1 means index if the point has been processed.
    BTPointInside               = 2,
    BTPointBoundary             = 3
} BTPointState;

// This allows us to perform boundary tracking in spaces up to 1024 on a side
#define BT_EDGE_POWER    (10)
#define BT_MAX_EDGE_SIZE (1 << BT_EDGE_POWER)
#define BT_STATE_WIDTH   ((8 * sizeof(unsigned int)) - 3 * BT_EDGE_POWER)  // ie, 2

typedef struct {
   unsigned int         x : BT_EDGE_POWER;
   unsigned int         y : BT_EDGE_POWER;
   unsigned int         z : BT_EDGE_POWER;
   unsigned int     state : BT_STATE_WIDTH; // in some cases, this will be filled out with the state
} BTPoint;

