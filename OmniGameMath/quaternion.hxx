extern "C" {
#import <objc/objc.h>
#import <math.h>
#import <stdio.h>
}

class quaternion {

public:

	double r, i, j, k;

        inline quaternion()
        {
        };

        inline quaternion(double r0, double i0, double j0, double k0)
        {
            r = r0;
            i = i0;
            j = j0;
            k = k0;
        };

        inline quaternion &operator += (quaternion const &a)
        {
            r += a.r;
            i += a.i;
            j += a.j;
            k += a.k;

            return *this;
        };

        inline quaternion &operator -= (quaternion const &a)
        {
            r -= a.r;
            i -= a.i;
            j -= a.j;
            k -= a.k;

            return *this;
        };

        inline quaternion &operator *= (double const &a)
        {
            r *= a;
            i *= a;
            j *= a;
            k *= a;

            return *this;
        };

        inline quaternion &operator /= (double const &a)
        {
            double invA = (1.0 / a);

            // multiplies are faster than divides -- we might lose some precision, though
            r *= invA;
            i *= invA;
            j *= invA;
            k *= invA;

            return *this;
        };

        inline quaternion operator = (quaternion const &a)
        {
            r = a.r;
            i = a.i;
            j = a.j;
            k = a.k;

            return *this;
        };

        inline quaternion operator + (quaternion const &a) const
        {
            quaternion temp;

            temp.r = r + a.r;
            temp.i = i + a.i;
            temp.j = j + a.j;
            temp.k = k + a.k;

            return temp;
        };

        inline quaternion operator + (double const &a) const
        {
            quaternion temp;

            temp.r = r + a;
            temp.i = i;
            temp.j = j;
            temp.k = k;

            return temp;
        };

        inline quaternion operator - (quaternion const &a) const
        {
            quaternion temp;

            temp.r = r - a.r;
            temp.i = i - a.i;
            temp.j = j - a.j;
            temp.k = k - a.k;

            return temp;
        };

        inline quaternion operator - () const
        {
            quaternion temp;

            temp.r = -r;
            temp.i = -i;
            temp.j = -j;
            temp.k = -k;

            return temp;
        };

        // Declare this as a friend function to make sure we get a*b instead of b*a
        // since this is non-commutative
        inline friend quaternion operator *(const quaternion &a, const quaternion &b)
        {
            quaternion temp;
  
            temp.r = a.r * b.r - a.i * b.i - a.j * b.j - a.k * b.k;
            temp.i = a.r * b.i + a.i * b.r + a.j * b.k - a.k * b.j;
            temp.j = a.r * b.j - a.i * b.k + a.j * b.r + a.k * b.i;
            temp.k = a.r * b.k + a.i * b.j - a.j * b.i + a.k * b.r;
  
            return temp;
        };

        inline quaternion operator * (double const &a) const
        {
            quaternion temp;
  
            temp.r = r * a;
            temp.i = i * a;
            temp.j = j * a;
            temp.k = k * a;
  
            return temp;
        };

        inline double dot (quaternion const &a) const
        {
            return r * a.r + i * a.i + j * a.j + k * a.k;
        };

        inline double magnitudeSquared() const
        {
           return this->dot(*this);
        };

        inline quaternion inverse() const
        {
            quaternion temp;
            double invMags;

            invMags = 1.0 / this->magnitudeSquared();

            temp.r =  r * invMags;
            temp.i = -i * invMags;
            temp.j = -j * invMags;
            temp.k = -k * invMags;

            return temp;
        };


        // Declare this as a friend function to make sure we get a/b instead of b/a
        // since this is non-commutative
        inline friend quaternion operator /(const quaternion &a, const quaternion &b)
        {
            return a * b.inverse();
        };

        inline quaternion operator / (double const &a) const
        {
            quaternion temp;
            double invA = (1.0 / a);

            // multiplies are faster than divides -- we might lose some precision, though
            temp.r = r * invA;
            temp.i = i * invA;
            temp.j = j * invA;
            temp.k = k * invA;
  
            return temp;
        };

        inline double distanceSquared(quaternion const &a) const
        {
            quaternion delta;

            delta = *this - a;
            return delta.magnitudeSquared();
        };

        inline BOOL withinEpsilon(quaternion const &a, double const &epsilon) const
        {
            double dr, di, dj, dk;
  
            if (((dr = fabs(r - a.r)) > epsilon) ||
                ((di = fabs(i - a.i)) > epsilon) ||
                ((dj = fabs(j - a.j)) > epsilon) ||
                ((dk = fabs(k - a.k)) > epsilon))
                return NO;

            return (dr * dr + di * di + dj * dj + dk * dk) < epsilon;
        };

        inline quaternion normalized() const
        {
            quaternion temp;
            double     mag;

            mag = magnitudeSquared();

            if (mag > 0.0)
                temp = *this / sqrt(mag);
            else
                temp = quaternion(0.0, 0.0, 0.0, 0.0);

            return temp;
        };

        inline void print(const char *s) const
        {
            fprintf(stderr, "%s <%f, %f, %f, %f>\n", s, r, i, j, k);
        }
    
    inline NSString *toString(void) const
    {
        return [NSString stringWithFormat:@"<%f, %f, %f, %f>", r, i, j, k];
    }

};
