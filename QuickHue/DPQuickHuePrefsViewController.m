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

NSString *const QuickHueAPIUsernamePrefKey = @"QuickHueAPIUsernamePrefKey";
NSString *const QuickHueHostPrefKey = @"QuickHueHostPrefKey";

@interface DPQuickHuePrefsViewController ()
@property (nonatomic, strong) DPHueDiscover *dhd;
@property (nonatomic, strong) NSString *foundHueHost;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation DPQuickHuePrefsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    self.hueBridgeHostLabel.stringValue = [[NSUserDefaults standardUserDefaults] objectForKey:QuickHueHostPrefKey];
}

- (IBAction)startDiscovery:(id)sender {
    self.dhd = [[DPHueDiscover alloc] initWithDelegate:self];
    [self.dhd discover];
    [self.discoveryProgressIndicator startAnimation:self];
    self.discoveryStatusLabel.stringValue = @"Discovering...";
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
    NSLog(@"Saving %@", self.foundHueHost);
    [[NSUserDefaults standardUserDefaults] setObject:self.foundHueHost forKey:QuickHueHostPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.hueBridgeHostLabel.stringValue = self.foundHueHost;
    [self.dhd stopDiscovery];
    self.dhd = nil;
    [NSApp endSheet:self.discoverySheet];
    [self.discoverySheet orderOut:sender];
}

- (void)createUsernameAt:(NSTimer *)timer {
    NSString *host = timer.userInfo;
    WSLog(@"Attempting to create username at %@", host);
    DPHue *someHue = [[DPHue alloc] initWithHueIP:host username:[[NSUserDefaults standardUserDefaults] objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        if (hue.authenticated) {
            [self.timer invalidate];
            [self.discoveryProgressIndicator stopAnimation:self];
            [self.discoverySaveButton setEnabled:YES];
            self.foundHueHost = hue.host;
            self.discoveryStatusLabel.stringValue = [NSString stringWithFormat:@"Found Hue at %@, named '%@'!", hue.host, hue.name];
        } else {
            [someHue registerUsername];
            self.discoveryStatusLabel.stringValue = @"Press Button On Hue!";
        }
    }];    
}

#pragma mark - DPHueDiscover delegate

- (void)foundHueAt:(NSString *)host {
    [self.discoveryProgressIndicator startAnimation:self];
    [self.discoverySaveButton setEnabled:NO];
    self.discoveryStatusLabel.stringValue = @"Hue Found! Authenticating...";
    DPHue *someHue = [[DPHue alloc] initWithHueIP:host username:[[NSUserDefaults standardUserDefaults] objectForKey:QuickHueAPIUsernamePrefKey]];
    [someHue readWithCompletion:^(DPHue *hue, NSError *err) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(createUsernameAt:) userInfo:host repeats:YES];
    }];
}

@end
