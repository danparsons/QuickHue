//
//  NSAttributedString+Hyperlink.h
//  QuickHue
//
//  Created by Dan Parsons on 12/23/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Hyperlink)

+ (id)hyperlinkFromString:(NSString *)inString withURL:(NSURL *)url;

@end
