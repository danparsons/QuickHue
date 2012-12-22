//
//  DPQuickHuePreset.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPQuickHuePreset.h"
#import "DPHue.h"

@implementation DPQuickHuePreset

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        self->_name = [a decodeObjectForKey:@"name"];
        self->_hue = [a decodeObjectForKey:@"hue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:self->_name forKey:@"name"];
    [a encodeObject:self->_hue forKey:@"hue"];
}

@end
