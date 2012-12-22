//
//  DPQuickHuePreset.h
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPHue.h"

@interface DPQuickHuePreset : NSObject <NSCoding>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) DPHue *hue;

@end
