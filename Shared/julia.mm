extern "C" {
#import <math.h>
#import <stdio.h>
}

#import "julia.h"

static dem_label juliaDistanceEstimate(OWJuliaContext *context, quaternion *orbit);

// optimization attempt declarsions
static dem_label juliaLabelNoRotationOpt1(OWJuliaContext *context, quaternion *orbit);
static dem_label juliaLabelNoRotationOpt2(OWJuliaContext *context, quaternion *orbit);
static dem_label juliaLabelNoRotationOpt3(OWJuliaContext *context, quaternion *orbit);

int juliaCalls      = 0;
int juliaIterations = 0;

//#define JUST_NO_ROTATION // this is useful when just running the compiler by hand to produce assembly

#ifndef JUST_NO_ROTATION

/* Iterated function:  z_{n+1} = z_n^2 + u */



//#define PRINT

static dem_label juliaDistanceEstimate(OWJuliaContext *context, quaternion *orbit)
{
    /* try to calculate distance */
    iteration    k = 0;
    quaternion   dz(1.0, 0.0, 0.0, 0.0);
    double       a, mags;
    
    mags = 1.0;

    while (k < context->n && mags < context->overflow) {
        dz = dz * orbit[k];
        dz *= 2.0;
        mags = dz.magnitudeSquared();
        k++;
    }
    if (mags >= context->overflow)
        return VERY_CLOSE;

    a = sqrt(orbit[context->n].magnitudeSquared());
    context->dist = 0.5 * a * log(a) / sqrt(mags);

    if (context->dist < context->delta)
        return DELTA_CLOSE;
    else
        return NOT_CLOSE;

}

// This version will dynamically switch between the two.  This is
// slightly slower than just statically calling the one you want
// if you already know
dem_label juliaLabel(OWJuliaContext *context, quaternion *orbit)
{
    if (context->rotation == 0.0)
        return juliaLabelNoRotationOpt3(context, orbit);
    else
        return juliaLabelRotation(context, orbit);
}

dem_label juliaLabelWithDistance(OWJuliaContext *context, quaternion *orbit)
{
    dem_label label;

    label = juliaLabel(context, orbit);
    
    if (context->n < context->N &&
        orbit[context->n].magnitudeSquared() >= RADIUS)
        return juliaDistanceEstimate(context, orbit);
    else
        return label;
}

// This is a general version that allows rotations
dem_label juliaLabelRotation(OWJuliaContext *context, quaternion *orbit)
{
    double                      mags = 0.0;
    quaternion                  rotU, temp, *orbitStepper, *lastOrbit;

    juliaCalls++;

    quaternion eITheta(context->crot, context->srot, 0, 0);
    quaternion eINegTheta(context->crot, -context->srot, 0, 0);
    rotU = eINegTheta * context->u;
    
    orbitStepper = orbit;
    lastOrbit = orbit + context->N;
    while (orbitStepper < lastOrbit && mags < RADIUS) {
        temp = *orbitStepper * *orbitStepper;
	orbitStepper++;
        *orbitStepper = eITheta * temp + rotU;

        mags = orbitStepper->magnitudeSquared();
    }

    juliaIterations += context->n;
    
    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
}

#endif // JUST_NO_ROTATION


// This is a specific version that doesn't allow rotations but is faster.
// This version takes about 75% of the execution time.
dem_label juliaLabelNoRotation(OWJuliaContext *context, quaternion *orbit)
{
    double                      mags = 0.0;
    quaternion                  z, *orbitStepper, *lastOrbit;

    juliaCalls++;

    orbitStepper = orbit;
    lastOrbit = orbit + context->N;
    z = orbit[0];
    
    while (orbitStepper < lastOrbit && mags < RADIUS) {
        z = z * z + context->u;
        orbitStepper++;
        *orbitStepper = z;

        mags = z.magnitudeSquared();
    }

    juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
}

#ifndef JUST_NO_ROTATION

double    juliaPotential(OWJuliaContext *context, quaternion *orbit)
{
  double a = sqrt(orbit[context->n-1].magnitudeSquared());
  return a / pow(2.0, (float)(context->n-1));
}

#endif // JUST_NO_ROTATION

//
//
//  Optimization attempts
//
//

// This version just inlines the C++ operators naively
// This version takes about 81% of the execution time.
dem_label juliaLabelNoRotationOpt1(OWJuliaContext *context, quaternion *orbit)
{
    double                      mags = 0.0;
    quaternion                  *orbitStepper, *lastOrbit;
    double                      zr, zi, zj, zk;
    double                      ur, ui, uj, uk;
    
    juliaCalls++;

    orbitStepper = orbit;
    lastOrbit    = orbit + context->N;
    
    zr = orbit->r;
    zi = orbit->i;
    zj = orbit->j;
    zk = orbit->k;
    ur = context->u.r;
    ui = context->u.i;
    uj = context->u.j;
    uk = context->u.k;
    
    // Perhaps it would be better to branch on overflow on 'mags'
    // and spend the extra loops rather than wasting a register
    // on RADIUS, which really doesn't have to be any particular
    // value -- just a large one
    
    while (orbitStepper < lastOrbit && mags < RADIUS) {
        double Zr, Zi, Zj, Zk;

        Zr = zr * zr - zi * zi - zj * zj - zk * zk + ur;
        Zi = zr * zi + zi * zr + zj * zk - zk * zj + ui;
        Zj = zr * zj - zi * zk + zj * zr + zk * zi + uj;
        Zk = zr * zk + zi * zj - zj * zi + zk * zr + uk;

        zr = Zr;
        zi = Zi;
        zj = Zj;
        zk = Zk;

        orbitStepper++;
        orbitStepper->r = zr;
        orbitStepper->i = zi;
        orbitStepper->j = zj;
        orbitStepper->k = zk;

        mags = zr * zr + zi * zi + zj * zj + zk * zk;
    }

    juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
}

// This version does some CSE on the above
// Runs at ~80%
dem_label juliaLabelNoRotationOpt2(OWJuliaContext *context, quaternion *orbit)
{
    double                       mags = 0.0;
    quaternion                  *orbitStepper, *lastOrbit;
    register double              zr, zi, zj, zk;
    
    juliaCalls++;

    orbitStepper = orbit;
    lastOrbit    = orbit + context->N;
    
    zr = orbit->r;
    zi = orbit->i;
    zj = orbit->j;
    zk = orbit->k;
    
    // Perhaps it would be better to branch on overflow on 'mags'
    // and spend the extra loops rather than wasting a register
    // on RADIUS, which really doesn't have to be any particular
    // value -- just a large one
    
    while (orbitStepper < lastOrbit && mags < RADIUS) {
        double ijk2Sum;
        double zr2;

        orbitStepper++;

        zr2     = zr * zr;
        ijk2Sum = zi * zi + zj * zj + zk * zk;

        zk      = 2 * zr * zk + context->u.k;
        zj      = 2 * zr * zj + context->u.j;
        zi      = 2 * zr * zi + context->u.i;
        zr      = zr2 - ijk2Sum + context->u.r;

        orbitStepper->r = zr;
        orbitStepper->i = zi;
        orbitStepper->j = zj;
        orbitStepper->k = zk;

        mags = zr2 + ijk2Sum;
    }

    juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
}

// This version attempts to order the operations better for the pipeline
// w/o reverting to assembly
dem_label juliaLabelNoRotationOpt3(OWJuliaContext *context, quaternion *orbit)
{
    double                       mags = 0.0;
    quaternion                  *orbitStepper, *lastOrbit;
    register double              zr, zi, zj, zk;
    
    juliaCalls++;

    orbitStepper = orbit;
    lastOrbit    = orbit + context->N;
    
    zr = orbit->r;
    zi = orbit->i;
    zj = orbit->j;
    zk = orbit->k;
    
    // Perhaps it would be better to branch on overflow on 'mags'
    // and spend the extra loops rather than wasting a register
    // on RADIUS, which really doesn't have to be any particular
    // value -- just a large one
    
    while (orbitStepper < lastOrbit && mags < RADIUS) {
        double ijk2Sum;
        double zr2;

        orbitStepper++;

        ijk2Sum = zi * zi + zj * zj + zk * zk;

        zk      = 2 * zr * zk + context->u.k;
        zr2     = zr * zr;
        
        zj      = 2 * zr * zj + context->u.j;
        orbitStepper->k = zk;

        zi      = 2 * zr * zi + context->u.i;
        orbitStepper->j = zj;

        zr      = zr2 - ijk2Sum + context->u.r;
        orbitStepper->i = zi;

        mags    = zr2 + ijk2Sum;        
        orbitStepper->r = zr;
    }

    juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

#warning FIXME:  The distance estimate should not be computed all the time.  This is not useful for the boundary tracking case
    if (context->n < context->N && mags >= RADIUS)
        //return juliaDistanceEstimate(context, orbit);
        return NOT_CLOSE;
    return IN_SET;
}

