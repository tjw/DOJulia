#import "quaternion.hxx"

typedef struct {
    quaternion                  normal;
    double                      dist;
    double                      opacity;
    int                         clips;
} plane_t;


typedef enum {IN_SET, VERY_CLOSE, DELTA_CLOSE, NOT_CLOSE} dem_label;
typedef unsigned long iteration;

typedef struct {
    unsigned char               r, g, b, a;
} color_t;

extern const color_t  white;
extern const color_t  black;
extern const color_t  ltgrey;
extern const color_t  dkgrey;

