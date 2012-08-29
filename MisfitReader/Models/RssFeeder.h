//
//  RssFeeder.h
//  MisfitReader
//
//  Created by Hoan Nguyen Ngoc on 8/27/12.
//  Copyright (c) 2012 Hoan Nguyen Ngoc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RssFeeder : NSObject

+ (void)authenticateEmail:(NSString *)email password:(NSString *)password followup:(void (^)(NSString *authValue))followup;
+ (void)feedRss:(NSString *)urlString withToken:(NSString *)token;

@end
