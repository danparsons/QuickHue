//
//  DPHue.m
//  QuickHue
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
@property (nonatomic, strong, readwrite) NSString *swversion;
@property (nonatomic, strong, readwrite) NSArray *lights;
@property (nonatomic, readwrite) BOOL authenticated;

@end

@implementation DPHue

- (id)initWithHueIP:(NSString *)host username:(NSString *)username {
    self = [super init];
    if (self) {
        self.deviceType = @"QuickHue";
        self.authenticated = NO;
        //self.username = @"3c24efdac3d8a40baeda32579444743f";
        self.host = host;
        self.username = username;
    }
    return self;
}

- (void)readWithCompletion:(void (^)(DPHue *, NSError *))block {
    NSURLRequest *req = [NSURLRequest requestWithURL:self.getURL];
    WSLog(@"Reading %@", self.getURL);
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:req];
    connection.completionBlock = block;
    connection.jsonRootObject = self;
    [connection start];
}

- (void)registerUsername {
    NSDictionary *usernameDict = @{@"devicetype": self.deviceType, @"username": self.username};
    NSString *urlString = [NSString stringWithFormat:@"http://%@/api/", self.host];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *usernameJson = [NSJSONSerialization dataWithJSONObject:usernameDict options:0 error:nil];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
    req.HTTPMethod = @"POST";
    req.HTTPBody = usernameJson;
    DPJSONConnection *conn = [[DPJSONConnection alloc] initWithRequest:req];
    NSString *pretty = [[NSString alloc] initWithData:usernameJson encoding:NSUTF8StringEncoding];
    NSMutableString *msg = [[NSMutableString alloc] init];
    [msg appendFormat:@"Writing to: %@\n", req.URL];
    [msg appendFormat:@"Writing values: %@\n", pretty];
    WSLog(@"%@", msg);
    [conn start];
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

- (void)updateURLs {
    _getURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@", self.host, self.username]];
    _putURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@/config", self.host, self.username]];
    for (DPHueLight *light in self.lights) {
        light.host = self.host;
        light.username = self.username;
    }
}

- (void)setUsername:(NSString *)username {
    _username = username;
    [self updateURLs];
}

- (void)setHost:(NSString *)host {
    _host = host;
    [self updateURLs];
}

#pragma mark - DPJSONSerializable

- (void)readFromJSONDictionary:(id) d {
    if (![d respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        // We were given an array, not a dict, which means
        // Hue is giving us a result array, which (in this case)
        // means error: not authenticated
        _authenticated = NO;
        return;
    }
    _name = d[@"config"][@"name"];
    if (_name)
        _authenticated = YES;
    _swversion = d[@"config"][@"swversion"];
    NSMutableArray *tmpLights = [[NSMutableArray alloc] init];
    for (id lightItem in d[@"lights"]) {
        DPHueLight *light = [[DPHueLight alloc] init];
        [light readFromJSONDictionary:d[@"lights"][lightItem]];
        /*NSString *getURLString = [NSString stringWithFormat:@"http://%@/api/%@/lights/%@", self.host, self.username, lightDict];
        light.getURL = [NSURL URLWithString:getURLString];
        light.putURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/state", getURLString]];
        */
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        light.number = [f numberFromString:lightItem];
        light.username = self.username;
        light.host = self.host;
        [tmpLights addObject:light];
    }
    _lights = tmpLights;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        _deviceType = @"QuickHue";
        _username = [a decodeObjectForKey:@"username"];
        _host = [a decodeObjectForKey:@"host"];
        _getURL = [a decodeObjectForKey:@"getURL"];
        _putURL = [a decodeObjectForKey:@"putURL"];
        _lights = [a decodeObjectForKey:@"lights"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:_getURL forKey:@"getURL"];
    [a encodeObject:_putURL forKey:@"putURL"];
    [a encodeObject:_host forKey:@"host"];
    [a encodeObject:_lights forKey:@"lights"];
    [a encodeObject:_username forKey:@"username"];
}

@end
