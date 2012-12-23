//
//  DPHueLight.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPHueLight.h"
#import "DPJSONConnection.h"

@interface DPHueLight ()
@property (nonatomic, readwrite) BOOL reachable;
@property (nonatomic, strong, readwrite) NSString *swversion;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSString *modelid;
@property (nonatomic, strong, readwrite) NSString *colorMode;
@property (nonatomic, strong) NSMutableDictionary *pendingChanges;
@property (nonatomic, readwrite) BOOL writeSuccess;
@property (nonatomic, strong, readwrite) NSMutableString *writeMessage;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSURL *getURL;
@property (nonatomic, strong, readwrite) NSURL *putURL;

@end

@implementation DPHueLight

- (id)init {
    self = [super init];
    if (self) {
        self.holdUpdates = YES;
        self.pendingChanges = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)description {
    NSMutableString *descr = [[NSMutableString alloc] init];
    [descr appendFormat:@"Light Name: %@\n", self.name];
    [descr appendFormat:@"\tgetURL: %@\n", self.getURL];
    [descr appendFormat:@"\tputURL: %@\n", self.putURL];
    [descr appendFormat:@"\tNumber: %@\n", self.number];
    [descr appendFormat:@"\tType: %@\n", self.type];
    [descr appendFormat:@"\tVersion: %@\n", self.swversion];
    [descr appendFormat:@"\tModel ID: %@\n", self.modelid];
    [descr appendFormat:@"\tOn: %@\n", self.on ? @"True" : @"False"];
    [descr appendFormat:@"\tBrightness: %@\n", self.brightness];
    [descr appendFormat:@"\tColor Mode: %@\n", self.colorMode];
    [descr appendFormat:@"\tHue: %@\n", self.hue];
    [descr appendFormat:@"\tSaturation: %@\n", self.saturation];
    [descr appendFormat:@"\tColor Temperature: %@\n", self.colorTemperature];
    [descr appendFormat:@"\txy: %@\n", self.xy];
    return descr;
}

- (void)updateURLs {
    NSString *base = [NSString stringWithFormat:@"http://%@/api/%@/lights/%@",
                      self.host, self.username, self.number];
    _getURL = [NSURL URLWithString:base];
    _putURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/state", base]];
}

#pragma mark - Setters that update getURL and putURL

- (void)setNumber:(NSNumber *)number {
    _number = number;
    [self updateURLs];
}

- (void)setUsername:(NSString *)username {
    _username = username;
    [self updateURLs];
}

- (void)setHost:(NSString *)host {
    _host = host;
    [self updateURLs];
}


#pragma mark - Setters that update pendingChanges

- (void)setOn:(BOOL)on {
    self->_on = on;
    self.pendingChanges[@"on"] = [NSNumber numberWithBool:on];
    if (!self.holdUpdates)
        [self write];
}

- (void)setBrightness:(NSNumber *)brightness {
    self->_brightness = brightness;
    self.pendingChanges[@"bri"] = brightness;
    if (!self.holdUpdates)
        [self write];
}

- (void)setHue:(NSNumber *)hue {
    self->_hue = hue;
    self.pendingChanges[@"hue"] = hue;
    if (!self.holdUpdates)
        [self write];
}

// This is the closest I've ever come to accidentally naming a method "sexy"
- (void)setXy:(NSArray *)xy {
    self->_xy = xy;
    self.pendingChanges[@"xy"] = xy;
    if (!self.holdUpdates)
        [self write];
}

- (void)setColorTemperature:(NSNumber *)colorTemperature {
    self->_colorTemperature = colorTemperature;
    self.pendingChanges[@"ct"] = colorTemperature;
    if (!self.holdUpdates)
        [self write];
}

- (void)setSaturation:(NSNumber *)saturation {
    self->_saturation = saturation;
    self.pendingChanges[@"sat"] = saturation;
    if (!self.holdUpdates)
        [self write];
}

- (void)read {
    NSURLRequest *req = [NSURLRequest requestWithURL:self.getURL];
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:req];
    connection.jsonRootObject = self;
    [connection start];
}

- (void)writeAll {
    if (!self.on) {
        // If bulb is off, it forbids changes, so send none
        // except to turn it off
        self.pendingChanges[@"on"] = [NSNumber numberWithBool:self.on];
        [self write];
        return;
    }
    self.pendingChanges[@"on"] = [NSNumber numberWithBool:self.on];
    self.pendingChanges[@"bri"] = self.brightness;
    // colorMode is set by the bulb itself
    // whichever color value you sent it last determines the mode
    if ([self.colorMode isEqualToString:@"hue"]) {
        self.pendingChanges[@"hue"] = self.hue;
        self.pendingChanges[@"sat"] = self.saturation;
    }
    if ([self.colorMode isEqualToString:@"xy"]) {
        self.pendingChanges[@"xy"] = self.xy;
    }
    if ([self.colorMode isEqualToString:@"ct"]) {
        self.pendingChanges[@"ct"] = self.colorTemperature;
    }
    [self write];
}

- (void)write {
    if (self.pendingChanges.count == 0)
        return;
    if (self.transitionTime) {
        self.pendingChanges[@"transitiontime"] = self.transitionTime;
    }
    NSData *json = [NSJSONSerialization dataWithJSONObject:self.pendingChanges options:0 error:nil];
    NSString *pretty = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.URL = self.putURL;
    request.HTTPMethod = @"PUT";
    request.HTTPBody = json;
    DPJSONConnection *connection = [[DPJSONConnection alloc] initWithRequest:request];
    connection.jsonRootObject = self;
    NSMutableString *msg = [[NSMutableString alloc] init];
    [msg appendFormat:@"Writing to: %@\n", self.putURL];
    [msg appendFormat:@"Writing values: %@\n", pretty];
    connection.completionBlock = ^(id obj, NSError *err) {
        WSLog(@"writeSuccess: %@:\n%@", self.writeSuccess ? @"True" : @"False", msg);
    };
    [connection start];
}

#pragma mark - DSJSONSerializable

- (void)readFromJSONDictionary:(id)d {
    if (![d respondsToSelector:@selector(objectForKeyedSubscript:)]) {
        // We were given an array, not a dict, which means
        // the Hue is telling us the result of a PUT
        // Loop through all results, if any are not successful, error out
        BOOL errorFound = NO;
        self->_writeMessage = [[NSMutableString alloc] init];
        for (NSDictionary *result in d) {
            if (result[@"error"]) {
                errorFound = YES;
                [self->_writeMessage appendFormat:@"%@\n", result[@"error"]];
            }
            if (result[@"success"]) {
                //[self->_writeMessage appendFormat:@"%@\n", result[@"success"]];
            }
        }
        if (errorFound) {
            self->_writeSuccess = NO;
            NSLog(@"Error writing values!\n%@", self->_writeMessage);
        }
        else {
            self->_writeSuccess = YES;
            [self->_pendingChanges removeAllObjects];
        }
        return;
    }
    self->_name = d[@"name"];
    self->_modelid = d[@"modelid"];
    self->_swversion = d[@"swversion"];
    self->_type = d[@"type"];
    self->_brightness = d[@"state"][@"bri"];
    self->_colorMode = d[@"state"][@"colormode"];
    self->_hue = d[@"state"][@"hue"];
    self->_type = d[@"type"];
    self->_on = (BOOL)d[@"state"][@"on"];
    self->_reachable = (BOOL)d[@"state"][@"reachable"];
    self->_xy = d[@"state"][@"xy"];
    self->_colorTemperature = d[@"state"][@"ct"];
    self->_saturation = d[@"state"][@"sat"];
}

#pragma mark - NSCoding 

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        self.holdUpdates = YES;
        self.pendingChanges = [[NSMutableDictionary alloc] init];
        
        self->_name = [a decodeObjectForKey:@"name"];
        self->_modelid = [a decodeObjectForKey:@"modelid"];
        self->_swversion = [a decodeObjectForKey:@"swversion"];
        self->_type = [a decodeObjectForKey:@"type"];
        self->_brightness = [a decodeObjectForKey:@"brightness"];
        self->_colorMode = [a decodeObjectForKey:@"colorMode"];
        self->_hue = [a decodeObjectForKey:@"hue"];
        self->_type = [a decodeObjectForKey:@"bulbType"];
        self->_on = [[a decodeObjectForKey:@"on"] boolValue];
        self->_xy = [a decodeObjectForKey:@"xy"];
        self->_colorTemperature = [a decodeObjectForKey:@"colorTemperature"];
        self->_saturation = [a decodeObjectForKey:@"saturation"];
        self->_getURL = [a decodeObjectForKey:@"getURL"];
        self->_putURL = [a decodeObjectForKey:@"putURL"];
        self->_number = [a decodeObjectForKey:@"number"];
        self->_host = [a decodeObjectForKey:@"host"];
        self->_username = [a decodeObjectForKey:@"username"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:self->_name forKey:@"name"];
    [a encodeObject:self->_modelid forKey:@"modelid"];
    [a encodeObject:self->_swversion forKey:@"swversion"];
    [a encodeObject:self->_type forKey:@"type"];
    [a encodeObject:self->_brightness forKey:@"brightness"];
    [a encodeObject:self->_colorMode forKey:@"colorMode"];
    [a encodeObject:self->_hue forKey:@"hue"];
    [a encodeObject:self->_type forKey:@"bulbType"];
    [a encodeObject:[NSNumber numberWithBool:self->_on] forKey:@"on"];
    [a encodeObject:self->_xy forKey:@"xy"];
    [a encodeObject:self->_colorTemperature forKey:@"colorTemperature"];
    [a encodeObject:self->_saturation forKey:@"saturation"];
    [a encodeObject:self->_getURL forKey:@"getURL"];
    [a encodeObject:self->_putURL forKey:@"putURL"];
    [a encodeObject:self->_number forKey:@"number"];
    [a encodeObject:self->_host forKey:@"host"];
    [a encodeObject:self->_username forKey:@"username"];
}

@end
