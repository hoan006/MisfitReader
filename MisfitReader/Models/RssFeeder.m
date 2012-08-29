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

@implementation RssFeeder

+ (void)authenticateEmail:(NSString *)email password:(NSString *)password followup:(void (^)(NSString *authValue))followup {
    NSURL *url = [NSURL URLWithString:kGOOGLE_CLIENT_LOGIN];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *data = [NSString stringWithFormat:@"accountType=GOOGLE&Email=%@&Passwd=%@&service=reader", email, password];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success: %@", operation.responseString);
        NSString *str = operation.responseString;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Auth=(.*)" options:0 error:NULL];
        NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
        NSString *authValue = [str substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"%@", authValue);
        if (followup) {
            followup(authValue);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@",  operation.responseString);
    }];
    [operation start];
}

+ (void)feedRss:(NSString *)urlString withToken:(NSString *)token
{
    NSURL *url = [NSURL URLWithString:kGOOGLE_READER_SUBSCRIPTION_LIST];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8r zlib/1.2.5" forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"GoogleLogin auth=%@", token] forHTTPHeaderField:@"Authorization"];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success: %@", operation.responseString);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@",  operation.responseString);
    }];
    [operation start];
}

//+ (void)requestToken:(NSString *)code {
//    NSURL *url = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request setHTTPMethod:@"POST"];
//    NSString *dataString = [NSString stringWithFormat:@"code=%@&client_id=500315435164.apps.googleusercontent.com&client_secret=35vT7BL7Wp5bnuDNBvIBpOiW&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code", code];
//    NSData *dataEncoded = [dataString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//    NSString *dataLength = [NSString stringWithFormat:@"%d",[dataEncoded length]];
//    [request addValue:dataLength forHTTPHeaderField:@"Content-Length"];
//    [request setHTTPBody:dataEncoded];
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"success: %@", operation.responseString);
//        NSError *e = nil;
//        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[operation.responseString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] options:NSJSONReadingMutableContainers error:&e];
//        NSString *token = [json objectForKey:@"access_token"];
//        [self feedRss:nil withToken:token];
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error: %@",  operation.responseString);
//    }];
//    [operation start];
//}
@end
