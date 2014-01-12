/* BoundaryDisplayController.h created by bungi on Sat 24-May-1997 */

#import <AppKit/AppKit.h>

@interface BoundaryDisplayController : NSObject
{
    IBOutlet NSImageView *imageView;
}

- (void) displayFile: sender;

@end
