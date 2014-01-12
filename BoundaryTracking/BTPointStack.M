extern "C" {
#import <Foundation/NSZone.h>
#import <ansi/string.h>  // memmove()
#import <stdio.h>
#import <OmniFoundation/assertions.h>
}

#import <BoundaryTracking/BTPointStack.H>

// You can turn this define off to debug stuff with smaller blocks of points
#define USE_VM_PAGES

#ifdef USE_VM_PAGES
# define PAGES_PER_BLOCK      (1)
# define BLOCK_SIZE           (NSPageSize() * PAGES_PER_BLOCK)
#else
# define BLOCK_SIZE (7 * sizeof(BTPoint))
#endif

#define MAX_POINTS_PER_BLOCK (BLOCK_SIZE / sizeof(BTPoint))


BTPoint *BTPointStack::_allocateBlock()
{
#ifdef USE_VM_PAGES
    return NSAllocateMemoryPages(BLOCK_SIZE);
#else
    return NSZoneMalloc(NSDefaultMallocZone(), BLOCK_SIZE);
#endif
}

void BTPointStack::_deallocateBlock(BTPoint *block)
{
#ifdef USE_VM_PAGES
    NSDeallocateMemoryPages(block, BLOCK_SIZE);
#else
    NSZoneFree(NSDefaultMallocZone(), block);
#endif
}


unsigned int BTPointStack::pointsPerPage()
{
    return MAX_POINTS_PER_BLOCK;
}

void BTPointStack::_allocateNewPartialPage()
{
    _partialPage = _allocateBlock();
    _partialPageInsertionPoint = _partialPage;
    _partialPageEmptyCount = MAX_POINTS_PER_BLOCK;
}

void BTPointStack::_partialPageFull()
{
    PRECONDITION(_partialPageEmptyCount == 0);

    _fullPages = (BTPoint **)NSZoneRealloc(NSDefaultMallocZone(), _fullPages, (_fullPageCount+1) * sizeof(BTPoint *));
    _fullPages[_fullPageCount] = _partialPage;
    _fullPageCount++;
    _allocateNewPartialPage();
}

void BTPointStack::_partialPageEmpty()
{
    PRECONDITION(_partialPageEmptyCount == MAX_POINTS_PER_BLOCK);
    PRECONDITION(_fullPageCount);
    
#warning Should keep a free list?
    _deallocateBlock(_partialPage);

    _fullPageCount--;
    _partialPage               = _fullPages[_fullPageCount];
    _partialPageInsertionPoint = _partialPage + MAX_POINTS_PER_BLOCK;
    _partialPageEmptyCount     = 0;
}

BTPointStack::BTPointStack()
{
    _fullPages = (BTPoint **) NSZoneMalloc(NSDefaultMallocZone(), sizeof(BTPoint *));
    _fullPageCount = 0;

    _allocateNewPartialPage();
}

BTPointStack::~BTPointStack()
{
    _deallocateBlock(_partialPage);
    while (_fullPageCount--)
        NSDeallocateMemoryPages(_fullPages[_fullPageCount], BLOCK_SIZE);
    NSZoneFree(NSDefaultMallocZone(), _fullPages);
}

unsigned int BTPointStack::count() const
{
    return _fullPageCount * MAX_POINTS_PER_BLOCK + (MAX_POINTS_PER_BLOCK - _partialPageEmptyCount);
}

void BTPointStack::getPopablePoints(BTPoint **points, unsigned int *popableCount) const
{
    if (_partialPageEmptyCount != MAX_POINTS_PER_BLOCK) {
        *points = _partialPage;
        *popableCount = MAX_POINTS_PER_BLOCK - _partialPageEmptyCount;
    } else if (_fullPageCount) {
        *points = _fullPages[_fullPageCount-1];
        *popableCount = MAX_POINTS_PER_BLOCK;
    }

    POSTCONDITION(*popableCount <= count());
}

void BTPointStack::popPoints(unsigned int popCount)
{
    unsigned int newCount = count() - popCount;
    PRECONDITION(popCount <= count());

    while (popCount) {
        unsigned int popFromPage;

        if (_partialPageEmptyCount == MAX_POINTS_PER_BLOCK)
            _partialPageEmpty();

        popFromPage = MIN(popCount, (MAX_POINTS_PER_BLOCK - _partialPageEmptyCount));

        _partialPageEmptyCount += popFromPage;
        _partialPageInsertionPoint -= popFromPage;
        popCount -= popFromPage;
    }

    POSTCONDITION(count() == newCount);
}

void BTPointStack::pushPoints(BTPoint *points, unsigned int pushCount)
{
    unsigned int newCount = count() + pushCount;
    
    while (pushCount) {
        unsigned int pushToPage;
        
        if (!_partialPageEmptyCount)
            _partialPageFull();

        pushToPage = MIN(_partialPageEmptyCount, pushCount);
        memmove(_partialPageInsertionPoint, points, sizeof(BTPoint) * pushToPage);

        _partialPageInsertionPoint += pushToPage;
        _partialPageEmptyCount -= pushToPage;
        pushCount -= pushToPage;
        points += pushToPage;
    }

    POSTCONDITION(count() == newCount);
}

void BTPointStack::print(const char *message, BOOL firstPageOnly) const
{
    unsigned int  pointCount;
    BTPoint      *points;

    fprintf(stderr, "%s (count = %d)\n", message, count());

    pointCount = MAX_POINTS_PER_BLOCK - _partialPageEmptyCount;
    points     = _partialPage;

    while (pointCount--) {
        fprintf(stderr, "\t<%d %d %d> = %d\n", points->x, points->y, points->z, points->state);
        points++;
    }
    fprintf(stderr, "\t--\n");

    if (firstPageOnly)
        return;

    int fullPageIndex;

    for (fullPageIndex = _fullPageCount - 1; fullPageIndex >= 0; fullPageIndex--) {
        pointCount = MAX_POINTS_PER_BLOCK;
        points = _fullPages[fullPageIndex];

        while (pointCount--) {
            fprintf(stderr, "\t<%d %d %d> = %d\n", points->x, points->y, points->z, points->state);
            points++;
        }
        fprintf(stderr, "\t--\n");
    }
}

