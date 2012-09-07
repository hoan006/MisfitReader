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

@implementation RssFeeder

+ (RssFeeder *)instance
{
    static RssFeeder *_instance = nil;
    
    @synchronized( self ) {
        if( _instance == nil ) {
            _instance = [[ RssFeeder alloc ] init ];
            [_instance loadFromCoreData];
        }
    }
    
    return _instance;
}

- (void)authenticateEmail:(void (^)(NSString *))followup {
    NSURL *url = [NSURL URLWithString:kGOOGLE_CLIENT_LOGIN];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *data = [NSString stringWithFormat:@"accountType=GOOGLE&Email=%@&Passwd=%@&service=reader", self.email, self.password];
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
        if (followup) {
            followup(newAuthValue);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### AUTH ERROR ###: %@",  operation.responseString);
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
        }];
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

- (void)listEntries:(int)attempts feed:(Feed *)feed delegate:(id<RssFeederDelegate>)delegate
{
    [self listEntries:attempts feed:feed authValue:self.authValue delegate:delegate];
}

- (void)listEntries:(int)attempts feed:(Feed *)feed authValue:(NSString *)aAuthValue delegate:(id<RssFeederDelegate>)delegate
{
    if (attempts <= 0) {
        //TODO: Detect useful error
        if ([delegate respondsToSelector:@selector(listEntriesFailure:error:)]) {
            [delegate listEntriesFailure:feed error:nil];
        }
        return;
    }
    NSURL *url = [NSURL URLWithString:[kGOOGLE_READER_NEW_FEEDS stringByAppendingString:feed.rss_url]];
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
                    [self listEntries:attempts -1 feed:feed authValue:authValue delegate:delegate];
                }];
            } else {
                NSLog(@"### LIST ENTRIES SUCCESS ###");
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
            [self listEntries:attempts -1 feed:feed authValue:authValue delegate:delegate];
        }];
    }];
    [operation start];
}

- (void)loadFromCoreData
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
    } else {
        self.email = @"einherjar006@gmail.com";
        self.password = @"26111995";
        self.authValue = self.token = @"";
    }
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

- (NSDate *)lastUpdate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    id date = [prefs stringForKey:@"LastUpdate"];
    if (date == nil || ![date isKindOfClass:[NSDate class]])
    {
        return [[NSDate date] dateByAddingTimeInterval: -86400.0];
    }
    return date;
}

- (void)setLastUpdate:(NSDate *)date
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:date forKey:@"LastUpdate"];
}

@end
