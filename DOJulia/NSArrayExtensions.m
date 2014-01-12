#import "NSArrayExtensions.h"
#import <bsd/libc.h>

@implementation NSArray (Extensions)

- (NSArray *) randomizedArray;
{
    NSMutableArray             *array, *selfCopy;
    unsigned int                count;

    if ((count = [self count]) < 2)
	return self;

    selfCopy = [[[NSMutableArray alloc] initWithArray: self] autorelease];
    array = [NSMutableArray arrayWithCapacity:count];
    while (count--) {
	NSObject                   *object;
	unsigned int                index;

	index = random() % (count + 1);
	object = [selfCopy objectAtIndex:index];
	[selfCopy removeObjectAtIndex:index];
	[array addObject:object];
    }

    return array;
}

@end
