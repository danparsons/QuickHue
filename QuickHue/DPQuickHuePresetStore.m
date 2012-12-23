//
//  DPQuickHuePresetStore.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPQuickHuePresetStore.h"
#import "DPQuickHuePreset.h"

@interface DPQuickHuePresetStore ()
@property (nonatomic, strong) NSMutableArray *allPresets;
@end

@implementation DPQuickHuePresetStore

+ (DPQuickHuePresetStore *)sharedStore {
    static DPQuickHuePresetStore *sharedStore = nil;
    if (!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    return sharedStore;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedStore];
}

- (id)init {
    self = [super init];
    if (self) {
        NSString *path = [self presetArchivePath];
        _allPresets = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!_allPresets)
            _allPresets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL)save {
    NSString *path = [self presetArchivePath];
    return [NSKeyedArchiver archiveRootObject:_allPresets toFile:path];
}

- (DPQuickHuePreset *)createPreset {
    DPQuickHuePreset *p = [[DPQuickHuePreset alloc] init];
    [_allPresets addObject:p];
    return p;
}

- (NSArray *)allPresets {
    return _allPresets;
}

- (void)removePreset:(DPQuickHuePreset *)p {
    [_allPresets removeObjectIdenticalTo:p];
}

- (NSString *)presetArchivePath {
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSArray *dirs = [fileMan URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *appSupDir = dirs[0];
    NSString *path = [appSupDir.path stringByAppendingPathComponent:@"QuickHue"];
    if (![fileMan fileExistsAtPath:path]) {
        [fileMan createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [path stringByAppendingPathComponent:@"presets.archive"];
}

@end
