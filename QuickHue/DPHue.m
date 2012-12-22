//
//  DPHue.m
//  HueProto
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPHue.h"
#import "DPHueLight.h"
#import "DPJSONConnection.h"
#import "NSString+MD5.h"

@interface DPHue ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *deviceType;
@property (nonatomic, strong, readwrite) NSURL *getURL;
@property (nonatomic, strong, readwrite) NSURL *putURL;
@property (nonatomic, strong, readwrite) NSString *host;
@property (nonatomic, strong, readwrite) NSString *swversion;
@property (nonatomic, strong, readwrite) NSArray *lights;
@property (nonatomic, readwrite) BOOL authenticated;

@end

@implementation DPHue

- (id)initWithHueControllerIP:(NSString *)host {
    self = [super init];
    if (self) {
        self.deviceType = @"test1";
        self.authenticated = NO;
        self.username = @"3c24efdac3d8a40baeda32579444743f";
        self.ip = ip;
        self.getURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@", ip, self.username]];
        self.putURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@/config", ip, self.username]];
        self.host = host;
    }
    return self;
}

- (void)readWithCompletion:(void (^)(DPHue *, NSError *))block {
    NSURLRequest *req = [NSURLRequest requestWithURL:self.getURL];
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:req];
    connection.completionBlock = block;
    connection.jsonRootObject = self;
    [connection start];
}

+ (NSString *)generateUsername {
    return [[[NSHost currentHost] name] MD5String];
}

- (NSString *)description {
    NSMutableString *descr = [[NSMutableString alloc] init];
    [descr appendFormat:@"Name: %@\n", self.name];
    [descr appendFormat:@"Version: %@\n", self.swversion];
    [descr appendFormat:@"Number of lights: %lu\n", self.lights.count];
    for (DPHueLight *light in self.lights) {
        [descr appendString:light.description];
        [descr appendString:@"\n"];
    }
    return descr;
}

- (void)allLightsOff {
    for (DPHueLight *light in self.lights) {
        light.on = NO;
        [light write];
    }
}

- (void)allLightsOn {
    for (DPHueLight *light in self.lights) {
        light.on = YES;
        [light write];
    }
}

- (void)writeAll {
    for (DPHueLight *light in self.lights)
        [light writeAll];
}

#pragma mark - DPJSONSerializable

- (void)readFromJSONDictionary:(id) d {
    if (![d respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        // We were given an array, not a dict, which means
        // Hue is giving us a result array, which (in this case)
        // means error: not authenticated
        self->_authenticated = NO;
        return;
    }
    self->_name = d[@"config"][@"name"];
    if (self->_name)
        self->_authenticated = YES;
    self->_swversion = d[@"config"][@"swversion"];
    NSMutableArray *tmpLights = [[NSMutableArray alloc] init];
    for (NSDictionary *lightDict in d[@"lights"]) {
        DPHueLight *light = [[DPHueLight alloc] init];
        [light readFromJSONDictionary:d[@"lights"][lightDict]];
        NSString *getURLString = [NSString stringWithFormat:@"http://%@/api/%@/lights/%@", self.host, self.username, lightDict];
        light.getURL = [NSURL URLWithString:getURLString];
        light.putURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/state", getURLString]];
        [tmpLights addObject:light];
    }
    self->_lights = tmpLights;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        self->_deviceType = @"test1";
        self->_username = @"3c24efdac3d8a40baeda32579444743f";
        self->_host = [a decodeObjectForKey:@"host"];
        self->_getURL = [a decodeObjectForKey:@"getURL"];
        self->_putURL = [a decodeObjectForKey:@"putURL"];
        self->_lights = [a decodeObjectForKey:@"lights"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:self->_getURL forKey:@"getURL"];
    [a encodeObject:self->_putURL forKey:@"putURL"];
    [a encodeObject:self->_host forKey:@"host"];
    [a encodeObject:self->_lights forKey:@"lights"];
}

@end
