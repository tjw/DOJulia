#import "types.h"
#import "quaternion.hxx"

#import <math.h>

#define N_COLORS 4
#define max(a,b) ((a)>(b) ? (a) : (b))
#define min(a,b) ((a)<(b) ? (a) : (b))

@class NSMutableData;

typedef struct {
    int                 nc, nr;
    NSMutableData      *pixelData;
    color_t            *pixelBytes;
} ImageTile;

ImageTile *tileNew(int rows, int cols);
void   tileFree(ImageTile *t);

static inline int offsetForPixel(ImageTile *t, int x, int y)
{
  int             pos = y * t->nc + x;

#ifdef DEBUG
  if (x >= t->nc || y >= t->nr || x < 0 || y < 0) {
    fprintf(stderr, "Coord out of bounds (%d,%d)!\n", x, y);
    exit(1);
  }
#endif

  return pos;
}

static inline color_t *tilePixel(ImageTile *t, int x, int y)
{
  return t->pixelBytes + offsetForPixel(t, x, y); 
}

static inline ImageTile *tileSetPixel(ImageTile *t, int x, int y, color_t c)
{
  color_t *pixel = tilePixel(t, x, y);

  *pixel        = c;
  return t;
}
