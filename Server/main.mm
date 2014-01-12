extern "C" {
#import <Foundation/Foundation.h>
}

#import "JuliaServer.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];

    NS_DURING {
	JuliaServer                *server = [[JuliaServer alloc] init];
	NSConnection               *connection;

        connection = [NSConnection defaultConnection];

        [connection setRootObject: server];

        if (![connection registerName: @"JuliaServer"]) {
            NSLog(@"Unable to register connection");
            exit(1);
        }

        [[NSRunLoop currentRunLoop] run];
    } NS_HANDLER {
	NSLog(@"exception raised:%@", [localException reason]);
    } NS_ENDHANDLER;

    [pool release];
}

