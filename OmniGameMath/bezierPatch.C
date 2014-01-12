#import "bezierPatch.hxx"
#import "bezier.hxx"

#define SETUP_A(A, G, comp) \
    A.elem[0].x = G[0].elem[0].comp;  A.elem[1].x = G[1].elem[0].comp;    A.elem[2].x = G[2].elem[0].comp;    A.elem[3].x = G[3].elem[0].comp;	\
    A.elem[0].y = G[0].elem[1].comp;  A.elem[1].y = G[1].elem[1].comp;    A.elem[2].y = G[2].elem[1].comp;    A.elem[3].y = G[3].elem[1].comp;	\
    A.elem[0].z = G[0].elem[2].comp;  A.elem[1].z = G[1].elem[2].comp;    A.elem[2].z = G[2].elem[2].comp;    A.elem[3].z = G[3].elem[2].comp;	\
    A.elem[0].w = G[0].elem[3].comp;  A.elem[1].w = G[1].elem[3].comp;    A.elem[2].w = G[2].elem[3].comp;    A.elem[3].w = G[3].elem[3].comp;


static inline void stepS(matrix &tmpDDx, matrix &tmpDDy, matrix &tmpDDz)
{
    tmpDDx.elem[0] += tmpDDx.elem[1];
    tmpDDx.elem[1] += tmpDDx.elem[2];
    tmpDDx.elem[2] += tmpDDx.elem[3];

    tmpDDy.elem[0] += tmpDDy.elem[1];
    tmpDDy.elem[1] += tmpDDy.elem[2];
    tmpDDy.elem[2] += tmpDDy.elem[3];

    tmpDDz.elem[0] += tmpDDz.elem[1];
    tmpDDz.elem[1] += tmpDDz.elem[2];
    tmpDDz.elem[2] += tmpDDz.elem[3];
}

static inline void stepV(vector &v)
{
    v.x += v.y;
    v.y += v.z;
    v.z += v.w;
}

void bezierPatch::patchPoints(vector *points, matrix const &transform,
                                  long tSteps, long sSteps)
{
    bezierPatch                 transformedPatch;
    matrix                      DDx, DDy, DDz;
    matrix                      Ax, Ay, Az;
    matrix                      Cx, Cy, Cz;
    matrix                      Es, Et, EtT;
    vector                     *p = points;

    /* Perform transform and change from homogeneous coordinates to screen coordinates */
    transformedPatch.controlPoints[0] = transform * controlPoints[0];
    transformedPatch.controlPoints[0].homogenize();

    transformedPatch.controlPoints[1] = transform * controlPoints[1];
    transformedPatch.controlPoints[1].homogenize();

    transformedPatch.controlPoints[2] = transform * controlPoints[2];
    transformedPatch.controlPoints[2].homogenize();

    transformedPatch.controlPoints[3] = transform * controlPoints[3];
    transformedPatch.controlPoints[3].homogenize();

    if (tSteps < 2)
	tSteps = 2;
    if (sSteps < 2)
	sSteps = 2;

    Es.bezierForwardDifference(1.0 / (sSteps - 1));
    Et.bezierForwardDifference(1.0 / (tSteps - 1));
    EtT = Et.transpose();

    SETUP_A(Ax, transformedPatch.controlPoints, x);
    Cx = BezierMatrix * Ax * BezierMatrix;
    DDx = Es *  Cx * EtT;

    SETUP_A(Ay, transformedPatch.controlPoints, y);
    Cy = BezierMatrix * Ay * BezierMatrix;
    DDy = Es * Cy * EtT;

    SETUP_A(Az, transformedPatch.controlPoints, z);
    Cz = BezierMatrix * Az * BezierMatrix;
    DDz = Es * Cz * EtT;

    while (sSteps--) {
	matrix                      tDDx(DDx), tDDy(DDy), tDDz(DDz);
	long                        tCount = tSteps;

	while (tCount--) {
	    *p++ = vector(tDDx.elem[0].x, tDDy.elem[0].x, tDDz.elem[0].x, 1);
	    stepV(tDDx.elem[0]);
	    stepV(tDDy.elem[0]);
	    stepV(tDDz.elem[0]);

	}

	stepS(DDx, DDy, DDz);
    }
}
