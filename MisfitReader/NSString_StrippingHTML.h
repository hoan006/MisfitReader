//
//  NSString_StrippingHTML.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import <Foundation/Foundation.h>

@interface NSString (StrippingHTML)

- (NSString *)stringByStrippingHTML;

@end

@implementation NSString (StrippingHTML)

- (NSString *) stringByStrippingHTML {
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n \t"]];
}

@end