//
//  DPHueNUPNP.h
//  QuickHue
//
//  Created by Dan Parsons on 12/27/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPJSONConnection.h"

@interface DPHueNUPNP : NSObject <DPJSONSerializable>
@property (nonatomic, strong, readonly) NSString *hueID;
@property (nonatomic, strong, readonly) NSString *hueIP;
@property (nonatomic, strong, readonly) NSString *hueMACAddress;
@end
