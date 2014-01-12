#import "matrix.hxx"


class bezierPatch {

public:

    matrix                      controlPoints[4];

    inline void setControlPoints(matrix const points[4])
    {
	controlPoints[0] = points[0];
	controlPoints[1] = points[1];
	controlPoints[2] = points[2];
	controlPoints[3] = points[3];
    }

    inline bezierPatch()
    {
    }

    inline bezierPatch(matrix const points[4])
    {
	setControlPoints(points);
    }

    inline bezierPatch operator =(bezierPatch const &patch)
    {
	controlPoints[0] = patch.controlPoints[0];
	controlPoints[1] = patch.controlPoints[1];
	controlPoints[2] = patch.controlPoints[2];
	controlPoints[3] = patch.controlPoints[3];

        return *this;
    }

    void patchPoints(vector *points, matrix const &screenTransform, long tSteps, long sSteps);
};
