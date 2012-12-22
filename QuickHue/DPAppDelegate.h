//
//  DPAppDelegate.h
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DPHueDiscover.h"

@interface DPAppDelegate : NSObject <NSApplicationDelegate, DPHueDiscoverDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
