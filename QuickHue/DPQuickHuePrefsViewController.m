//
//  DPQuickHuePrefsViewController.m
//  QuickHue
//
//  Created by Dan Parsons on 12/21/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "DPQuickHuePrefsViewController.h"
#import "DPHueDiscover.h"
#import "DPHue.h"
#import "DPQuickHuePresetStore.h"
#import "DPQuickHuePreset.h"
#import "DPQuickHueAppDelegate.h"
#import "NSAttributedString+Hyperlink.h"

NSString *const QuickHueAPIUsernamePrefKey = @"QuickHueAPIUsernamePrefKey";
NSString *const QuickHueHostPrefKey = @"QuickHueHostPrefKey";
NSString *const QuickHueUseBlackAndWhiteMenuBarIconsKey = @"QuickHueUseBlackAndWhiteMenuBarIcons";

@interface DPQuickHuePrefsViewController ()
@property (nonatomic, strong) DPHueDiscover *dhd;
@property (nonatomic, strong) NSString *foundHueHost;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) DPHue *touchlinkHue;
@property (nonatomic, strong) NSMutableString *discoveryLog;
@end

@implementation DPQuickHuePrefsViewController

void updateLaunchAtLoginCheckboxFunc(LSSharedFileListRef inList, void *context) {
    DPQuickHuePrefsViewController *self = (__bridge id)context;
    [self updateLaunchAtLoginCheckbox];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
        LSSharedFileListAddObserver(loginItems, CFRunLoopGetMain(), (CFStringRef)NSDefaultRunLoopMode, updateLaunchAtLoginCheckboxFunc, (__bridge void *)(self));
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    if (self.firstRun) {
        self.firstRun = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            [self startDiscovery:self];
        });
    }
    NSString *someHost = [[NSUserDefaults standardUserDefaults] objectForKey:QuickHueHostPrefKey];
    if (!someHost)
        self.hueBridgeHostLabel.stringValue = @"None";
    else
        self.hueBridgeHostLabel.stringValue = someHost;
    [self updateLaunchAtLoginCheckbox];
    self.twitterLabel.allowsEditingTextAttributes = YES;
    [self.twitterLabel setSelectable:YES];
    NSURL *twitterURL = [NSURL URLWithString:@"https://twitter.com/danparsons"];
    NSMutableAttributedString *twitterStr = [[NSMutableAttributedString alloc] init];
    [twitterStr appendAttributedString:[NSAttributedString hyperlinkFromString:@"@danparsons" withURL:twitterURL]];
    self.twitterLabel.attributedStringValue = twitterStr;
    [self.twitterLabel sizeToFit];
    
    self.githubLabel.allowsEditingTextAttributes = YES;
    [self.githubLabel setSelectable:YES];
    NSURL *githubURL = [NSURL URLWithString:@"https://github.com/danparsons/QuickHue"];
    NSMutableAttributedString *githubStr = [[NSMutableAttributedString alloc] init];
    [githubStr appendAttributedString:[NSAttributedString hyperlinkFromString:@"GitHub" withURL:githubURL]];
    self.githubLabel.attributedStringValue = githubStr;
    [self.githubLabel sizeToFit];
    
    self.versionLabel.stringValue = [NSString stringWithFormat:@"QuickHue v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];

    self.useBlackAndWhiteMenuBarIconsCheckbox.state = [[NSUserDefaults standardUserDefaults] boolForKey:QuickHueUseBlackAndWhiteMenuBarIconsKey];
}

- (void)addLoginItem {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
        if (item)
            CFRelease(item);
    }
    if (loginItems)
        CFRelease(loginItems);
}

- (void)deleteLoginItem {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed;
        NSArray *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seed);
        for (id itemRef in loginItemsArray) {
            if (LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)(itemRef), 0, (CFURLRef *) &url, NULL) == noErr) {
                NSString *urlPath = [(__bridge NSURL *)url path];
                if ([urlPath compare:appPath] == NSOrderedSame) {
                    LSSharedFileListItemRemove(loginItems, (__bridge LSSharedFileListItemRef)(itemRef));
                }
            }
        }
    }
}

- (BOOL)willLaunchAtLogin {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed;
        NSArray *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seed);
        for (id itemRef in loginItemsArray) {
            if (LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)(itemRef), 0, (CFURLRef *) &url, NULL) == noErr) {
                NSString *urlPath = [(__bridge NSURL *)url path];
                if ([urlPath compare:appPath] == NSOrderedSame) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)discoveryTimeHasElapsed {
    self.dhd = nil;
    [self.timer invalidate];
    [self.discoveryProgressIndicator stopAnimation:self];
    if (!self.foundHueHost) {
        self.discoveryStatusLabel.stringValue = @"Failed to find Hue";
        [self.viewDiscoveryLogButton setHidden:NO];
    }
}

#pragma mark - IBActions

- (IBAction)addPreset:(id)sender {
    DPQuickHuePresetStore *presetStore = [DPQuickHuePresetStore sharedStore];
    DPQuickHuePreset *preset = [presetStore createPreset];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [self.delegate buildMenu];
    [self.presetsTableView reloadData];
    preset.hue = [[DPHue alloc] initWithHueIP:[prefs objectForKey:QuickHueHostPrefKey] username:[prefs objectForKey:QuickHueAPIUsernamePrefKey]];
    [preset.hue readWithCompletion:^(DPHue *hue, NSError *err) {
        [presetStore save];        
    }];
}

- (IBAction)removePreset:(id)sender {
    //    [[[DPQuickHuePresetStore sharedStore] allPresets]
    [[DPQuickHuePresetStore sharedStore] removePresetAtIndex:(int)self.presetsTableView.selectedRow];
    [[DPQuickHuePresetStore sharedStore] save];
    [self.delegate buildMenu];
    [self.presetsTableView reloadData];
    [self autosetRemovePresetButtonState];
}

- (IBAction)startDiscovery:(id)sender {
    self.dhd = [[DPHueDiscover alloc] initWithDelegate:self];
    [self.dhd discoverForDuration:30 withCompletion:^(NSMutableString *log) {
        self.discoveryLog = log;
        [self discoveryTimeHasElapsed];
    }];
    [self.discoveryProgressIndicator startAnimation:self];
    self.discoveryStatusLabel.stringValue = @"Searching for Hue...";
    [self.successCheckmarkImage setHidden:YES];
    [NSApp beginSheet:self.discoverySheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)cancelDiscovery:(id)sender {
    [self.dhd stopDiscovery];
    self.dhd = nil;
    [self.timer invalidate];
    [NSApp endSheet:self.discoverySheet];
    [self.discoverySheet orderOut:sender];
}

- (IBAction)saveDiscovery:(id)sender {
    WSLog(@"Saving %@", self.foundHueHost);
    [[NSUserDefaults standardUserDefaults] setObject:self.foundHueHost forKey:QuickHueHostPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.hueBridgeHostLabel.stringValue = self.foundHueHost;
    [self.dhd stopDiscovery];
    self.dhd = nil;
    [NSApp endSheet:self.discoverySheet];
    [self.discoverySheet orderOut:sender];
}

- (IBAction)viewDiscoveryLog:(id)sender {
    self.discoveryLogTextView.string = self.discoveryLog;
    self.discoveryLogWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    [self.discoveryLogWindow makeKeyAndOrderFront:self];
}

- (void)createUsernameAt:(NSTimer *)timer {
    NSString *host = timer.userInfo;
    WSLog(@"Attempting to create username at %@", host);
    [self.discoveryLog appendFormat:@"%@: Attempting to authenticate to %@\n", [NSDate date], host];
    DPHue *someHue = [[DPHue alloc] initWithHueIP:host username:[[NSUserDefaults standardUserDefaults] objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        if (hue.authenticated) {
            [self.discoveryLog appendFormat:@"%@: Successfully authenticated\n", [NSDate date]];
            [self.timer invalidate];
            [self.discoveryProgressIndicator stopAnimation:self];
            [self.discoverySaveButton setEnabled:YES];
            self.foundHueHost = hue.host;
            self.discoveryStatusLabel.stringValue = [NSString stringWithFormat:@"Found Hue at %@, named '%@'!", hue.host, hue.name];
            [self.successCheckmarkImage setHidden:NO];
            [self.viewDiscoveryLogButton setHidden:NO]; 
        } else {
            [self.discoveryLog appendFormat:@"%@: Authentication failed, will try to create username\n", [NSDate date]];
            [someHue registerUsername];
            self.discoveryStatusLabel.stringValue = @"Press Button On Hue!";
        }
    }];
}

- (void)updateLaunchAtLoginCheckbox {
    if ([self willLaunchAtLogin])
        self.launchAtLoginCheckbox.state = YES;
    else
        self.launchAtLoginCheckbox.state = NO;
}

- (IBAction)triggerTouchlink:(id)sender {
    NSString *someHost = [[NSUserDefaults standardUserDefaults] objectForKey:QuickHueHostPrefKey];
    self.touchlinkHue = [[DPHue alloc] initWithHueIP:someHost username:[[NSUserDefaults standardUserDefaults] objectForKey:QuickHueAPIUsernamePrefKey]];
    [self.touchlinkProgressIndicator startAnimation:self];
    [self.touchlinkProgressIndicator setHidden:NO];
    [self.touchlinkHue triggerTouchlinkWithCompletion:^(BOOL success, NSString *result) {
        if (success) {
            WSLog(@"Touchlink found bulbs!");
            self.touchlinkStatusLabel.stringValue = @"Touchlink found bulbs!";
        }
        else {
            WSLog(@"Touchlink failed to find bulbs");
            self.touchlinkStatusLabel.stringValue = @"Touchlink failed to find bulbs";
        }
        [self.touchlinkProgressIndicator stopAnimation:self];
        [self.touchlinkProgressIndicator setHidden:YES];
        self.touchlinkMessageLabel.stringValue = [NSString stringWithFormat:@"Result from Hue: %@", result];
        [self.popoverController showRelativeToRect:self.triggerTouchlinkButton.bounds ofView:self.triggerTouchlinkButton preferredEdge:NSMaxYEdge];
        self.touchlinkHue = nil;
        
    }];
}

- (IBAction)tableViewSelected:(id)sender {
    [self autosetRemovePresetButtonState];
}

- (IBAction)startAtLoginClicked:(id)sender {
    if (self.launchAtLoginCheckbox.state)
        [self addLoginItem];
    else
        [self deleteLoginItem];
}

- (IBAction)useBlackAndWhiteMenuBarIconsClicked:(id)sender {
    if(self.useBlackAndWhiteMenuBarIconsCheckbox.state) {
        self.statusItem.image = [NSImage imageNamed:@"bulb-black"];
        self.statusItem.alternateImage = [NSImage imageNamed:@"bulb-white"];
    } else {
        self.statusItem.image = [NSImage imageNamed:@"bulb"];
        self.statusItem.alternateImage = [NSImage imageNamed:@"bulb"];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setBool:self.useBlackAndWhiteMenuBarIconsCheckbox.state forKey:QuickHueUseBlackAndWhiteMenuBarIconsKey];

    [defaults synchronize];
}

- (void)autosetRemovePresetButtonState {
    if (self.presetsTableView.numberOfSelectedRows != 0)
        [self.removePresetButton setEnabled:YES];
    else
        [self.removePresetButton setEnabled:NO];
}

#pragma mark - DPHueDiscover delegate

- (void)foundHueAt:(NSString *)host discoveryLog:(NSMutableString *)log {
    self.discoveryLog = log;
    [self.discoveryProgressIndicator startAnimation:self];
    [self.discoverySaveButton setEnabled:NO];
    self.discoveryStatusLabel.stringValue = @"Hue Found! Authenticating...";
    DPHue *someHue = [[DPHue alloc] initWithHueIP:host username:[[NSUserDefaults standardUserDefaults] objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(createUsernameAt:) userInfo:host repeats:YES];
    }];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[DPQuickHuePresetStore sharedStore] allPresets] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[[[DPQuickHuePresetStore sharedStore] allPresets] objectAtIndex:row] name];
}

#pragma mark - NSTableViewDelegate

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return YES;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [[DPQuickHuePresetStore sharedStore] setName:object atIndex:(int)row];
    [[DPQuickHuePresetStore sharedStore] save];
    [self.delegate buildMenu];
    [self.presetsTableView reloadData];
}

@end
