//
//  DPHue.m
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

#import "DPHue.h"
#import "DPHueLight.h"
#import "DPJSONConnection.h"
#import "NSString+MD5.h"
#import "WSLog.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface DPHue ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *deviceType;
@property (nonatomic, strong, readwrite) NSURL *readURL;
@property (nonatomic, strong, readwrite) NSURL *writeURL;
@property (nonatomic, strong, readwrite) NSString *swversion;
@property (nonatomic, strong, readwrite) NSArray *lights;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, readwrite) BOOL authenticated;
@property (nonatomic, strong) void (^touchLightCompletionBlock)(BOOL success, NSString *result);

@end

@implementation DPHue

- (id)initWithHueHost:(NSString *)host username:(NSString *)username {
    self = [super init];
    if (self) {
        self.deviceType = @"QuickHue";
        self.authenticated = NO;
        self.host = host;
        self.username = username;
    }
    return self;
}

- (void)readWithCompletion:(void (^)(DPHue *, NSError *))block {
    NSURLRequest *req = [NSURLRequest requestWithURL:self.readURL];
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
    return [[[NSProcessInfo processInfo] globallyUniqueString] MD5String];
}

- (NSString *)description {
    NSMutableString *descr = [[NSMutableString alloc] init];
    [descr appendFormat:@"Name: %@\n", self.name];
    [descr appendFormat:@"Version: %@\n", self.swversion];
    [descr appendFormat:@"readURL: %@\n", self.readURL];
    [descr appendFormat:@"writeURL: %@\n", self.writeURL];
    [descr appendFormat:@"Number of lights: %lu\n", (unsigned long)self.lights.count];
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

// Sets _readURL and _writeURL based on _hostname, for the
// controller and all the lights managed by this controller.
- (void)updateURLs {
    _readURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@", self.host, self.username]];
    _writeURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/%@/config", self.host, self.username]];
    
    // As each DPHueLight maintains its own access URLs, they
    // too must be updated if URLs change.
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

- (void)triggerTouchlinkWithCompletion:(void (^)(BOOL success, NSString *))block {
    WSLog(@"Triggering Touchlink");
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if (![self.socket connectToHost:self.host onPort:30000 withTimeout:5 error:&err]) {
        WSLog(@"Error connecting to %@:30000 %@", self.host, err);
        return;
    }
    self.touchLightCompletionBlock = block;
    // After 5 seconds, stop
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 10), dispatch_get_current_queue(), ^{
        if (self.socket) {
            self.touchLightCompletionBlock(NO, @"No response after 10 sec");
            [self.socket disconnect];
            self.socket = nil;
        }
    });
}


#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    WSLog(@"Connected to %@:%d", host, port);
    NSData *data = [@"[Link,Touchlink]\n" dataUsingEncoding:NSUTF8StringEncoding];
    [sock writeData:data withTimeout:-1 tag:-1];
    NSMutableData *buffy = [[NSMutableData alloc] init];
    [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:5 buffer:buffy bufferOffset:0 tag:-1];
    WSLog(@"Sending: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag {
    NSMutableData *buffy = [[NSMutableData alloc] init];
    NSString *resultMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    WSLog(@"Received string: %@", resultMsg);
    if ([resultMsg rangeOfString:@"[Link,Touchlink,success"].location != NSNotFound) {
        // Touchlink found bulbs
        self.touchLightCompletionBlock(YES, resultMsg);
        [self.socket disconnect];
        self.socket = nil;
    } else if ([resultMsg rangeOfString:@"[Link,Touchlink,failed"].location != NSNotFound) {
        // Touchlink failed to find bulbs
        self.touchLightCompletionBlock(NO, resultMsg);
        [self.socket disconnect];
        self.socket = nil;
    } else {
        // We do not have a Touchlink result message yet, so keep receiving
        [self.socket readDataToData:[GCDAsyncSocket LFData] withTimeout:5 buffer:buffy bufferOffset:0 tag:-1];
    }
}

#pragma mark - DPJSONSerializable

- (void)readFromJSONDictionary:(id)d {
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
        _readURL = [a decodeObjectForKey:@"getURL"];
        _writeURL = [a decodeObjectForKey:@"putURL"];
        _lights = [a decodeObjectForKey:@"lights"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:_readURL forKey:@"getURL"];
    [a encodeObject:_writeURL forKey:@"putURL"];
    [a encodeObject:_host forKey:@"host"];
    [a encodeObject:_lights forKey:@"lights"];
    [a encodeObject:_username forKey:@"username"];
}

@end
