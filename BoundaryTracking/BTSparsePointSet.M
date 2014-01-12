extern "C" {
#import <OmniFoundation/assertions.h>
}

#import <BoundaryTracking/BTSparsePointSet.H>

// Define the _BTPointRange class for real

// a future version of this should store ranges of states that are known
// and not stored unknown points at all since the vast majority of points
// are either inside or outside and nowhere near the boundary (so
// they will never be queried or set)

#define BT_STATES_PER_BLOCK ((sizeof(unsigned int) * 8) / BT_STATE_WIDTH)
#define BT_STATE_MASK       ((1 << BT_STATE_WIDTH) - 1)

class _BTPointRange {
    unsigned int stateBlocks[BT_MAX_EDGE_SIZE / BT_STATES_PER_BLOCK];

public:

    inline BTPointState stateForPosition(unsigned int position) const {
        unsigned stateBlock;
        unsigned blockIndex, positionIndex;

        blockIndex    = position / BT_STATES_PER_BLOCK;
        positionIndex = position & (BT_STATES_PER_BLOCK - 1);

        stateBlock    = stateBlocks[position / BT_STATES_PER_BLOCK];
        stateBlock  >>= (positionIndex * BT_STATE_WIDTH);
        return (BTPointState)(stateBlock & BT_STATE_MASK);
    }

    inline void recordStateForPosition(unsigned int position, unsigned int state) {
        unsigned int blockIndex, positionIndex;

        blockIndex               = position / BT_STATES_PER_BLOCK;
        positionIndex            = position & (BT_STATES_PER_BLOCK - 1);
        
        state                  <<= (positionIndex * BT_STATE_WIDTH);
        stateBlocks[blockIndex] &= ~(BT_STATE_MASK << (positionIndex * BT_STATE_WIDTH));
        stateBlocks[blockIndex] |= state;
    }
};


// Now, define BTSparsePointSet in terms of _BTPointRange
BTSparsePointSet::BTSparsePointSet()
{
    _ranges = (_BTPointRange **)NSZoneMalloc(NSDefaultMallocZone(),
                                             sizeof(_BTPointRange *) * BT_MAX_EDGE_SIZE * BT_MAX_EDGE_SIZE);
}

BTSparsePointSet::~BTSparsePointSet()
{
    NSZoneFree(NSDefaultMallocZone(), _ranges);
}

BTPointState BTSparsePointSet::stateForPoint(BTPoint point) const
{
    _BTPointRange *range;

    if (!(range = _rangeForPoint(point)))
        return BTPointStateUnknown;
    return range->stateForPosition(point.z);
}

void BTSparsePointSet::recordPointState(const BTPoint point)
{
    _BTPointRange *range;

    if (!(range = _rangeForPoint(point))) {
        range = NSZoneCalloc(NSDefaultMallocZone(), 1, sizeof(_BTPointRange));
        _setRangeForPoint(point, range);
    }
    
    range->recordStateForPosition(point.z, point.state);
}

void BTSparsePointSet::print() const
{
}


