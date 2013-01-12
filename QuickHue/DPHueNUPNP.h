//
//  DPHueNUPNP.h
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

// This is just a class for encapsulating data returned from the
// meethue.com discovery API.

#import <Foundation/Foundation.h>
#import "DPJSONConnection.h"

@interface DPHueNUPNP : NSObject <DPJSONSerializable>
@property (nonatomic, strong, readonly) NSString *hueID;
@property (nonatomic, strong, readonly) NSString *hueIP;
@property (nonatomic, strong, readonly) NSString *hueMACAddress;
@end
