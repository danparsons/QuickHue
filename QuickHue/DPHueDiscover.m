//
//  DPHueDiscover.m
//  QuickHue
//
//  Created by Dan Parsons on 12/21/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import "DPHueDiscover.h"
#import "DPJSONConnection.h"

@interface DPHueDiscover ()
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) BOOL foundHue;
@end

@implementation DPHueDiscover

- (id)initWithDelegate:(id<DPHueDiscoverDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)discover {
    WSLog(@"Starting discovery");
    self.udpSocket = [self createSocket];
    NSString *msg = @"M-SEARCH * HTTP/1.1\r\nHost: 239.255.255.250:1900\r\nMan: ssdp:discover\r\nMx: 3\r\nST: \"ssdp:all\"\r\n\r\n";
    NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:msgData toHost:@"239.255.255.250" port:1900 withTimeout:-1 tag:0];
    
    // 5 seconds later, stop discovering
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        [self stopDiscovery];
    });
}

- (void)stopDiscovery {
    WSLog(@"Stopping discovery");
    [self.udpSocket close];
    self.udpSocket = nil;
}

- (GCDAsyncUdpSocket *)createSocket {
    GCDAsyncUdpSocket *socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    
    if (![socket bindToPort:0 error:&error])
        WSLog(@"Error binding: %@", error.description);
    if (![socket beginReceiving:&error])
        WSLog(@"Error receiving: %@", error.description);
    [socket enableBroadcast:YES error:&error];
    if (error)
        WSLog(@"Error enabling broadcast: %@", error.description);
    return socket;
}

- (void)searchForHueAt:(NSURL *)url {
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:req];
    connection.completionBlock = ^(NSData *data, NSError *err) {
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        // If this string is found, then url == hue!
        if ([msg rangeOfString:@"Philips hue bridge 2012"].location != NSNotFound) {
            if ([self.delegate respondsToSelector:@selector(foundHueAt:)]) {
                if (!self.foundHue) {
                    [self.delegate foundHueAt:url.host];
                    self.foundHue = YES;
                }
            }
        } else {
            // Host is not a Hue
        }
    };
    [connection start];
}

#pragma mark - GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg) {
        //NSRegularExpression *reg = [[NSRegularExpression alloc] initWithPattern:@"LOCATION:(.*?)xml" options:0 error:nil];
        NSRegularExpression *reg = [[NSRegularExpression alloc] initWithPattern:@"http:\\/\\/(.*?)description\\.xml" options:0 error:nil];
        NSArray *matches = [reg matchesInString:msg options:0 range:NSMakeRange(0, msg.length)];
        if (matches.count > 0) {
            NSTextCheckingResult *result = matches[0];
            NSString *matched = [msg substringWithRange:[result rangeAtIndex:0]];
            NSURL *url = [NSURL URLWithString:matched];
            [self searchForHueAt:url];
        }
    }
}

@end
