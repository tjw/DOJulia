
#import "types.h"
#import "julia.h"
#import "OWJuliaNormalApproximation.h"
#import "map.h"

double OWJuliaNormalDotApproximation(JuliaContext *context, quaternion *orbit)
{
    int i;
    double d[3], plusE, minusE;
    quaternion eyeToP, xGrad, yGrad, zGrad, grad, p;
    double tmp;

    p = orbit[0];

    const map *m = context->m;
    
    /* compute gradient to surface at p in units (not quaternions) */
    for (i = 0; i < 3; i++) {
        dem_label label;

        orbit[0] = m->basis[i] * context->delta + p;

        label = juliaLabel(context, orbit);
        plusE = context->dist;
#ifdef PRINT
        printf("%d +label = %d, dist = %f ", i, (int)label, plusE);
#endif

        orbit[0] = m->basis[i] * -context->delta + p;

        label = juliaLabel(context, orbit);
        minusE = context->dist;
#ifdef PRINT
        printf("-label = %d, dist = %f\n", (int)label, minusE);
#endif

        d[i] = plusE - minusE;
    }

    /* compute quaternion vector from p to eyepoint and normalize */
    eyeToP = (m->eyePoint - p).normalized();

    /* make a normalized quaternion out of the gradient */
    xGrad = m->basis[0] * d[0];
    yGrad = m->basis[1] * d[1];
    zGrad = m->basis[2] * d[2];

    grad = (xGrad + yGrad + zGrad).normalized();

    /* dot the two vectors to get our magnitude */
    tmp = grad.dot(eyeToP);
    return fabs(tmp);
}
