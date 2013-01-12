//
//  DPJSONConnection.m
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue


#import "DPJSONConnection.h"

static NSMutableArray *sharedConnectionList = nil;

@interface DPJSONConnection ()
@property (nonatomic, strong) NSURLConnection *internalConnection;
@property (nonatomic, strong) NSMutableData *container;
@end

@implementation DPJSONConnection

- (id)initWithRequest:(NSURLRequest *)request {
    self = [super init];
    if (self)
        self.request = request;
    return self;
}

- (void)start {
    self.container = [[NSMutableData alloc] init];
    self.internalConnection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:YES];
    if (!sharedConnectionList)
        sharedConnectionList = [[NSMutableArray alloc] init];
    [sharedConnectionList addObject:self];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.container appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (self.jsonRootObject) {
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:self.container options:0 error:nil];
        [self.jsonRootObject readFromJSONDictionary:d];
        if (self.completionBlock)
            self.completionBlock(self.jsonRootObject, nil);
    } else { // Didn't specify jsonRootObject, so going to return raw data
        if (self.completionBlock)
            self.completionBlock(self.container, nil);
    }
    [sharedConnectionList removeObject:self];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (self.completionBlock)
        self.completionBlock(nil, error);
    [sharedConnectionList removeObject:self];
}

@end
