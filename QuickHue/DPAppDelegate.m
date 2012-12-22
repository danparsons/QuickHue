//
//  DPAppDelegate.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPAppDelegate.h"
#import "DPQuickHuePresetStore.h"
#import "DPQuickHuePreset.h"
#import "DPHue.h"
#import "DPHueDiscover.h"

@interface DPAppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusBar;
@property (nonatomic, strong) NSMenu *statusBarMenu;
@property (nonatomic, strong) DPHueDiscover *dhd;
@end


@implementation DPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.image = [NSImage imageNamed:@"hue-logo"];
    self.statusBar.highlightMode = YES;
    [self buildMenu];
}

- (void)buildMenu {
    self.statusBarMenu = [[NSMenu alloc] initWithTitle:@"QuickHue"];
    DPQuickHuePresetStore *presetStore = [DPQuickHuePresetStore sharedStore];
    for (DPQuickHuePreset *preset in presetStore.allPresets) {
        NSMenuItem *someItem = [[NSMenuItem alloc] initWithTitle:preset.name action:@selector(applyPreset:) keyEquivalent:@""];
        someItem.representedObject = preset;
        [self.statusBarMenu addItem:someItem];
    }
    NSMenuItem *separatorItem = [NSMenuItem separatorItem];
    [self.statusBarMenu addItem:separatorItem];
    
    NSMenuItem *discoverItem = [[NSMenuItem alloc] initWithTitle:@"Discover" action:@selector(discover) keyEquivalent:@""];
    [self.statusBarMenu addItem:discoverItem];
    
    NSMenuItem *stopDiscoveryItem = [[NSMenuItem alloc] initWithTitle:@"Stop Discovery" action:@selector(stopDiscovery) keyEquivalent:@""];
    [self.statusBarMenu addItem:stopDiscoveryItem];
    
    NSMenuItem *makePresetItem = [[NSMenuItem alloc] initWithTitle:@"Make Preset" action:@selector(makePreset) keyEquivalent:@""];
    [self.statusBarMenu addItem:makePresetItem];
    
    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(preferences) keyEquivalent:@""];
    [self.statusBarMenu addItem:preferencesMenuItem];
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    [self.statusBarMenu addItem:quitMenuItem];
    self.statusBar.menu = self.statusBarMenu;
}

- (void)applyPreset:(id)sender {
    DPQuickHuePreset *preset = [sender representedObject];
    [preset.hue writeAll];
}

- (void)makePreset {
    DPQuickHuePresetStore *presetStore = [DPQuickHuePresetStore sharedStore];
    DPQuickHuePreset *preset = [presetStore createPreset];
    preset.name = @"Some Preset";
    preset.hue = [[DPHue alloc] initWithHueControllerIP:@"192.168.0.25"];
    [preset.hue readWithCompletion:^(DPHue *hue, NSError *err) {
        [presetStore save];
        [self buildMenu];
    }];
}

- (void)discover {
    self.dhd = [[DPHueDiscover alloc] initWithDelegate:self];
    [self.dhd discover];
}

- (void)stopDiscovery {
    [self.dhd stopDiscovery];
    self.dhd = nil;
}

- (void)preferences {
    
}

#pragma mark - DPHueDiscoverDelegate

- (void)hueFound:(NSString *)hueHost {
    WSLog(@"Hue found: %@", hueHost);
}

@end
