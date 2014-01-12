#import <sys/types.h>

#define NEWTYPE(type)  (xmalloc(sizeof(type)))

void *xmalloc(size_t size);
void *xrealloc(void *mem, size_t newSize);
