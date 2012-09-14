//
//  RssFeeder.m
//  MisfitReader
//
//  Created by Hoan Nguyen Ngoc on 8/27/12.
//  Copyright (c) 2012 Hoan Nguyen Ngoc. All rights reserved.
//

#import "RssFeeder.h"
#import "AFHTTPRequestOperation.h"
#import "constants.h"
#import "RssParser.h"
#import "AppDelegate.h"
#import "AccountSetting.h"
#import "Feed.h"
#import "Entry.h"

@implementation RssFeeder

+ (RssFeeder *)instance
{
    static dispatch_once_t once;
    static RssFeeder *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
        [instance loadFromCoreData];
    });
    
    return instance;
}


- (void)authenticateEmail:(void (^)(NSString *))success failure:(void (^)())failure{
    [self authenticateEmail:self.email password:self.password success:success failure:failure];
}

- (void)authenticateEmail:(NSString *)aEmail password:(NSString *)aPassword success:(void (^)(NSString *))success failure:(void (^)())failure
{
    NSURL *url = [NSURL URLWithString:kGOOGLE_CLIENT_LOGIN];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *data = [NSString stringWithFormat:@"accountType=GOOGLE&Email=%@&Passwd=%@&service=reader", aEmail, aPassword];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### AUTH SUCCESS ###");
        NSString *str = operation.responseString;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Auth=(.*)" options:0 error:NULL];
        NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        NSString *newAuthValue = [str substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"### AUTH VALUE ###: %@", newAuthValue);
        if (success) {
            success(newAuthValue);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### AUTH ERROR ###: %@",  operation.responseString);
        if (failure) {
            failure();
        }
    }];
    [operation start];
}

- (void)requestToken:(void (^)(NSString *, NSString *))followup
{
    [self requestToken:followup authValue:self.authValue];
}

- (void)requestToken:(void (^)(NSString *, NSString *))followup authValue:(NSString *)aAuthValue {
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_TOKEN];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### TOKEN SUCCESS ###: %@", operation.responseString);
        NSString *newToken = [operation.responseString substringFromIndex:2];
        if (followup) {
            followup(aAuthValue, newToken);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### TOKEN ERROR ###");
        [self authenticateEmail:^(NSString *newAuthValue){
            [self requestToken:followup authValue:newAuthValue];
        } failure:nil];
    }];
    [operation start];
}

- (void)listSubscription:(int)attempts delegate:(id<RssFeederDelegate>)delegate
{
    [self listSubscription:attempts authValue:self.authValue delegate:delegate];
}

- (void)listSubscription:(int)attempts authValue:(NSString *)aAuthValue delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: detect useful error
        if ([delegate respondsToSelector:@selector(listSubscriptionFailure:)]) {
            [delegate listSubscriptionFailure:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_SUBSCRIPTION_LIST];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"### FEED SUCCESS ###: %@", operation.responseString);
            NSArray *result = [RssParser parseFeeds:operation.responseString];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(listSubscriptionSuccess:)]) {
                    [delegate listSubscriptionSuccess:result];
                }
                // update feeder
                [self saveAuthValue:aAuthValue andToken:self.token];
            });
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### FEED ERROR ###: %@",  operation.responseString);
        [self authenticateEmail:^(NSString *authValue){
            [self listSubscription:attempts -1 authValue:authValue delegate:delegate];
        } failure:^{
            if ([delegate respondsToSelector:@selector(listSubscriptionFailure:)]) {
                [delegate listSubscriptionFailure:nil];
            }
        }];
    }];
    [operation start];
}

- (void)listUnreadCount:(int)attempts delegate:(id<RssFeederDelegate>)delegate {
    [self listUnreadCount:attempts authValue:self.authValue delegate:delegate];
}

- (void)listUnreadCount:(int)attempts authValue:(NSString *)aAuthValue delegate:(id<RssFeederDelegate>)delegate {
    if (attempts <= 0) {
        //TODO: detect useful error
        if ([delegate respondsToSelector:@selector(listUnreadCountFailure:)]) {
            [delegate listUnreadCountFailure:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_UNREAD_COUNT];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"### UNREAD COUNT SUCCESS ###: %@", operation.responseString);
            NSDictionary *result = [RssParser parseUnreadCount:operation.responseString];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(listUnreadCountSuccess:)]) {
                    [delegate listUnreadCountSuccess:result];
                }
                // update feeder
                [self saveAuthValue:aAuthValue andToken:self.token];
            });
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### UNREAD COUNT ERROR ###: %@",  operation.responseString);
        [self authenticateEmail:^(NSString *authValue){
            [self listUnreadCount:attempts -1 authValue:authValue delegate:delegate];
        } failure:^{
            if ([delegate respondsToSelector:@selector(listUnreadCountFailure:)]) {
                [delegate listUnreadCountFailure:nil];
            }
        }];
    }];
    [operation start];

}

- (void)subscribe:(int)attempts url:(NSString *)feedURL delegate:(id<RssFeederDelegate>)delegate
{
    [self subscribe:attempts url:feedURL authValue:self.authValue token:self.token delegate:delegate];
}

- (void)subscribe:(int)attempts url:(NSString *)feedURL authValue:(NSString *)aAuthValue token:(NSString *)aToken delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(subscribeFailure:)]) {
            [delegate subscribeFailure:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_SUBSCRIBE];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    NSString *data = [NSString stringWithFormat:@"quickadd=%@&T=%@", feedURL, aToken];
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### SUBSCRIBE SUCCESS ###: %@", operation.responseString);
        if ([delegate respondsToSelector:@selector(subscribeSuccess)]) {
            [delegate subscribeSuccess];
        }
        // update feeder
        [self saveAuthValue:aAuthValue andToken:aToken];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### SUBSCRIBE ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self subscribe:attempts - 1 url:feedURL authValue:newAuthValue token:newToken delegate:delegate];
        }];
    }];
    [operation start];
}

- (void)renameSubscription:(int)attempts feed:(Feed *)feed newName:(NSString *)newName delegate:(id<RssFeederDelegate>)delegate
{
    [self renameSubscription:attempts feed:feed newName:newName authValue:self.authValue token:self.token delegate:delegate];
}

- (void)renameSubscription:(int)attempts feed:(Feed *)feed newName:(NSString *)newName authValue:(NSString *)aAuthValue token:(NSString *)aToken delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(renameSubscriptionFailure:error:)]) {
            [delegate renameSubscriptionFailure:feed error:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_EDIT];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    NSString *data = [NSString stringWithFormat:@"s=%@&ac=edit&t=%@&T=%@", feed.rss_url, newName, aToken];
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### RENAME SUCCESS ###: %@", operation.responseString);
        if ([delegate respondsToSelector:@selector(renameSubscriptionSuccess:)]) {
            feed.title = newName;
            [delegate renameSubscriptionSuccess:feed];
        }
        // update feeder
        [self saveAuthValue:aAuthValue andToken:aToken];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### RENAME ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self renameSubscription:attempts - 1 feed:feed newName:newName authValue:newAuthValue token:newToken delegate:delegate];
        }];
    }];
    [operation start];
}

- (void)unsubscribe:(int)attempts feed:(Feed *)feed delegate:(id<RssFeederDelegate>)delegate
{
    [self unsubscribe:attempts feed:feed authValue:self.authValue token:self.token delegate:delegate];
}

- (void)unsubscribe:(int)attempts feed:(Feed *)feed authValue:(NSString *)aAuthValue token:(NSString *)aToken delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(renameSubscriptionFailure:error:)]) {
            [delegate renameSubscriptionFailure:feed error:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_EDIT];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    NSString *data = [NSString stringWithFormat:@"s=%@&ac=unsubscribe&t=%@&T=%@", feed.rss_url, feed.title, aToken];
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### RENAME SUCCESS ###: %@", operation.responseString);
        if ([delegate respondsToSelector:@selector(renameSubscriptionSuccess:)]) {
            [delegate unsubscribeSuccess:feed];
        }
        // update feeder
        [self saveAuthValue:aAuthValue andToken:aToken];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### RENAME ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self unsubscribe:attempts - 1 feed:feed authValue:newAuthValue token:newToken delegate:delegate];
        }];
    }];
    [operation start];
}

- (void)listEntries:(int)attempts feed:(Feed *)feed unreadCount:(int)unreadCount delegate:(id<RssFeederDelegate>)delegate
{
    [self listEntries:attempts feed:feed unreadCount:unreadCount authValue:self.authValue delegate:delegate];
}

- (void)listEntries:(int)attempts feed:(Feed *)feed unreadCount:(int)unreadCount authValue:(NSString *)aAuthValue delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(listEntriesFailure:error:)]) {
            [delegate listEntriesFailure:feed error:nil];
        }
        return;
    }
    NSString *urlString = [feed.entries count] == 0 ? [NSString stringWithFormat:kGOOGLE_READER_UNREAD_ENTRIES_FROM_FEED_URL_AND_COUNT, feed.rss_url, @(unreadCount)] : [NSString stringWithFormat:kGOOGLE_READER_UNREAD_ENTRIES_FROM_FEED_URL_AND_TIMESTAMP, feed.rss_url, @((int)(double)[self.beginningTimestamp timeIntervalSince1970])];

    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            //detect response is a XML or HTML
            if ([[operation.responseString substringToIndex:30] rangeOfString:@"<html"].location != NSNotFound)
            {
                NSLog(@"### LIST ENTRIES REDIRECT ###");
                [self authenticateEmail:^(NSString *authValue){
                    [self listEntries:attempts -1 feed:feed unreadCount:unreadCount authValue:authValue delegate:delegate];
                } failure:^{
                    if ([delegate respondsToSelector:@selector(listEntriesFailure:error:)]) {
                        [delegate listEntriesFailure:feed error:nil];
                    }
                }];
            } else {
                NSLog(@"### LIST ENTRIES SUCCESS ### ");
                NSArray *entries = [RssParser parseEntries:operation.responseString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(listEntriesSuccess:result:)]) {
                        [delegate listEntriesSuccess:feed result:entries];
                    }
                });
            }
        });
        // update feeder
        [self saveAuthValue:aAuthValue andToken:self.token];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### LIST ENTRIES ERROR ###: %@",  operation.responseString);
        [self authenticateEmail:^(NSString *authValue){
            [self listEntries:attempts -1 feed:feed unreadCount:unreadCount authValue:authValue delegate:delegate];
        } failure:^{
            if ([delegate respondsToSelector:@selector(listEntriesFailure:error:)]) {
                [delegate listEntriesFailure:feed error:nil];
            }
        }];
    }];
    [operation start];
}

- (void)readEntry:(int)attempts entry:(Entry *)entry status:(BOOL)status delegate:(id<RssFeederDelegate>)delegate
{
    [self readEntry:attempts entry:entry status:status authValue:self.authValue token:self.token delegate:delegate];
}

- (void)readEntry:(int)attempts entry:(Entry *)entry status:(BOOL)status authValue:(NSString *)aAuthValue token:(NSString *)aToken delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(readEntryFailure:error:)]) {
            [delegate readEntryFailure:entry error:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_SET_TAG];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    NSString *data;
    if (status) // add 'read' tag and remove 'kept-unread' tag
    {
        data = [NSString stringWithFormat:@"r=%@&a=%@&async=true&s=%@&i=%@&T=%@", kGOOGLE_READER_USER_STATE_KEPT_UNREAD, kGOOGLE_READER_USER_STATE_READ, entry.feed.rss_url, entry.tag_id, aToken];
    } else {
        data = [NSString stringWithFormat:@"r=%@&a=%@&async=true&s=%@&i=%@&T=%@", kGOOGLE_READER_USER_STATE_READ, kGOOGLE_READER_USER_STATE_KEPT_UNREAD, entry.feed.rss_url, entry.tag_id, aToken];
    }
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### READ ENTRY SUCCESS ###: %@", operation.responseString);
        if ([delegate respondsToSelector:@selector(readEntrySuccess:)]) {
            [delegate readEntrySuccess:entry];
        }
        // update feeder
        [self saveAuthValue:aAuthValue andToken:aToken];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### READ ENTRY ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self readEntry:attempts - 1 entry:entry status:status authValue:newAuthValue token:newToken delegate:delegate];
        }];
    }];
    [operation start];
}

- (void)starEntry:(int)attempts entry:(Entry *)entry status:(BOOL)status delegate:(id<RssFeederDelegate>)delegate
{
    [self starEntry:attempts entry:entry status:status authValue:self.authValue token:self.token delegate:delegate];
}

- (void)starEntry:(int)attempts entry:(Entry *)entry status:(BOOL)status authValue:(NSString *)aAuthValue token:(NSString *)aToken delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(starEntryFailure:error:)]) {
            [delegate starEntryFailure:entry error:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_SET_TAG];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    NSString *data;
    if (status) // add 'read' tag and remove 'kept-unread' tag
    {
        data = [NSString stringWithFormat:@"r=%@&async=true&s=%@&i=%@&T=%@", kGOOGLE_READER_USER_STATE_STARRED, entry.feed.rss_url, entry.tag_id, aToken];
    } else {
        data = [NSString stringWithFormat:@"a=%@&async=true&s=%@&i=%@&T=%@", kGOOGLE_READER_USER_STATE_STARRED, entry.feed.rss_url, entry.tag_id, aToken];
    }
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### STAR ENTRY SUCCESS ###: %@", operation.responseString);
        if ([delegate respondsToSelector:@selector(starEntrySuccess:)]) {
            [delegate starEntrySuccess:entry];
        }
        // update feeder
        [self saveAuthValue:aAuthValue andToken:aToken];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### STAR ENTRY ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self starEntry:attempts - 1 entry:entry status:status authValue:newAuthValue token:newToken delegate:delegate];
        }];
    }];
    [operation start];
}

- (void)markAllAsRead:(int)attempts feed:(Feed *)feed delegate:(id<RssFeederDelegate>)delegate
{
    [self markAllAsRead:attempts feed:feed authValue:self.authValue token:self.token delegate:delegate];
}

- (void)markAllAsRead:(int)attempts feed:(Feed *)feed authValue:(NSString *)aAuthValue token:(NSString *)aToken delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(markAllAsReadFailure:error:)]) {
            [delegate markAllAsReadFailure:feed error:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_MARK_ALL_AS_READ];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    NSString *data = [NSString stringWithFormat:@"s=%@&ts=%@&T=%@", feed.rss_url, @((int)(double)[[NSDate date] timeIntervalSince1970]), aToken];
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### MARK ALL AS READ SUCCESS ###: %@", operation.responseString);
        if ([delegate respondsToSelector:@selector(markAllAsReadSuccess:)]) {
            [delegate markAllAsReadSuccess:feed];
        }
        // update feeder
        [self saveAuthValue:aAuthValue andToken:aToken];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### MARK ALL AS READ ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self markAllAsRead:attempts - 1 feed:feed authValue:newAuthValue token:newToken delegate:delegate];
        }];
    }];
    [operation start];
}

- (BOOL)loadFromCoreData
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AccountSetting" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSError *e;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&e];
    if (result.count > 0)
    {
        AccountSetting *account = [result objectAtIndex:0];
        self.email = account.email;
        self.password = account.password;
        self.authValue = account.google_auth;
        self.token = account.google_token;
        return YES;
    } else {
        self.email = self.password = self.authValue = self.token = nil;
    }
    return NO;
}

- (void)saveAuthValue:(NSString *)aAuthValue andToken:(NSString *)aToken
{
    self.authValue = aAuthValue;
    self.token = aToken;

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AccountSetting" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSError *e;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&e];
    if (result.count == 0)
    {
        AccountSetting *account = [NSEntityDescription insertNewObjectForEntityForName:@"AccountSetting"
                                                                inManagedObjectContext:context];
        account.email = self.email;
        account.password = self.password;
        account.google_auth = self.authValue;
        account.google_token = self.token;
    } else {
        AccountSetting *account = [result objectAtIndex:0];
        account.google_auth = self.authValue;
        account.google_token = self.token;
    }
    [context save:nil];
}

- (NSDate *)beginningTimestamp
{
    if (_beginningTimestamp == nil) {
        _beginningTimestamp = [[NSDate date] dateByAddingTimeInterval:-86400];
    }
    return _beginningTimestamp;
}

@end
