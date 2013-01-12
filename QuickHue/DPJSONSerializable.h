//
//  DPJSONSerializable.h
//  DPHue
//
//  This protocol is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

// Objects that conform to the DPJSONSerializable
// protocol are able to load a dictionary or list
// into their ivars.

#import <Foundation/Foundation.h>

@protocol DPJSONSerializable <NSObject>

- (void)readFromJSONDictionary:(id)d;

@end
