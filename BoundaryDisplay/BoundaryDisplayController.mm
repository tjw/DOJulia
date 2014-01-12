/* BoundaryDisplayController.m created by bungi on Sat 24-May-1997 */

extern "C" {
#import "BoundaryDisplayController.h"
#import <BoundaryTracking/BTPoint.h>
}

#import <OmniGameMath/vector.hxx>

// This is a simple zbuffer class for use in producing images.
// Will need to move this code later.

class zbuffer {
   unsigned int  _width, _height;
   double       *_depths;

   inline double *_depthPointer(unsigned int x, unsigned int y) {
       return _depths + (y * _width + x);
   }

public:

   inline zbuffer(unsigned int width, unsigned int height) {
       _width  = width;
       _height = height;
       _depths = (double *)NSZoneCalloc(NSDefaultMallocZone(), 1, sizeof(*_depths) * _width * _height);
   }

   inline ~zbuffer() {
       NSZoneFree(NSDefaultMallocZone(), _depths);
   }

   inline void setDepth(unsigned int x, unsigned int y, double depth) {
       double currentDepth;

       currentDepth = *_depthPointer(x, y);
       if (currentDepth < depth)
           *_depthPointer(x, y) = depth;
   }

   inline double depth(unsigned int x, unsigned int y) {
       return *_depthPointer(x, y);
   }
};


@implementation BoundaryDisplayController

- (void) displayFile: sender;
{
    NSString         *fileName;
    NSData           *fileData;
    unsigned int      pointCount;
    zbuffer          *zb;
    const BTPoint    *points;
    unsigned int      x, y;
    unsigned char    *imageBytes;
    NSBitmapImageRep *imageRep;
    NSImage          *image;

    zb = new zbuffer(BT_MAX_EDGE_SIZE, BT_MAX_EDGE_SIZE);
    fileName = [sender stringValue];
    fileData = [[NSData alloc] initWithContentsOfMappedFile: fileName];
    if (!fileData) {
        NSLog(@"Cannot open %@", fileName);
        return;
    }

    pointCount = [fileData length] / sizeof(BTPoint);
    points     = (const BTPoint *)[fileData bytes];
    
    while (pointCount--) {
        // Later we'll probably want to do some perspective
        zb->setDepth(points->x, points->y, points->z);

        // Testing a goofy way to smooth stuff out
        zb->setDepth(points->x + 0, points->y + 1, points->z - 0.25);
        zb->setDepth(points->x + 1, points->y + 1, points->z - 0.5);
        zb->setDepth(points->x + 1, points->y + 0, points->z - 0.25);
        zb->setDepth(points->x + 1, points->y - 1, points->z - 0.5);
        zb->setDepth(points->x + 0, points->y - 1, points->z - 0.25);
        zb->setDepth(points->x - 1, points->y - 1, points->z - 0.5);
        zb->setDepth(points->x - 1, points->y + 0, points->z - 0.25);
        zb->setDepth(points->x - 1, points->y + 1, points->z - 0.5);
        
        points++;
    }
    
    [fileData release];

    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                       pixelsWide: BT_MAX_EDGE_SIZE
                                                       pixelsHigh: BT_MAX_EDGE_SIZE
                                                    bitsPerSample: 8
                                                  samplesPerPixel: 1
                                                         hasAlpha: NO
                                                         isPlanar: NO
                                                   colorSpaceName: NSCalibratedWhiteColorSpace
                                                      bytesPerRow: 0
                                                     bitsPerPixel: 0];

    image = [[NSImage alloc] initWithSize: NSMakeSize(BT_MAX_EDGE_SIZE, BT_MAX_EDGE_SIZE)];
    [image addRepresentation: imageRep];

    [imageView setFrameSize: [image size]];
    [imageView setImage: image];

    [imageRep release];
    [image release];
    
    imageBytes = [imageRep bitmapData];

    /*
     Compute an image by constructing a normal from the zbuffer.  Leave the edges alone
     to avoid having to deal with the the normal there.
     */

    vector toEye(0, 0, 1);
    
    for (y = 1; y < BT_MAX_EDGE_SIZE - 1; y++) {
        unsigned char *imageSpan;

        imageSpan = imageBytes + y * BT_MAX_EDGE_SIZE + 1;
        
        for (x = 1; x < BT_MAX_EDGE_SIZE - 1; x++) {
            double       depth, upperDepth, rightDepth;
            vector       center, right, up, normal;
            double       lightMagnitude;
            
            depth      = zb->depth(x, y);
            rightDepth = zb->depth(x + 1, y);
            upperDepth = zb->depth(x, y + 1);

            center = vector(0, 0, depth);
            right  = vector(1, 0, rightDepth) - center;
            up     = vector(0, 1, upperDepth) - center;

            if (center.z == 0 && up.z == 0 && right.z == 0) {
                // Don't bother doing the cross or normalization -- these are way slow
                lightMagnitude = 0.0;
            } else {
                right = right.normalized();
                up    = up.normalized();

                normal = up.cross(right);

                lightMagnitude = 1.0 - normal.dot(toEye);
            }

            *imageSpan = (unsigned char) (lightMagnitude * 255);
            imageSpan++;
        }
    }
         
    [imageView display];
    [[NSDPSContext currentContext] wait];
    delete zb;
}

@end
