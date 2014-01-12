#import <OmniDocument/OmniDocument.h>

@class JuliaClient;

@interface DOJuliaDocument : OmniDocument
{
    id                          tileView;
    JuliaClient                *client;
}

- startComputing: sender;
- stopComputing: sender;

@end
