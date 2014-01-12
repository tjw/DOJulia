#import <AppKit/NSDocument.h>

@class JuliaClient;

@interface DOJuliaDocument : NSDocument

- (IBAction)startComputing:(id)sender;
- (IBAction)stopComputing:(id)sender;

@end
