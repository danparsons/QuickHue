//
//  DPJSONSerializable.h
//  QuickHue
//
//  Created by Dan Parsons on 12/19/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DPJSONSerializable <NSObject>

- (void)readFromJSONDictionary:(id)d;

@end
