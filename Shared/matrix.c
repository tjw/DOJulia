#import <DOJuliaShared/matrix.h>
#import <stdio.h>
#import <math.h>

void matrixIdentity(matrix I)
{
  I[0][0] =  1;  I[0][1] =  0;  I[0][2] =  0;  I[0][3] = 0;
  I[1][0] =  0;  I[1][1] =  1;  I[1][2] =  0;  I[1][3] = 0;
  I[2][0] =  0;  I[2][1] =  0;  I[2][2] =  1;  I[2][3] = 0;
  I[3][0] =  0;  I[3][1] =  0;  I[3][2] =  0;  I[3][3] = 1;
}

/* Create matrix for translation by (tx, ty) 
*/
void matrixTranslate(matrix T, double tx, double ty, double tz) 
{
  T[0][0] =  1;  T[0][1] =  0;  T[0][2] =  0;  T[0][3] = 0;
  T[1][0] =  0;  T[1][1] =  1;  T[1][2] =  0;  T[1][3] = 0;
  T[2][0] =  0;  T[2][1] =  0;  T[2][2] =  1;  T[2][3] = 0;
  T[3][0] = tx;  T[3][1] = ty;  T[3][2] = tz;  T[3][3] = 1;
}


/* Create matrix for scaling x by factor sx and y by factor sy 
*/
void matrixScale(matrix S, double sx, double sy, double sz)
{
  S[0][0] = sx;  S[0][1] =  0;  S[0][2] =  0;  S[0][3] = 0;
  S[1][0] =  0;  S[1][1] = sy;  S[1][2] =  0;  S[1][3] = 0;
  S[2][0] =  0;  S[2][1] =  0;  S[2][2] = sz;  S[2][3] = 0;
  S[3][0] =  0;  S[3][1] =  0;  S[3][2] =  0;  S[3][3] = 1;
}


/* Create matrix for rotation by alpha (alpha in radians) around x-axis
*/
void matrixRotateX(matrix R, double a)
{
  R[0][0] = 1;  R[0][1] =       0;  R[0][2] =      0;  R[0][3] = 0;
  R[1][0] = 0;  R[1][1] =  cos(a);  R[1][2] = sin(a);  R[1][3] = 0;
  R[2][0] = 0;  R[2][1] = -sin(a);  R[2][2] = cos(a);  R[2][3] = 0;
  R[3][0] = 0;  R[3][1] =       0;  R[3][2] =      0;  R[3][3] = 1;
}

/* Create matrix for rotation by alpha (alpha in radians) around y-axis
*/
void matrixRotateY(matrix R, double a)
{
  R[0][0] =  cos(a);  R[0][1] =  0;  R[0][2] = -sin(a);  R[0][3] = 0;
  R[1][0] =       0;  R[1][1] =  1;  R[1][2] =       0;  R[1][3] = 0;
  R[2][0] =  sin(a);  R[2][1] =  0;  R[2][2] =  cos(a);  R[2][3] = 0;
  R[3][0] =       0;  R[3][1] =  0;  R[3][2] =       0;  R[3][3] = 1;
}


/* Create matrix for rotation by alpha (alpha in radians) around z-axis
*/
void matrixRotateZ(matrix R, double a)
{
  R[0][0] =  cos(a);  R[0][1] = sin(a);  R[0][2] =  0;  R[0][3] = 0;
  R[1][0] = -sin(a);  R[1][1] = cos(a);  R[1][2] =  0;  R[1][3] = 0;
  R[2][0] =       0;  R[2][1] =      0;  R[2][2] =  1;  R[2][3] = 0;
  R[3][0] =       0;  R[3][1] =      0;  R[3][2] =  0;  R[3][3] = 1;
}


/* Multiplication of two 4-by-4 matrices: P = A * B 
*/ 
void matrixMult(matrix P, matrix A, matrix B)   
{
  int i, j;

  for (i = 0; i < 4; i++) 
    for (j = 0; j < 4; j++) 
      P[i][j] =
        A[i][0] * B[0][j] +
        A[i][1] * B[1][j] +
        A[i][2] * B[2][j] +
        A[i][3] * B[3][j];
}


/*
 * Transform point p by transformation matrix T [p.x p.y 1] = [p.x p.y 1] * T 
 */
void matrixTransformPoint(matrix T, point *p)   
{
  point q;

  q.x = p->x * T[0][0] + p->y * T[1][0] + p->z * T[2][0] + T[3][0];
  q.y = p->x * T[0][1] + p->y * T[1][1] + p->z * T[2][1] + T[3][1]; 
  q.z = p->x * T[0][2] + p->y * T[1][2] + p->z * T[2][2] + T[3][2];

  p->x = q.x;
  p->y = q.y;
  p->z = q.z;
}


/* Print all elements of a 3-by-3 matrix
*/
void matrixPrint(matrix A)
{
  int i;

  for (i = 0; i < 4; i++)
    printf("%f %f %f %f\n", A[i][0], A[i][1], A[i][2], A[i][3]);
}
