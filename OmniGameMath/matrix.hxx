extern "C" {
#import <math.h>
}

#import "vector.hxx"

#define DEGREES_TO_RADIANS(d)  ((d) * (M_PI / 180.0))

class matrix {

public:

    vector                      elem[4];

    inline matrix()
    {
    }

    inline void set(vector const &v0, vector const &v1, vector const &v2, vector const &v3)
    {
	elem[0] = v0;
	elem[1] = v1;
	elem[2] = v2;
	elem[3] = v3;
    }

    inline matrix(matrix const &m)
    {
        set(m.elem[0], m.elem[1], m.elem[2], m.elem[3]);
    }

    inline matrix(vector const &v0, vector const &v1, vector const &v2, vector const &v3)
    {
        set(v0, v1, v2, v3);
    }

    inline void bezierForwardDifference(float delta)
    {
	float                      delta2 = delta * delta;
	float                      delta3 = delta2 * delta;
    
	elem[0].x = 0;                    elem[1].x = 0;                     elem[2].x = 0;      elem[3].x = 1;
        elem[0].y = delta3;               elem[1].y = delta2;                elem[2].y = delta;  elem[3].y = 0;
        elem[0].z = ((float)6) * delta3;  elem[1].z = ((float)2) * delta2;   elem[2].z = 0;      elem[3].z = 0;
        elem[0].w = ((float)6) * delta3;  elem[1].w = 0;                     elem[2].w = 0;      elem[3].w = 0;
    }

    inline void swapHandedness()
    {
	elem[0].x =  1;  elem[1].x =  0;  elem[2].x =   0;  elem[3].x = 0;
        elem[0].y =  0;  elem[1].y =  1;  elem[2].y =   0;  elem[3].y = 0;
        elem[0].z =  0;  elem[1].z =  0;  elem[2].z =  -1;  elem[3].z = 0;
        elem[0].w =  0;  elem[1].w =  0;  elem[2].w =   0;  elem[3].w = 1;
    }

    inline matrix transpose() const
    {
	matrix t;

	t.elem[0].x = elem[0].x; t.elem[0].y = elem[1].x; t.elem[0].z = elem[2].x; t.elem[0].w = elem[3].x;
	t.elem[1].x = elem[0].y; t.elem[1].y = elem[1].y; t.elem[1].z = elem[2].y; t.elem[1].w = elem[3].y;
	t.elem[2].x = elem[0].z; t.elem[2].y = elem[1].z; t.elem[2].z = elem[2].z; t.elem[2].w = elem[3].z;
	t.elem[3].x = elem[0].w; t.elem[3].y = elem[1].w; t.elem[3].z = elem[2].w; t.elem[3].w = elem[3].w;

        return t;
    }

    inline void translate(float tx, float ty, float tz)
    {
	elem[0].x =  1;  elem[1].x =  0;  elem[2].x =  0;  elem[3].x = tx;
        elem[0].y =  0;  elem[1].y =  1;  elem[2].y =  0;  elem[3].y = ty;
        elem[0].z =  0;  elem[1].z =  0;  elem[2].z =  1;  elem[3].z = tz;
        elem[0].w =  0;  elem[1].w =  0;  elem[2].w =  0;  elem[3].w = 1;
    }

    inline void scale(float sx, float sy, float sz)
    {
	elem[0].x = sx;  elem[1].x =  0;  elem[2].x =  0;  elem[3].x =  0;
        elem[0].y =  0;  elem[1].y = sy;  elem[2].y =  0;  elem[3].y =  0;
        elem[0].z =  0;  elem[1].z =  0;  elem[2].z = sz;  elem[3].z =  0;
        elem[0].w =  0;  elem[1].w =  0;  elem[2].w =  0;  elem[3].w =  1;
    }

    inline void identity()
    {
        scale(1.0, 1.0, 1.0);
    }

    inline void rotateX(float a)
    {
        float s, c;

	s = sin(a);
        c = cos(a);

	elem[0].x =  1;  elem[1].x =  0;  elem[2].x =  0;  elem[3].x =  0;
        elem[0].y =  0;  elem[1].y =  c;  elem[2].y = -s;  elem[3].y =  0;
        elem[0].z =  0;  elem[1].z =  s;  elem[2].z =  c;  elem[3].z =  0;
        elem[0].w =  0;  elem[1].w =  0;  elem[2].w =  0;  elem[3].w =  1;
    }

    inline void rotateY(float a)
    {
        float s, c;

	s = sin(a);
        c = cos(a);

	elem[0].x =  c;  elem[1].x =  0;  elem[2].x =  s;  elem[3].x =  0;
        elem[0].y =  0;  elem[1].y =  1;  elem[2].y =  0;  elem[3].y =  0;
        elem[0].z = -s;  elem[1].z =  0;  elem[2].z =  c;  elem[3].z =  0;
        elem[0].w =  0;  elem[1].w =  0;  elem[2].w =  0;  elem[3].w =  1;
    }

    inline void rotateZ(float a)
    {
        float s, c;

	s = sin(a);
        c = cos(a);

	elem[0].x =  c;  elem[1].x = -s;  elem[2].x =  0;  elem[3].x =  0;
        elem[0].y =  s;  elem[1].y =  c;  elem[2].y =  0;  elem[3].y =  0;
        elem[0].z =  0;  elem[1].z =  0;  elem[2].z =  1;  elem[3].z =  0;
        elem[0].w =  0;  elem[1].w =  0;  elem[2].w =  0;  elem[3].w =  1;
    }

    inline void rotateXDegrees(float a)
    {
        float radians = DEGREES_TO_RADIANS(a);
        rotateX(radians);
    }

    inline void rotateYDegrees(float a)
    {
        float radians = DEGREES_TO_RADIANS(a);
        rotateY(radians);
    }

    inline void rotateZDegrees(float a)
    {
        float radians = DEGREES_TO_RADIANS(a);
        rotateZ(radians);
    }

    inline void perspective(float dist)
    {
	elem[0].x = 1;   elem[1].x = 0;   elem[2].x = 0;           elem[3].x = 0;
        elem[0].y = 0;   elem[1].y = 1;   elem[2].y = 0;           elem[3].y = 0;
        elem[0].z = 0;   elem[1].z = 0;   elem[2].z = 1;           elem[3].z = 0;
        elem[0].w = 0;   elem[1].w = 0;   elem[2].w = 1.0 / dist;  elem[3].w = 0;
    }

    inline void homogenize()
    {
	elem[0] /= elem[0].w;
	elem[1] /= elem[1].w;
	elem[2] /= elem[2].w;
	elem[3] /= elem[3].w;
    }

    inline vector operator *(vector const &v) const
    {
	vector r;

	r.x = v.x * elem[0].x + v.y * elem[1].x + v.z * elem[2].x + v.w * elem[3].x;
	r.y = v.x * elem[0].y + v.y * elem[1].y + v.z * elem[2].y + v.w * elem[3].y;
	r.z = v.x * elem[0].z + v.y * elem[1].z + v.z * elem[2].z + v.w * elem[3].z;
	r.w = v.x * elem[0].w + v.y * elem[1].w + v.z * elem[2].w + v.w * elem[3].w;

        return r;
    }

    // Write the matrix/matrix multiply in terms of matrix/vector multiplies
    // Declare this as a friend function to make sure we get a*b instead of b*a
    inline friend matrix operator *(const matrix &a, const matrix &b)
    {
	matrix                      t;

        t.elem[0] = a * b.elem[0];
        t.elem[1] = a * b.elem[1];
        t.elem[2] = a * b.elem[2];
        t.elem[3] = a * b.elem[3];

        return t;
    }

    inline matrix operator =(matrix const &m)
    {
	elem[0] = m.elem[0];
	elem[1] = m.elem[1];
	elem[2] = m.elem[2];
	elem[3] = m.elem[3];

        return *this;
    }
};

