//
//  DPAppDelegate.m
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPQuickHueAppDelegate.h"
#import "DPQuickHuePresetStore.h"
#import "DPQuickHuePreset.h"
#import "DPHue.h"
#import "DPHueLight.h"
#import "DPHueDiscover.h"
#import "DPQuickHuePrefsViewController.h"

@interface DPQuickHueAppDelegate ()
@property (nonatomic, strong) NSStatusItem *statusBar;
@property (nonatomic, strong) NSMenu *statusBarMenu;
@property (nonatomic, strong) DPQuickHuePrefsViewController *pvc;
@property (nonatomic, strong) DPHueDiscover *dhd;
@end

extern NSString * const QuickHueAPIUsernamePrefKey;
extern NSString * const QuickHueHostPrefKey;

@implementation DPQuickHueAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.image = [NSImage imageNamed:@"bulb"];
    self.statusBar.highlightMode = YES;
    [self buildMenu];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if (![prefs objectForKey:QuickHueAPIUsernamePrefKey]) {
        // No API username found in user prefs, generate one
        NSString *newUsername = [DPHue generateUsername];
        [prefs setObject:newUsername forKey:QuickHueAPIUsernamePrefKey];
        [prefs synchronize];
        WSLog(@"No API username found; generated %@", [prefs objectForKey:QuickHueAPIUsernamePrefKey]);
    }
    self.pvc = [[DPQuickHuePrefsViewController alloc] init];
    self.pvc.delegate = self;
    WSLog(@"Username: %@", [DPHue generateUsername]);
    [self preferences];
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
    
    NSMenuItem *debug1 = [[NSMenuItem alloc] initWithTitle:@"Debug1" action:@selector(debug1) keyEquivalent:@""];
    [self.statusBarMenu addItem:debug1];
    
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
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    preset.hue = [[DPHue alloc] initWithHueIP:[prefs objectForKey:QuickHueHostPrefKey] username:[prefs objectForKey:QuickHueAPIUsernamePrefKey]];
    [preset.hue readWithCompletion:^(DPHue *hue, NSError *err) {
        [presetStore save];
        [self buildMenu];
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
    [self.pvc.view.window makeKeyAndOrderFront:self];
}

- (void)debug1 {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    DPHue *someHue = [[DPHue alloc] initWithHueIP:[prefs objectForKey:QuickHueHostPrefKey] username:[prefs objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        NSLog(@"Read complete:\n%@", hue);
        NSLog(@"Changing host\n");
        hue.host = @"123.245.222.212";
        NSLog(@"%@\n", hue);
        NSLog(@"Changing username\n");
        hue.username = @"foofity";
        DPHueLight *someLight = hue.lights[0];
        someLight.on = NO;
        NSLog(@"%@\n", hue);
        
    }];
}

#pragma mark - DPHueDiscoverDelegate

- (void)foundHueAt:(NSString *)host {
    WSLog(@"Hue found: %@", host);
}

@end
