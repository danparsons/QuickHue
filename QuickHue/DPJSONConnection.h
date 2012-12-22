//
//  DPJSONConnection.h
//  HueProto2
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPJSONSerializable.h"

@interface DPJSONConnection : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, copy) void (^completionBlock)(id obj, NSError *err);
@property (nonatomic, strong) id <DPJSONSerializable> jsonRootObject;

- (id)initWithRequest:(NSURLRequest *)request;
- (void)start;

@end
