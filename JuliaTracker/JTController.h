/* JTController.h created by bungi on Sat 26-Apr-1997 */

#import <BoundaryTracking/BTController.h>
#import <AppKit/NSImageView.h>

#define IBOutlet

@class OWJuliaContext;

@interface JTController : BTController
{
    IBOutlet NSImageView *imageView;
    NSImage              *image;
    NSBitmapImageRep     *imageRep;
    
    OWJuliaContext       *context;
    void                 *orbit;
    unsigned int          basin;
    void                 *boundaryZBuffer;

    double                scale;

    FILE                 *outputFile;
}

- (void) start: (id) sender;

@end
