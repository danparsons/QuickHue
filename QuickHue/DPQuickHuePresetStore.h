//
//  DPQuickHuePresetStore.h
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DPQuickHuePreset;

@interface DPQuickHuePresetStore : NSObject

+ (DPQuickHuePresetStore *)sharedStore;
- (void)removePreset:(DPQuickHuePreset *)p;
- (NSArray *)allPresets;
- (DPQuickHuePreset *)createPreset;
- (NSString *)presetArchivePath;
- (BOOL)save;

@end
