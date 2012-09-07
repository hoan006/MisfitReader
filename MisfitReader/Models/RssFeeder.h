//
//  RssFeeder.h
//  MisfitReader
//
//  Created by Hoan Nguyen Ngoc on 8/27/12.
//  Copyright (c) 2012 Hoan Nguyen Ngoc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Feed;

@protocol RssFeederDelegate <NSObject>

@optional
- (void)subscribeSuccess;
- (void)subscribeFailure:(NSError *)error;
- (void)listSubscriptionSuccess:(NSArray *)result;
- (void)listSubscriptionFailure:(NSError *)error;
- (void)listEntriesSuccess:(Feed *)feed result:(NSArray *)entries;
- (void)listEntriesFailure:(Feed *)feed error:(NSError *)error;
- (void)renameSubscriptionSuccess:(Feed *)feed;
- (void)renameSubscriptionFailure:(Feed *)feed error:(NSError *)error;
- (void)unsubscribeSuccess:(Feed *)feed;
- (void)unsubscribeFailure:(Feed *)feed error:(NSError *)error;

@end

@interface RssFeeder : NSObject

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *authValue;
@property (strong, nonatomic) NSString *token;

+ (RssFeeder *)instance;
- (void)authenticateEmail:(void (^)(NSString *))followup;
- (void)requestToken:(void (^)(NSString *, NSString *))followup;
- (void)listSubscription:(int)attempts delegate:(id<RssFeederDelegate>)delegate;
- (void)subscribe:(int)attempts url:(NSString *)feedURL delegate:(id<RssFeederDelegate>)delegate;
- (void)renameSubscription:(int)attempts feed:(Feed *)feed newName:(NSString *)newName delegate:(id<RssFeederDelegate>)delegate;
- (void)unsubscribe:(int)attempts feed:(Feed *)feed delegate:(id<RssFeederDelegate>)delegate;
- (void)listEntries:(int)attempts feed:(Feed *)feed delegate:(id<RssFeederDelegate>)delegate;
@end
