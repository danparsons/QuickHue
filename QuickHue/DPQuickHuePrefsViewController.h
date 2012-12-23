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

// Properties of main prefs window
@property (nonatomic, strong) id delegate;
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSPanel *discoverySheet;
@property (weak) IBOutlet NSTextField *hueBridgeHostLabel;
@property (weak) IBOutlet NSButton *launchAtLoginCheckbox;
@property (weak) IBOutlet NSTableView *presetsTableView;
@property (weak) IBOutlet NSButton *removePresetButton;
- (IBAction)addPreset:(id)sender;
- (IBAction)removePreset:(id)sender;
- (IBAction)tableViewSelected:(id)sender;
- (IBAction)startAtLoginClicked:(id)sender;
- (IBAction)startDiscovery:(id)sender;
- (void)updateLaunchAtLoginCheckbox;


// Properties of sheet
@property (weak) IBOutlet NSProgressIndicator *discoveryProgressIndicator;
@property (weak) IBOutlet NSTextField *discoveryStatusLabel;
@property (weak) IBOutlet NSButton *discoverySaveButton;
@property (weak) IBOutlet NSImageView *successCheckmarkImage;

- (IBAction)cancelDiscovery:(id)sender;
- (IBAction)saveDiscovery:(id)sender;



@end
