//
//  DPAppDelegate.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <DPHue/DPHue.h>
#import <DPHue/DPHueLight.h>
#import <DPHue/DPHueDiscover.h>
#import "DPQuickHueAppDelegate.h"
#import "DPQuickHuePresetStore.h"
#import "DPQuickHuePreset.h"
#import "DPQuickHuePrefsViewController.h"

@interface DPQuickHueAppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *statusBarMenu;
@property (nonatomic, strong) DPQuickHuePrefsViewController *pvc;
@property (nonatomic, strong) DPHueDiscover *dhd;
@end

extern NSString * const QuickHueAPIUsernamePrefKey;
extern NSString * const QuickHueHostPrefKey;
extern NSString * const QuickHueUseBlackAndWhiteMenuBarIconsKey;

@implementation DPQuickHueAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    if([prefs boolForKey:QuickHueUseBlackAndWhiteMenuBarIconsKey]) {
        self.statusItem.image = [NSImage imageNamed:@"bulb-black"];
        self.statusItem.alternateImage = [NSImage imageNamed:@"bulb-white"];
    } else {
        self.statusItem.image = [NSImage imageNamed:@"bulb"];
        self.statusItem.alternateImage = [NSImage imageNamed:@"bulb"];
    }

    self.statusItem.highlightMode = YES;
    
    [self buildMenu];
    
    self.pvc = [[DPQuickHuePrefsViewController alloc] init];
    self.pvc.statusItem = self.statusItem;
    self.pvc.delegate = self;

    if ( (![prefs objectForKey:QuickHueAPIUsernamePrefKey]) ||
        (![prefs objectForKey:QuickHueHostPrefKey])) {
        self.pvc.firstRun = YES;
        // No API username or hostname found, probably first app run
        NSString *newUsername = [DPHue generateUsername];
        [prefs setObject:newUsername forKey:QuickHueAPIUsernamePrefKey];
        [prefs synchronize];
        [self.pvc.view.window makeKeyAndOrderFront:self];
    }
}

- (void)buildMenu {
    self.statusBarMenu = [[NSMenu alloc] initWithTitle:@"QuickHue"];
    DPQuickHuePresetStore *presetStore = [DPQuickHuePresetStore sharedStore];
    if ([presetStore allPresets].count > 0) {
        for (DPQuickHuePreset *preset in presetStore.allPresets) {
            NSMenuItem *someItem = [[NSMenuItem alloc] initWithTitle:preset.name action:@selector(applyPreset:) keyEquivalent:@""];
            someItem.representedObject = preset;
            [self.statusBarMenu addItem:someItem];
        }
    } else
        [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"No presets, create one!" action:nil keyEquivalent:@""]];
    [self.statusBarMenu addItem:[NSMenuItem separatorItem]];
    [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"All Lights On" action:@selector(allOn) keyEquivalent:@""]];
    [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"All Lights Off" action:@selector(allOff) keyEquivalent:@""]];
    [self.statusBarMenu addItem:[NSMenuItem separatorItem]];
#ifdef DEBUG
    [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Debug1" action:@selector(debug1) keyEquivalent:@""]];
#endif
    [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Create Preset" action:@selector(createPreset) keyEquivalent:@""]];
    [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(preferences) keyEquivalent:@""]];
    [self.statusBarMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""]];
    self.statusItem.menu = self.statusBarMenu;
}

- (void)applyPreset:(id)sender {
    DPQuickHuePreset *preset = [sender representedObject];
    [preset.hue writeAll];
}

- (void)createPreset {
    DPQuickHuePresetStore *presetStore = [DPQuickHuePresetStore sharedStore];
    DPQuickHuePreset *preset = [presetStore createPreset];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    preset.hue = [[DPHue alloc] initWithHueHost:[prefs objectForKey:QuickHueHostPrefKey] username:[prefs objectForKey:QuickHueAPIUsernamePrefKey]];
    [self.pvc.presetsTableView reloadData];
    [preset.hue readWithCompletion:^(DPHue *hue, NSError *err) {
        [presetStore save];
        [self buildMenu];
    }];
}

- (void)allOn {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    DPHue *someHue = [[DPHue alloc] initWithHueHost:[prefs objectForKey:QuickHueHostPrefKey] username:[prefs objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        [hue allLightsOn];
    }];
}

- (void)allOff {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    DPHue *someHue = [[DPHue alloc] initWithHueHost:[prefs objectForKey:QuickHueHostPrefKey] username:[prefs objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        [hue allLightsOff];
    }];
}

- (void)preferences {
    /*
    // temporarily using this for testing stuff
    DPHue *someHue = [[DPHue alloc] initWithHueControllerIP:@"192.168.0.25"];
    NSString *hueAPIUsername = [[NSUserDefaults standardUserDefaults] objectForKey:QuickHueAPIUsernamePrefKey];
    NSLog(@"%@", hueAPIUsername);
    //[[NSUserDefaults standardUserDefaults] setObject:@"foo" forKey:@"hueAPIUsername"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        NSLog(@"Authenticated: %d", hue.authenticated);
    }];
     */
    [NSApp activateIgnoringOtherApps:YES];
    self.pvc.view.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    [self.pvc.view.window makeKeyAndOrderFront:self];
}

- (void)debug1 {
    NSLog(@"%@", [DPHue generateUsername]);
}

#pragma mark - DPHueDiscoverDelegate

- (void)foundHueAt:(NSString *)host discoveryLog:(NSString *)log {
    WSLog(@"Hue found: %@", host);
}

@end
