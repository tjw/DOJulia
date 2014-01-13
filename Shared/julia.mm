extern "C" {
#import <math.h>
#import <stdio.h>
}

#import "julia.h"

//static julia_result juliaDistanceEstimate(const JuliaContext *context, quaternion *orbit);

// optimization attempt declarsions
//static julia_result juliaLabelNoRotationOpt1(const JuliaContext *context, quaternion *orbit);
//static julia_result juliaLabelNoRotationOpt2(const JuliaContext *context, quaternion *orbit);
static julia_result juliaLabelNoRotationOpt3(const JuliaContext *context, quaternion *orbit);

//int juliaCalls      = 0;
//int juliaIterations = 0;

//#define JUST_NO_ROTATION // this is useful when just running the compiler by hand to produce assembly

#ifndef JUST_NO_ROTATION

/* Iterated function:  z_{n+1} = z_n^2 + u */



//#define PRINT

static julia_result juliaDistanceEstimate(const JuliaContext *context, julia_result result, quaternion *orbit)
{
    /* try to calculate distance */
    iteration    k = 0;
    quaternion   dz(1.0, 0.0, 0.0, 0.0);
    double       a, mags;
    
    mags = 1.0;

    while (k < result.n && mags < context->overflow) {
        dz = dz * orbit[k];
        dz *= 2.0;
        mags = dz.magnitudeSquared();
        k++;
    }
    if (mags >= context->overflow) {
        result.label = VERY_CLOSE;
        return result;
    }

    a = sqrt(orbit[result.n].magnitudeSquared());
    result.dist = 0.5 * a * log(a) / sqrt(mags);

    if (result.dist < context->delta)
        result.label = DELTA_CLOSE;
    else
        result.label = NOT_CLOSE;
    
    return result;
}

// This version will dynamically switch between the two.  This is
// slightly slower than just statically calling the one you want
// if you already know
julia_result juliaLabel(const JuliaContext *context, quaternion *orbit)
{
    if (context->rotation == 0.0)
        return juliaLabelNoRotationOpt3(context, orbit);
    else
        return juliaLabelRotation(context, orbit);
}

julia_result juliaLabelWithDistance(const JuliaContext *context, quaternion *orbit)
{
    julia_result result = juliaLabel(context, orbit);
    
    if (result.n < context->N &&
        orbit[result.n].magnitudeSquared() >= RADIUS)
        result = juliaDistanceEstimate(context, result, orbit);
    return result;
}

// This is a general version that allows rotations
julia_result juliaLabelRotation(const JuliaContext *context, quaternion *orbit)
{
    abort();
#if 0
    double                      mags = 0.0;
    quaternion                  rotU, temp, *orbitStepper, *lastOrbit;

    //juliaCalls++;

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

    //juliaIterations += context->n;
    
    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
#endif
}

#endif // JUST_NO_ROTATION


// This is a specific version that doesn't allow rotations but is faster.
// This version takes about 75% of the execution time.
julia_result juliaLabelNoRotation(const JuliaContext *context, quaternion *orbit)
{
    abort();
#if 0
    double                      mags = 0.0;
    quaternion                  z, *orbitStepper, *lastOrbit;

    //juliaCalls++;

    orbitStepper = orbit;
    lastOrbit = orbit + context->N;
    z = orbit[0];
    
    while (orbitStepper < lastOrbit && mags < RADIUS) {
        z = z * z + context->u;
        orbitStepper++;
        *orbitStepper = z;

        mags = z.magnitudeSquared();
    }

    //juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
#endif
}

#ifndef JUST_NO_ROTATION

double juliaPotential(julia_result result, quaternion *orbit)
{
  double a = sqrt(orbit[result.n-1].magnitudeSquared());
  return a / pow(2.0, (float)(result.n-1));
}

#endif // JUST_NO_ROTATION

//
//
//  Optimization attempts
//
//

// This version just inlines the C++ operators naively
// This version takes about 81% of the execution time.
dem_label juliaLabelNoRotationOpt1(JuliaContext *context, quaternion *orbit)
{
    abort();
#if 0
    double                      mags = 0.0;
    quaternion                  *orbitStepper, *lastOrbit;
    double                      zr, zi, zj, zk;
    double                      ur, ui, uj, uk;
    
    //juliaCalls++;

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

    //juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
#endif
}

// This version does some CSE on the above
// Runs at ~80%
dem_label juliaLabelNoRotationOpt2(JuliaContext *context, quaternion *orbit)
{
    abort();
#if 0
    double                       mags = 0.0;
    quaternion                  *orbitStepper, *lastOrbit;
    register double              zr, zi, zj, zk;
    
    //juliaCalls++;

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

    //juliaIterations += context->n;

    context->n = (orbitStepper - orbit);
    context->dist = 0.0;

    return IN_SET;
#endif
}

// This version attempts to order the operations better for the pipeline
// w/o reverting to assembly
julia_result juliaLabelNoRotationOpt3(const JuliaContext *context, quaternion *orbit)
{
    double                       mags = 0.0;
    quaternion                  *orbitStepper, *lastOrbit;
    register double              zr, zi, zj, zk;
    
    //juliaCalls++;

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
        //NSLog(@"  z=<%f, %f, %f, %f>, mags %f", zr, zi, zj, zk, mags);
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

    //juliaIterations += context->n;

    iteration n = (orbitStepper - orbit);
    julia_result r = {
        .n = n,
        .dist = 0.0,
    };
    //NSLog(@"  n = %ld", r.n);
    
    // TODO: The distance estimate should not be computed all the time.  This is not useful for the boundary tracking case
    if (r.n < context->N && mags >= RADIUS)
        //return juliaDistanceEstimate(context, orbit);
        r.label = NOT_CLOSE;
    else
        r.label = IN_SET;
    return r;
}

