//
//  DPHueNUPNP.m
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

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
