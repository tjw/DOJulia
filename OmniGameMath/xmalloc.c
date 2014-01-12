#import <stdio.h>
#import <libc.h>

#include "xmalloc.h"

void *xmalloc(size_t size)
{
    void                       *p = (void *)malloc(size);

    if (!p) {
	fprintf(stderr, "Out of memory!\n");
	exit(1);
    }
    return p;
}

void *xrealloc(void *mem, size_t newSize)
{
    if (!newSize && !mem)
	return mem;
    else if (!mem) {
	mem = malloc(newSize);
    } else if (!newSize) {
	free(mem);
	return NULL;
    } else {
	mem = realloc(mem, newSize);
    }

    if (!mem) {
	fprintf(stderr, "Out of memory!!!\n");
	exit(1);
    }

    return mem;
}
