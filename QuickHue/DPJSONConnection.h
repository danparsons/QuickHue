//
//  DPJSONConnection.h
//  DPHue
//
//  This class is in the public domain.
//  Originally created by Dan Parsons in 2012.
//
//  https://github.com/danparsons/DPHue

// DPJSONConnection wraps NSURLConnection and optionally
// decodes JSON into a supplied object if it conforms to
// the DPJSONSerializable protocol

#import <Foundation/Foundation.h>
#import "DPJSONSerializable.h"

@interface DPJSONConnection : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, copy) void (^completionBlock)(id obj, NSError *err);
@property (nonatomic, strong) id <DPJSONSerializable> jsonRootObject;

- (id)initWithRequest:(NSURLRequest *)request;
- (void)start;

@end
