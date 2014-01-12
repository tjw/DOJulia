#import <objc/objc.h> /* For BOOL */


#import <OmniFoundation/assertions.h>


#define SHIFT (16)
#define SCALE (1 << SHIFT)
#define FIXED_IS_FLOAT

#define PRECISE
#if defined(DEBUG) && defined(PRECISE)
#	define CHECK_PRECISION(a) ASSERT(a)
#else
#	define CHECK_PRECISION(a)
#endif

#ifdef FIXED_IS_FLOAT
#	define fixedZero ((fixed){0.0})
#	define fixedOne  ((fixed){1.0})
#	define MAX_FIXED MAXFLOAT
#	define MIN_FIXED MINFLOAT
#else
#	define fixedZero ((fixed){0L})
#	define fixedOne  ((fixed){SCALE})
#	define MAX_FIXED 0x7fffffff
#	define MIN_FIXED 0x80000000
#endif



class fixed {
#ifdef FIXED_IS_FLOAT
    float                       value;
#else
    long                        value;
#endif

public:

/*** Constructors ***/

inline fixed()
{
};

inline fixed(fixed const & a)
{
    value = a.value;
}

inline fixed(long a)
{
#ifdef FIXED_IS_FLOAT
    value = a;
#else
    value = a << SHIFT;
#endif
}

inline fixed(float a)
{
#ifdef FIXED_IS_FLOAT
    value = a;
#else
    value = a * SCALE;
#endif
}

inline fixed(double a)
{
#ifdef FIXED_IS_FLOAT
    value = a;
#else
    value = a * SCALE;
#endif
}
  

/****** Conversions ******/

inline operator long() const
{
#ifdef FIXED_IS_FLOAT
    return (long)value;
#else
    return long (value / SCALE);
#endif
}

inline operator float() const
{
#ifdef FIXED_IS_FLOAT
    return (float)value;
#else
    return float (value) / SCALE;
#endif
}

inline operator double() const
{
#ifdef FIXED_IS_FLOAT
    return (float)value;
#else
    return double (value) / SCALE;
#endif
}

/****** Unary Operators ******/

inline fixed &operator +=(fixed const &a)
{
    value += a.value;
    return *this;
}

inline fixed &operator -=(fixed const &a)
{
    value -= a.value;
    return *this;
}

inline fixed &operator *=(fixed const &a)
{
#ifdef FIXED_IS_FLOAT
    value *= a.value;
#else
#ifdef sparc
    register fixed result;

    asm volatile (
	"smul %1, %2, %%o4\n"   	/* %o4    = [  L  ][     ] */
	"rd %%y, %%o5\n"        	/* %o5    = [     ][  H  ] */
	"srl %%o4, 0x10, %%o4\n"	/* %o4    = [  0  ][  L  ] */
	"sll %%o5, 0x10, %%o5\n"	/* %o5    = [  H  ][  0  ] */
	"or  %%o4, %%o5, %0\n"		/* result = [  H  ][  L  ] */
    : "=r" (result)
    : "r" (a.value), "r" (b.value)
    : "o4", "o5", "cc"
    );

    return result;
#endif /* sparc */
#endif
    return *this;
}

inline fixed &operator /=(fixed const &a)
{
#ifdef FIXED_IS_FLOAT
    return value /= a.value;
#else
#ifdef i386
  "xor eax, eax"
  "shrd eax, edx, 16"
  "sar edx, 16"
  "idiv ebx"
#else
    return value = ((long long)value * SCALE) / b.value;
#endif
#endif
    return *this;
}

inline fixed operator -() const
{
    fixed                       temp;

    temp.value = -value;
    return temp;
}

inline fixed inverse() const
{
    fixed                       temp;

#ifdef FIXED_IS_FLOAT
    temp.value = 1.0 / value;
#else
    temp.value = 1;
    temp /= *this;
#endif

    return temp;
}


/***** Binary operators *****/

inline fixed operator = (const fixed &a)
{
     value = a.value;
}

inline fixed operator + (const fixed &a) const
{
    fixed                       temp;

    temp.value = value + a.value;
    return temp;
}

inline fixed operator -(const fixed& a) const
{
    fixed                       temp;

    temp.value = value - a.value;
    return temp;
}

inline fixed operator *(const fixed& a) const
{
    fixed temp;
   
#ifdef FIXED_IS_FLOAT
    temp.value = value * a.value;
#else
#ifdef sparc
    asm volatile (
	"smul %1, %2, %%o4\n"   	/* %o4    = [  L  ][     ] */
	"rd %%y, %%o5\n"        	/* %o5    = [     ][  H  ] */
	"srl %%o4, 0x10, %%o4\n"	/* %o4    = [  0  ][  L  ] */
	"sll %%o5, 0x10, %%o5\n"	/* %o5    = [  H  ][  0  ] */
	"or  %%o4, %%o5, %0\n"		/* result = [  H  ][  L  ] */
    : "=r" (temp.value)
    : "r" (value), "r" (a.value)
    : "o4", "o5", "cc"
    );
#endif /* sparc */
#endif
    return temp;   
}

inline fixed operator /(const fixed& a) const
{
    fixed                       temp;

#ifdef FIXED_IS_FLOAT
    temp.value = value / a.value;
#else
    temp.value = ((long long)value * SCALE) / b.value;
#endif
    return temp;
}


/***** Comparison Operators *****/


inline int operator == (fixed const &a) const
{
    return value == a.value;
}

inline int operator != ( fixed const &a) const
{
    return value != a.value;
}

inline int operator > ( fixed const &a) const
{
    return value > a.value;
}

inline int operator < ( fixed const &a) const
{
    return value < a.value;
}

inline int operator >= ( fixed const &a) const
{
    return value >= a.value;
}

inline int operator <= ( fixed const &a) const
{
    return value <= a.value;
}

inline int operator || (fixed const &a) const
{
    return value || a.value;
}

/**** Shifting Operators ****/

inline fixed operator << (unsigned long s) const
{
    fixed                       temp;

#ifdef FIXED_IS_FLOAT
    temp.value = value * (1 << s);
#else
    temp.value = value << s;
#endif
    return temp;
}

inline fixed &operator <<= (unsigned long s)
{
#ifdef FIXED_IS_FLOAT
    value *= (1 << s);
#else
    value <<= s;
#endif
    return *this;
}

inline fixed operator >> (unsigned long s) const
{
    fixed                       temp;

#ifdef FIXED_IS_FLOAT
    temp.value = value / (1 << s);
#else
    temp.value = value >> s;
#endif
    return temp;
}

inline fixed &operator >>= (unsigned long s)
{
#ifdef FIXED_IS_FLOAT
    value /= (1 << s);
#else
    value >>= s;
#endif
    return *this;
}


/***** TRIG *****/

inline fixed cosine() const
{
    fixed                       temp;
    extern double               cos(double a);

    temp.value = (fixed) cos(value);
    return temp;
}

inline fixed sine() const
{
    fixed                       temp;
    extern double               sin(double a);

    temp.value = (fixed) sin((double)value);
    return temp;
}

};
