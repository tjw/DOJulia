extern "C" {
#import <BoundaryTracking/BTPoint.h>
#import <objc/objc.h>
}

class BTPointStackEnumerator;

class BTPointStack {

    friend class BTPointStackEnumerator;

    BTPoint      **_fullPages;
    unsigned int   _fullPageCount;

    BTPoint       *_partialPage;
    BTPoint       *_partialPageInsertionPoint;
    unsigned int   _partialPageEmptyCount;

    static BTPoint *_allocateBlock();
    static void _deallocateBlock(BTPoint *block);
    
    void _allocateNewPartialPage();
    void _partialPageFull();
    void _partialPageEmpty();
    
public:

     BTPointStack();
    ~BTPointStack();

    // Returns the number of points in the stack
    unsigned int count() const;

    inline BOOL isEmpty() const {
        return (_partialPageInsertionPoint == _partialPage) && !_fullPageCount;
    }
    
    // Get a large range of points that can be operated on contigously.    
    void getPopablePoints(BTPoint **points, unsigned int *popableCount) const;

    // Pop the specified number of points.  This will typically be used
    // after calling getPopablePoints() (using popableCount as the count
    // to pop
    void popPoints(unsigned int popCount);
    
    // Pushes a large number of points all at once
    void pushPoints(BTPoint *points, unsigned int pushCount);

    // Pushes a single point.
    inline void pushPoint(BTPoint point) {
        unsigned int oldCount = count();
        
        if (!_partialPageEmptyCount)
            _partialPageFull();
        *_partialPageInsertionPoint = point;
        _partialPageInsertionPoint++;
        _partialPageEmptyCount--;

        POSTCONDITION(count() == oldCount + 1);
    };

    // Pops a single point.
    inline BTPoint popPoint() {
        unsigned int oldCount = count();
        
        if (_partialPageInsertionPoint == _partialPage)
            // This page is empty
            _partialPageEmpty();
        _partialPageEmptyCount++;
        _partialPageInsertionPoint--;

        POSTCONDITION(count() == oldCount - 1);
        return *_partialPageInsertionPoint;
    };

    void print(const char *message, BOOL firstPageOnly) const;

    // This methods are not really for general use, BTController needs them right now
    // to make it simple.  Later it would be good to have some sort of bulk enumerator.
    inline unsigned int pageCount() { return _fullPageCount; }
    inline unsigned int partialPageCount() { return _partialPageInsertionPoint - _partialPage; }
    inline BTPoint *page(unsigned int pageIndex) { return _fullPages[pageIndex]; }
    inline BTPoint *partialPage() { return _partialPage; }
    static unsigned int pointsPerPage();
    
};

class BTPointStackEnumerator {

    BTPoint      **_fullPages;
    unsigned int   _fullPagesLeft;
    BTPoint       *_nextPoint;
    unsigned int   _currentPagePointsLeft;

public:

    inline BTPointStackEnumerator(const BTPointStack *stack) {
        _fullPages      = stack->_fullPages;
        _fullPagesLeft  = stack->_fullPageCount;
        _nextPoint      = stack->_partialPage;
        _currentPagePointsLeft = stack->_partialPageInsertionPoint - stack->_partialPage;
    }

    inline BTPoint nextPoint() {
        if (!_currentPagePointsLeft) {
            ASSERT(_fullPagesLeft);
            _nextPoint = *_fullPages;
            _fullPages++;
            _fullPagesLeft--;
            _currentPagePointsLeft = BTPointStack::pointsPerPage();
        }
        _currentPagePointsLeft--;
        return *_nextPoint++;
    }

    inline void nextPoints(BTPoint *points, unsigned int *pointCount) {
#warning finish me
    }
};

