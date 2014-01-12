extern "C" {
#import <objc/objc.h>
}

#import "matrix.hxx"

static const matrix BezierMatrix(vector(-1,  3, -3, 1),
                                 vector( 3, -6,  3, 0),
                                 vector(-3,  3,  0, 0),
                                 vector( 1,  0,  0, 0));

class bezier {

public:

    matrix                      controlPoints;

    inline bezier()
    {
    }

    inline bezier(matrix const &points)
    {
	setControlPoints(points);
    }

    inline void setControlPoints(matrix const &points)
    {
	controlPoints = points;
    }
};


class bezierEnumerator {

    long                        stepsLeft;

public:

    matrix                      D;


    inline bezierEnumerator(bezier const &b, matrix const &transform, long steps)
    {
	matrix                      E;
    
	stepsLeft = steps;
	E.bezierForwardDifference(1 / stepsLeft);
    
	D = E * BezierMatrix * b.controlPoints * transform;
    }

    inline BOOL step()
    {
	D.elem[0].x += D.elem[1].x;
	D.elem[1].x += D.elem[2].x;
	D.elem[2].x += D.elem[3].x;

	D.elem[0].y += D.elem[1].y;
	D.elem[1].y += D.elem[2].y;
	D.elem[2].y += D.elem[3].y;

	D.elem[0].z += D.elem[1].z;
	D.elem[1].z += D.elem[2].z;
	D.elem[2].z += D.elem[3].z;

        stepsLeft--;
	return stepsLeft > 0;
    }
};
