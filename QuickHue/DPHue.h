//
//  DPHue.h
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

#import <Foundation/Foundation.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "DPJSONSerializable.h"

@interface DPHue : NSObject <DPJSONSerializable, NSCoding, GCDAsyncSocketDelegate>

// Properties you may be interested in setting

// The API username DPHue will use when communicating with the Hue controller.
// The Hue API requires this be an MD5 hash of something.
@property (nonatomic, strong) NSString *username;

// The hostname (or IP address) that DPHue will talk to.
@property (nonatomic, strong) NSString *host;



// Properties you may be interested in reading

// The "name" of the Hue controller, as returned by the API
// This can actually be changed via the Hue API if necessary,
// but I didn't implement that feature.
@property (nonatomic, strong, readonly) NSString *name;

// Firmware version
@property (nonatomic, strong, readonly) NSString *swversion;

// An array of DPHueLight objects representing all the lights
// that the controller is aware of.
@property (nonatomic, strong, readonly) NSArray *lights;

// Accessing this proprety causes DPHue to try to authenticate
@property (nonatomic, readonly) BOOL authenticated;



// Properties you can probably ignore

// Both getURL and putURL are automatically generated based on
// data returned from the controller.
// readURL is the URL that returns data (controller config, lights)
@property (nonatomic, strong, readonly) NSURL *readURL;

// writeURL is the URL that new JSON values are sent to
@property (nonatomic, strong, readonly) NSURL *writeURL;


// Utility method for generating a username that Hue will like
// It requires usernames to be MD5 hashes
// This method returns a md5 hash of the system's hostname
+ (NSString *)generateUsername;

// host is the hostname or IP of the Hue controller you want to talk to.
// username has to be an md5 string - use [DPHue generateUsername] to
// create one if you don't have one already. In that case, you'll also
// have to register the username with the controller. See
// [DPHue registerUsername].
- (id)initWithHueHost:(NSString *)host username:(NSString *)username;

// Download the complete state of the Hue controller, including the state
// of all lights. block is called when the operation is complete. This
// normally takes only 1 to 3 seconds.
- (void)readWithCompletion:(void (^)(DPHue *hue, NSError *err))block;

// This will attempt to register self.username with the Hue controller.
// This will fail unless the physical button on the Hue controller has
// been pressed within the last 30 seconds. The workflow for this method
// is a loop: tell the user to press the button on their controller, call
// this method, then check self.authenticated. If NO, keep calling this
// method. See DPQuickHue for implementation example.
- (void)registerUsername;

// Turns off all lights the controller is aware of
// via [DPHueLight setOn:OFF]
- (void)allLightsOff;

// Turns on all lights the controller is aware of
// via [DPHueLight setOn:ON]
- (void)allLightsOn;

// Writes the state of all lights to the controller, even if no changes
// have been made. Helpful for changing from one complete state to another.
- (void)writeAll;

// Triggers the Touchlink feature in a Hue controller, which causes it to
// pair with all lamps it can find, even thoughs that belong to another
// controller. To limit the possibility of "stealing" someone else's lamps,
// the range of this function is limited (by Philips, in the controller firmware)
// to a short distance from the controller.
// Calls block when a response is received from the controller.
- (void)triggerTouchlinkWithCompletion:(void (^)(BOOL success, NSString *result))block;

@end
