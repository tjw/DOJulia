#import "types.h"
#import "quaternion.hxx"

#import <math.h>

#define N_COLORS 4

@class NSMutableData;

typedef struct {
    NSUInteger nc, nr;
    CFMutableDataRef pixelData;
    color_t *pixelBytes;
} ImageTile;

ImageTile *tileNew(NSUInteger rows, NSUInteger cols);
void   tileFree(ImageTile *t);

static inline NSUInteger offsetForPixel(ImageTile *t, NSUInteger x, NSUInteger y)
{
  NSUInteger pos = y * t->nc + x;

#ifdef DEBUG
  if (x >= t->nc || y >= t->nr) {
    fprintf(stderr, "Coord out of bounds (%lu,%lu)!\n", x, y);
    exit(1);
  }
#endif

  return pos;
}

static inline color_t *tilePixel(ImageTile *t, NSUInteger x, NSUInteger y)
{
  return t->pixelBytes + offsetForPixel(t, x, y); 
}

static inline ImageTile *tileSetPixel(ImageTile *t, NSUInteger x, NSUInteger y, color_t c)
{
  color_t *pixel = tilePixel(t, x, y);

  *pixel        = c;
  return t;
}
