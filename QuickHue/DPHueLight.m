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
    _on = on;
    self.pendingChanges[@"on"] = [NSNumber numberWithBool:on];
    if (!self.holdUpdates)
        [self write];
}

- (void)setBrightness:(NSNumber *)brightness {
    _brightness = brightness;
    self.pendingChanges[@"bri"] = brightness;
    if (!self.holdUpdates)
        [self write];
}

- (void)setHue:(NSNumber *)hue {
    _hue = hue;
    self.pendingChanges[@"hue"] = hue;
    if (!self.holdUpdates)
        [self write];
}

// This is the closest I've ever come to accidentally naming a method "sexy"
- (void)setXy:(NSArray *)xy {
    _xy = xy;
    self.pendingChanges[@"xy"] = xy;
    if (!self.holdUpdates)
        [self write];
}

- (void)setColorTemperature:(NSNumber *)colorTemperature {
    _colorTemperature = colorTemperature;
    self.pendingChanges[@"ct"] = colorTemperature;
    if (!self.holdUpdates)
        [self write];
}

- (void)setSaturation:(NSNumber *)saturation {
    _saturation = saturation;
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
        _writeMessage = [[NSMutableString alloc] init];
        for (NSDictionary *result in d) {
            if (result[@"error"]) {
                errorFound = YES;
                [_writeMessage appendFormat:@"%@\n", result[@"error"]];
            }
            if (result[@"success"]) {
                //[_writeMessage appendFormat:@"%@\n", result[@"success"]];
            }
        }
        if (errorFound) {
            _writeSuccess = NO;
            NSLog(@"Error writing values!\n%@", _writeMessage);
        }
        else {
            _writeSuccess = YES;
            [_pendingChanges removeAllObjects];
        }
        return;
    }
    _name = d[@"name"];
    _modelid = d[@"modelid"];
    _swversion = d[@"swversion"];
    _type = d[@"type"];
    _brightness = d[@"state"][@"bri"];
    _colorMode = d[@"state"][@"colormode"];
    _hue = d[@"state"][@"hue"];
    _type = d[@"type"];
    _on = (BOOL)d[@"state"][@"on"];
    _reachable = (BOOL)d[@"state"][@"reachable"];
    _xy = d[@"state"][@"xy"];
    _colorTemperature = d[@"state"][@"ct"];
    _saturation = d[@"state"][@"sat"];
}

#pragma mark - NSCoding 

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        self.holdUpdates = YES;
        self.pendingChanges = [[NSMutableDictionary alloc] init];
        
        _name = [a decodeObjectForKey:@"name"];
        _modelid = [a decodeObjectForKey:@"modelid"];
        _swversion = [a decodeObjectForKey:@"swversion"];
        _type = [a decodeObjectForKey:@"type"];
        _brightness = [a decodeObjectForKey:@"brightness"];
        _colorMode = [a decodeObjectForKey:@"colorMode"];
        _hue = [a decodeObjectForKey:@"hue"];
        _type = [a decodeObjectForKey:@"bulbType"];
        _on = [[a decodeObjectForKey:@"on"] boolValue];
        _xy = [a decodeObjectForKey:@"xy"];
        _colorTemperature = [a decodeObjectForKey:@"colorTemperature"];
        _saturation = [a decodeObjectForKey:@"saturation"];
        _getURL = [a decodeObjectForKey:@"getURL"];
        _putURL = [a decodeObjectForKey:@"putURL"];
        _number = [a decodeObjectForKey:@"number"];
        _host = [a decodeObjectForKey:@"host"];
        _username = [a decodeObjectForKey:@"username"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:_name forKey:@"name"];
    [a encodeObject:_modelid forKey:@"modelid"];
    [a encodeObject:_swversion forKey:@"swversion"];
    [a encodeObject:_type forKey:@"type"];
    [a encodeObject:_brightness forKey:@"brightness"];
    [a encodeObject:_colorMode forKey:@"colorMode"];
    [a encodeObject:_hue forKey:@"hue"];
    [a encodeObject:_type forKey:@"bulbType"];
    [a encodeObject:[NSNumber numberWithBool:self->_on] forKey:@"on"];
    [a encodeObject:_xy forKey:@"xy"];
    [a encodeObject:_colorTemperature forKey:@"colorTemperature"];
    [a encodeObject:_saturation forKey:@"saturation"];
    [a encodeObject:_getURL forKey:@"getURL"];
    [a encodeObject:_putURL forKey:@"putURL"];
    [a encodeObject:_number forKey:@"number"];
    [a encodeObject:_host forKey:@"host"];
    [a encodeObject:_username forKey:@"username"];
}

@end
