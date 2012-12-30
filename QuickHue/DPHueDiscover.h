//
//  DPHueDiscover.h
//  QuickHue
//
//  Created by Dan Parsons on 12/21/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>

@protocol DPHueDiscoverDelegate <NSObject>
- (void)foundHueAt:(NSString *)host discoveryLog:(NSString *)log;
@end

@interface DPHueDiscover : NSObject <GCDAsyncUdpSocketDelegate>

@property (nonatomic, weak) id<DPHueDiscoverDelegate> delegate;

- (id)initWithDelegate:(id<DPHueDiscoverDelegate>)delegate;
- (void)discoverForDuration:(int)seconds withCompletion:(void (^)(NSMutableString *log))block;
- (void)stopDiscovery;

@end
