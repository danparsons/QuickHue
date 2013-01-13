//
//  DPQuickHuePreset.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <DPHue/DPHue.h>
#import "DPQuickHuePreset.h"

@implementation DPQuickHuePreset

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)a {
    self = [super init];
    if (self) {
        _name = [a decodeObjectForKey:@"name"];
        _hue = [a decodeObjectForKey:@"hue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)a {
    [a encodeObject:_name forKey:@"name"];
    [a encodeObject:_hue forKey:@"hue"];
}

@end
