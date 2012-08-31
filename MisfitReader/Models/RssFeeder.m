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
#import "RXMLElement.h"
#import "AppDelegate.h"
#import "AccountSetting.h"

@implementation RssFeeder

+ (RssFeeder *)instance
{
    static RssFeeder* _instance = nil;
    
    @synchronized( self ) {
        if( _instance == nil ) {
            _instance = [[ RssFeeder alloc ] init ];
            // should load authValue from Core Data
            _instance.authValue = @"";
            _instance.token = @"";
            _instance.email = @"einherjar006@gmail.com";
            _instance.password = @"26111995";
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

- (void)feedRss:(int)attempts
{
    [self feedRss:attempts authValue:self.authValue];
}

- (void)feedRss:(int)attempts authValue:(NSString *)aAuthValue
{
    if (attempts <= 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_SUBSCRIPTION_LIST];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:kCURL_USER_AGENT forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", aAuthValue] forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"### FEED SUCCESS ###: %@", operation.responseString);
        // update feeder
        self.authValue = aAuthValue;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### FEED ERROR ###: %@",  operation.responseString);
        [self authenticateEmail:^(NSString *authValue){
            self.authValue = authValue;
            [self feedRss:attempts -1];
        }];
    }];
    [operation start];
}

- (void)subscribe:(int)attempts url:(NSString *)feedURL
{
    [self subscribe:attempts url:feedURL authValue:self.authValue token:self.token];
}

- (void)subscribe:(int)attempts url:(NSString *)feedURL authValue:(NSString *)aAuthValue token:(NSString *)aToken
{
    if (attempts <= 0) {
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
        // update feeder
        self.authValue = aAuthValue;
        self.token = aToken;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"### SUBSCRIBE ERROR ###: %@",  operation.responseString);
        [self requestToken:^(NSString *newAuthValue, NSString *newToken){
            [self subscribe:attempts - 1 url:feedURL authValue:newAuthValue token:newToken];
        }];
    }];
    [operation start];
}

- (void)test
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AccountSetting" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    // Set the batch size to a suitable number.
//    [fetchRequest setFetchBatchSize:20];

    // Edit the sort key as appropriate.
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"email" ascending:NO];
//    [fetchRequest setSortDescriptors:@[sortDescriptor]];

    NSError *e;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&e];
    for (AccountSetting* item in result)
    {
        [context deleteObject:item];
    }
    [context save:nil];

//    AccountSetting *account = [NSEntityDescription insertNewObjectForEntityForName:@"AccountSetting"
//                                                            inManagedObjectContext:context];
//    account.email = @"einherjar006@gmail.com";
//    account.password = @"26111995";
//    account.google_auth = @"DQAAALQAAACSo216ejL60f_qQcBP5PUa1mRdV50HHQlhx8JW4ssXVRO3tVA2v1dKQLODk9VipPGww-7ltjKmpkgEt96XWKNqCAYtwJVizrV5-ZUszDQDXWXpQqLBa7hFZly1OPEce6sqQUe4_jA_rL1H0ykJNf0mYrWgJgUEtYwjsHpd1bJMRZx7sp204eYZikOr4TJCQbQnSANlTxBmxKxt2_muqJkZWvdmQfZ5tzNNopUQffL7VziPSuCYmEHgfl6t4ZpJNtQ";
//    account.google_token = @"MWoeRSFvBlxe_KObCsgKgw";
//    [context save:nil];
}

@end
