//
//  DPHueNUPNP.m
//  QuickHue
//
//  Created by Dan Parsons on 12/27/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPHueNUPNP.h"

@implementation DPHueNUPNP

- (void)readFromJSONDictionary:(id)d {
    if ([d count] > 0) {
        NSDictionary *dict = [d objectAtIndex:0];
        _hueID = dict[@"id"];
        _hueIP = dict[@"internalipaddress"];
        _hueMACAddress = dict[@"macaddress"];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ID: %@\nIP: %@\nMAC: %@\n", self.hueID, self.hueIP, self.hueMACAddress];
}

@end
