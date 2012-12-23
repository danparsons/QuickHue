//
//  NSAttributedString+Hyperlink.m
//  QuickHue
//
//  Created by Dan Parsons on 12/23/12.
//  Copyright (c) 2012 Dan Parsons. All rights reserved.
//

#import "NSAttributedString+Hyperlink.h"

@implementation NSAttributedString (Hyperlink)

+ (id)hyperlinkFromString:(NSString *)inString withURL:(NSURL *)url {
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:inString];
    NSRange range = NSMakeRange(0, str.length);
    [str beginEditing];
    [str addAttribute:NSLinkAttributeName value:url.absoluteString range:range];
    NSColor *lightBlueColor = [NSColor colorWithSRGBRed:0.378 green:0.547 blue:0.901 alpha:1];
    [str addAttribute:NSForegroundColorAttributeName value:lightBlueColor range:range];
    [str endEditing];
    return str;
}

@end
