//
//  DPQuickHuePrefsViewController.h
//  QuickHue
//
//  Created by Dan Parsons on 12/21/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DPHueDiscover.h"

@interface DPQuickHuePrefsViewController : NSViewController <DPHueDiscoverDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) BOOL firstRun;

@property (nonatomic, strong) NSStatusItem *statusItem; //for modifying black and white vs. color state

// Properties of main prefs window
@property (nonatomic, strong) id delegate;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSPanel *discoverySheet;
@property (weak) IBOutlet NSTextField *hueBridgeHostLabel;
@property (weak) IBOutlet NSButton *launchAtLoginCheckbox;
@property (weak) IBOutlet NSButton *useBlackAndWhiteMenuBarIconsCheckbox;
@property (weak) IBOutlet NSTableView *presetsTableView;
@property (weak) IBOutlet NSButton *removePresetButton;
@property (weak) IBOutlet NSTextField *twitterLabel;
@property (weak) IBOutlet NSTextField *githubLabel;
@property (weak) IBOutlet NSTextField *versionLabel;
@property (strong) IBOutlet NSPanel *touchlinkStatusWindow;
@property (weak) IBOutlet NSButton *triggerTouchlinkButton;
@property (strong) IBOutlet NSPopover *popoverController;
@property (weak) IBOutlet NSTextField *touchlinkStatusLabel;
@property (weak) IBOutlet NSTextField *touchlinkMessageLabel;
@property (weak) IBOutlet NSProgressIndicator *touchlinkProgressIndicator;

- (IBAction)addPreset:(id)sender;
- (IBAction)removePreset:(id)sender;
- (IBAction)tableViewSelected:(id)sender;
- (IBAction)startAtLoginClicked:(id)sender;
- (IBAction)useBlackAndWhiteMenuBarIconsClicked:(id)sender;
- (IBAction)startDiscovery:(id)sender;
- (void)updateLaunchAtLoginCheckbox;
- (IBAction)triggerTouchlink:(id)sender;


// Properties of sheet
@property (weak) IBOutlet NSProgressIndicator *discoveryProgressIndicator;
@property (weak) IBOutlet NSTextField *discoveryStatusLabel;
@property (weak) IBOutlet NSButton *discoverySaveButton;
@property (weak) IBOutlet NSImageView *successCheckmarkImage;
@property (weak) IBOutlet NSButton *viewDiscoveryLogButton;
@property (strong) IBOutlet NSWindow *discoveryLogWindow;
@property (unsafe_unretained) IBOutlet NSTextView *discoveryLogTextView;

- (IBAction)cancelDiscovery:(id)sender;
- (IBAction)saveDiscovery:(id)sender;
- (IBAction)viewDiscoveryLog:(id)sender;



@end
