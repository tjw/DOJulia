
class vector {

public:

    float                       x, y, z, w;

    inline vector()
    {
    };

    inline vector(vector const &v)
    {
	x = v.x;
	y = v.y;
	z = v.z;
	w = v.w;
    };

    inline vector(float x0, float y0, float z0, float w0 = 0.0)
    {
	x = x0;
	y = y0;
	z = z0;
	w = w0;
    }

    inline vector &operator +=(vector const &a)
    {
	x += a.x;
	y += a.y;
	z += a.z;
	w += a.w;
	return *this;
    }

    inline vector &operator -=(vector const &a)
    {
	x -= a.x;
	y -= a.y;
	z -= a.z;
	w -= a.w;
	return *this;
    }

    inline vector &operator *=(float a)
    {
	x *= a;
	y *= a;
	z *= a;
	w *= a;
	return *this;
    }

    inline vector &operator /=(float a)
    {
        float invA = (1.0 / a);
	x *= invA;
	y *= invA;
	z *= invA;
	w *= invA;
	return *this;
    }

/*  For some reason the compiler complains about this ...
    inline vector operator -() const
    {
	vector                       temp;
    
	temp.x = -x;
	temp.y = -y;
	temp.z = -z;
	temp.w = -w;
	return temp;
    }
*/

    inline vector operator = (const vector &a)
    {
	x = a.x;
	y = a.y;
	z = a.z;
	w = a.w;

        return *this;
    }

    inline vector operator + (const vector &a) const
    {
	vector                       temp;
    
	temp.x = x + a.x;
	temp.y = y + a.y;
	temp.z = z + a.z;
	temp.w = w + a.w;
	return temp;
    }

    inline vector operator - (const vector& a) const
    {
	vector                       temp;
    
	temp.x = x - a.x;
	temp.y = y - a.y;
	temp.z = z - a.z;
	temp.w = w - a.w;
	return temp;
    }

    inline vector operator * (float a) const
    {
	vector                       temp;
    
	temp.x = x * a;
	temp.y = y * a;
	temp.z = z * a;
	temp.w = w * a;
	return temp;
    }

    inline vector operator / (float a) const
    {
	float      invA = (1.0 / a);
	vector     temp;
    
	temp.x = x * invA;
	temp.y = y * invA;
	temp.z = z * invA;
	temp.w = w * invA;
	return temp;
    }

    inline bool operator == (const vector &a) const
    {
        return x == a.x &&
               y == a.y &&
               z == a.z &&
               w == a.w;
    }

    inline vector homogenize() const
    {
        vector t;
        float invW = 1.0 / w;

        t.x = x * invW;
        t.y = y * invW;
        t.z = z * invW;
        t.w = 1.0;

        return t;
    }

    inline float dot (vector const &v) const
    {
	return x * v.x +
               y * v.y +
               z * v.z + 
               w * v.w;
    }

    inline float length() const
    {
	return sqrt(x*x + y*y + z*z + w*w);
    }

    inline vector normalized() const
    {
        return *this / length();
    }

    // Dunno if this is correct for homogenous coordinates
    // or not, but it might come in useful someday
    inline vector cross (vector const &v) const
    {
	vector r;

	r.x = y * v.z - z * v.y;
        r.y = z * v.x - x * v.z;
        r.z = x * v.y - y * v.x;
        r.w = 1;

        return r;
    }
};
