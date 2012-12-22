//
//  DPHueLight.h
//  HueProto2
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPJSONSerializable.h"

@interface DPHueLight : NSObject <DPJSONSerializable, NSCoding>

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong) NSNumber *brightness; // 0-255
@property (nonatomic, strong, readonly) NSString *colorMode; // "xy", "ct" or "hs"
@property (nonatomic, strong) NSNumber *hue; // in degrees*182, 0-65535
@property (nonatomic, strong) NSNumber *saturation; // 0-255
@property (nonatomic) BOOL on;
@property (nonatomic, readonly) BOOL reachable;
@property (nonatomic, strong) NSArray *xy; // CIE 1931 color coordinates
@property (nonatomic, strong, readonly) NSString *swversion;
@property (nonatomic, strong, readonly) NSString *type;
@property (nonatomic, strong) NSURL *getURL;
@property (nonatomic, strong) NSURL *putURL;
@property (nonatomic, strong, readonly) NSString *modelid;
@property (nonatomic, strong) NSNumber *colorTemperature; // in mireds 154-500
@property (nonatomic, strong) NSNumber *transitionTime; // if 0, instant changes
@property (nonatomic) BOOL holdUpdates;

- (void)read;
- (void)write;
- (void)writeAll;
- (void)flashOnce;
- (void)flashRepeatedly;
- (void)stopFlashing;

@end
