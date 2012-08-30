//
//  RssFeeder.h
//  MisfitReader
//
//  Created by Hoan Nguyen Ngoc on 8/27/12.
//  Copyright (c) 2012 Hoan Nguyen Ngoc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RssFeeder : NSObject

@property (weak, nonatomic) NSString *email;
@property (weak, nonatomic) NSString *password;
@property (weak, nonatomic) NSString *authValue;
@property (weak, nonatomic) NSString *token;
+ (RssFeeder *)instance;
- (void)authenticateEmail:(void (^)(NSString *))followup;
- (void)requestToken:(void (^)(NSString *, NSString *))followup;
- (void)feedRss:(int)attempts;
- (void)subscribe:(int)attempts url:(NSString *)feedURL;

@end
