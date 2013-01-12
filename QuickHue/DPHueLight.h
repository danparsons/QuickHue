//
//  DPHueLight.h
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

#import <Foundation/Foundation.h>
#import "DPJSONSerializable.h"

@interface DPHueLight : NSObject <DPJSONSerializable, NSCoding>

// Properties you may be interested in setting
// Setting these values does not actually update the Hue
// controller until [DPHueLight write] is called
// (unless self.holdUpdates is set to NO, then changes are
// immediate).

// Lamp brightness, valid values are 0 - 255.
@property (nonatomic, strong) NSNumber *brightness;

// Lamp hue, in degrees*182, valid valuse are 0 - 65535.
@property (nonatomic, strong) NSNumber *hue;

// Lamp saturation, valid values are 0 - 255.
@property (nonatomic, strong) NSNumber *saturation;

// Lamp on (or off). When a lamp is told to turn on,
// it returns to its last state, in terms of color,
// brightness, etc. Unless mains power was lost,
// then it returns to factory state, which is a warm color.
@property (nonatomic) BOOL on;

// Color in (x,y) CIE 1931 coordinates. See below URL for details:
// http://en.wikipedia.org/wiki/CIE_1931
@property (nonatomic, strong) NSArray *xy;

// Color temperature in mireds, valid values are 154 - 500.
@property (nonatomic, strong) NSNumber *colorTemperature;

// Specifies how quickly a lamp should change from its old state
// to new state. Supposedly a setting of 0 allows for instant
// changes, but this hasn't worked well for me.
@property (nonatomic, strong) NSNumber *transitionTime;

// Set to YES by default.
// If set to YES, changes are held until [DPHueLight write] is called.
@property (nonatomic) BOOL holdUpdates;


// Properties you may be interested in reading

// Lamp name, as returned by the controller. The API allows for changing
// this, but I haven't implemented that feature.
@property (nonatomic, strong, readonly) NSString *name;

// The API does not allow changing this value directly. Rather, the color
// mode of a lamp is determined by the last color value type it was given.
// For example, if you last set a lamp's colorTemperature value, then
// colormode would be "ct". If you set hue or saturation, it would be "hs".
@property (nonatomic, strong, readonly) NSString *colorMode; // "xy", "ct" or "hs"

// This returns the controller's best guess as to whether the lamp is
// reachable by the controller or not.
@property (nonatomic, readonly) BOOL reachable;

// Firmware version of the lamp.
@property (nonatomic, strong, readonly) NSString *swversion;

// Lamp model type.
@property (nonatomic, strong, readonly) NSString *type;

// The number of the lamp, assigned by the controller.
@property (nonatomic, strong) NSNumber *number;

// Lamp model ID.
@property (nonatomic, strong, readonly) NSString *modelid;


// Properties you can probably ignore
@property (nonatomic, strong, readonly) NSURL *readURL;
@property (nonatomic, strong, readonly) NSURL *writeURL;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *host;

// Re-download & parse controller's state for this particular light
- (void)read;

// Write only pending changes to controller
- (void)write;

// Write entire state to controller, regardless of changes
- (void)writeAll;

// To be implemented later
/*- (void)flashOnce;
- (void)flashRepeatedly;
- (void)stopFlashing;
*/
@end
