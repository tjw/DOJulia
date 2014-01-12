/* SparsePointSet.h created by bungi on Thu 24-Apr-1997 */

extern "C" {
#import <Foundation/Foundation.h>
#import <BoundaryTracking/BTPoint.h>
}

// This class allows us to keep track of what points have been processed
// and what the determination was.  As an added bonus, we can determine
// if a point is currently being processed

class _BTPointRange;
class BTSparsePointSet {

    _BTPointRange **_ranges;

    inline _BTPointRange *_rangeForPoint(BTPoint point) const {
        return _ranges[(point.y << BT_EDGE_POWER) + point.x];
    }

    inline void _setRangeForPoint(BTPoint point, _BTPointRange *range) {
        _ranges[(point.y << BT_EDGE_POWER) + point.x] = range;
    }
        
public:

    BTSparsePointSet();
    ~BTSparsePointSet();

    BTPointState stateForPoint(BTPoint point) const;
    void recordPointState(BTPoint point);

    void print() const; 
};
