#import <DOJuliaShared/point.h>

#define MATRIXDIM 4

#error Use matrix.hxx instead

typedef double matrix[MATRIXDIM][MATRIXDIM];

void matrixIdentity(matrix I);
void matrixTranslate(matrix T, double tx, double ty, double tz);
void matrixScale(matrix S, double sx, double sy, double sz);
void matrixRotateX(matrix R, double a);
void matrixRotateY(matrix R, double a);
void matrixRotateZ(matrix R, double a);
void matrixMult(matrix P, matrix A, matrix B);
void matrixPrint(matrix A);
void matrixTransformPoint(matrix T, point *p);
