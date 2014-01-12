extern "C" {
#import <libc.h>
#import "xmalloc.h"
}

#import "zbuffer.hxx"

#define Z(z,x,y) ((z)->depths + (y)*(z)->numCol + (x))

zbuffer *zbufferNew(unsigned int r, unsigned int c)
{
    size_t                      depthSize = sizeof(float) * r * c;
    zbuffer                    *z = (zbuffer *) xmalloc(sizeof(zbuffer));

    z->numRow = r;
    z->numCol = c;
    z->depths = (float *)xmalloc(depthSize);
    bzero(z->depths, depthSize);
    return z;
}

zbuffer *zbufferSetDepth(zbuffer * z, unsigned int row,
                         unsigned int col, float depth)
{
    float                     *d = Z(z, row, col);

    if (*d < depth)
	*d = depth;
    return z;
}


float zbufferDepth(zbuffer * z, unsigned int row, unsigned int col)
{
    return *Z(z, row, col);
}

