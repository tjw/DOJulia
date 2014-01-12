
typedef struct {
    unsigned int                numRow, numCol;
    float                      *depths;
} zbuffer;

zbuffer        *zbufferNew(unsigned int r, unsigned int c);
zbuffer        *zbufferSetDepth(zbuffer *z, unsigned int row,
                                unsigned int col, float depth);
float          zbufferDepth(zbuffer *z, unsigned int row, unsigned int col);
