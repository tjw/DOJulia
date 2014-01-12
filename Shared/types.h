#import <OmniGameMath/quaternion.hxx>

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

extern color_t  white;
extern color_t  black;
extern color_t  ltgrey;
extern color_t  dkgrey;

