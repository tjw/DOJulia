#import <AppKit/AppKit.h>
#import "DOJuliaController.h"

@implementation DOJuliaController

#define DEPTH_DEFAULT @"NXWindowDepthLimit"
#define DEPTH_VALUE   @"TestTwentyFourBitRGB"

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
#if 0
    NSString *defValue;
    NSUserDefaults *defaults;

    /* Make sure the TestTwentyFourBitRGB default is set for this app */
    defaults = [NSUserDefaults standardUserDefaults];
    defValue = [defaults stringForKey: DEPTH_DEFAULT];
    if (![defValue isEqualToString: DEPTH_DEFAULT]) {
	NSRunAlertPanel([[NSProcessInfo processInfo] processName],
                 @"Loading defaults.  App will not print correctly until next time you run it.",
                 @"Ok", nil, nil);

        [defaults setObject: DEPTH_VALUE forKey: DEPTH_DEFAULT];
        [defaults synchronize];
    }
#endif
}

@end
