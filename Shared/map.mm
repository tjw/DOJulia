#import "map.h"

const map *map::makeMap(vector eye, double focusLength, double fov,
                        double rx, double ry, double rz, double scale,
                        double radius,
                        NSUInteger portWidth, NSUInteger portHeight)
{
    map *m = new map();
    
    matrix          Rx, Ry, Rz, S, B;
    double          xWidth;
    
    assert(focusLength > 0.0);
    assert(fov > 0.0);
    assert(radius > 0.0);
    
    /* Just some trivial parameters */
    m->boundingRadius = radius;
    m->portWidth = portWidth;
    m->portHeight = portHeight;
    
    /* Compute the composite rotation matrix for rx, ry, and rz */
    Rx.rotateX(rx);
    Ry.rotateY(ry);
    Rz.rotateZ(rz);
    
    S.scale(scale, scale, scale);
    
    B = S * Rx * Ry * Rz;
    
    /* Store quaternions used for advancing one unit along x, y, and z under the rotation matrix */
    vector b0, b1, b2;
    
    b0 = B * vector(1, 0, 0, 0);
    b1 = B * vector(0, 1, 0, 0);
    b2 = B * vector(0, 0, 1, 0);
    
    m->basis[0] = quaternion(b0.x, b0.y, b0.z, b0.w);
    m->basis[1] = quaternion(b1.x, b1.y, b1.z, b1.w);
    m->basis[2] = quaternion(b2.x, b2.y, b2.z, b2.w);
    
    /* Don't deal with the 'k' component here, this is done in the qrot() code */
    assert(m->basis[0].k == 0.0);
    assert(m->basis[1].k == 0.0);
    assert(m->basis[2].k == 0.0);
    
    fprintf(stderr, "Basis is:\n");
    fprintf(stderr, "B[0] = (%4.8f, %4.8f, %4.8f, %4.8f)\n",
            m->basis[0].r, m->basis[0].i, m->basis[0].j, m->basis[0].k);
    fprintf(stderr, "B[1] = (%4.8f, %4.8f, %4.8f, %4.8f)\n",
            m->basis[1].r, m->basis[1].i, m->basis[1].j, m->basis[1].k);
    fprintf(stderr, "B[2] = (%4.8f, %4.8f, %4.8f, %4.8f)\n",
            m->basis[2].r, m->basis[2].i, m->basis[2].j, m->basis[2].k);
    
    
    /* Compute the width of the screen from the focusLength and fov */
    xWidth = tan(fov/2.0) * focusLength;
    
    /*
     Store the size of the screen in object space.  Set the height to be appropriate
     for a 1.0 aspect ratio.
     */
    m->screenWidth = xWidth;
    m->screenHeight = (xWidth * portHeight) / (double) portWidth;
    
    /* Store the origin of the eye ray */
    m->eyePoint = quaternion(eye.x, eye.y, eye.z, 0.0);
    
    /* Figure the lower left hand point of the screen as represented in object space */
    {
        quaternion zDist, center;
        quaternion right, top, cornerOffset;
        
        /* Go out focusLength units along the z basis vector to find the center of the screen */
        zDist = m->basis[2] * focusLength;     /* focusLength * <z> */
        center = m->eyePoint + zDist;        /* the center of the screen */
        
        /* Compute the offsets to the right-center and center-top points of the screen */
        right = m->basis[0] * (m->screenWidth / 2.0);
        top   = m->basis[1] * (m->screenHeight / 2.0);
        
        /* Add the two offsets to find the offset to the upper right corner */
        cornerOffset = right + top;
        
        /* Finally, subtract the upper-right offset from the center point to find the lower-left point */
        m->lowerLeft = center - cornerOffset;
    }
    
    return m;
}

quaternion map::screenPoint(double screenX, double screenY) const
{
    double xUnits = ((double)screenX / (double)portWidth) * screenWidth;
    double yUnits = ((double)screenY / (double)portHeight) * screenHeight;
    
    quaternion xOffset = basis[0] * xUnits;
    quaternion yOffset = basis[1] * yUnits;
    
    return lowerLeft + xOffset + yOffset;
}
