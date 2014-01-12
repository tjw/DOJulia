#import "NSArrayExtensions.h"

@implementation NSArray (Extensions)

- (NSMutableArray *)randomizedArray;
{
    NSUInteger count = [self count];
    if (count < 2)
	return [self mutableCopy];

    NSMutableArray *selfCopy = [[NSMutableArray alloc] initWithArray:self];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    while (count--) {
	NSUInteger objectIndex = random() % (count + 1);
	id object = [selfCopy objectAtIndex:objectIndex];
	[selfCopy removeObjectAtIndex:objectIndex];
	[result addObject:object];
    }

    return result;
}

@end
