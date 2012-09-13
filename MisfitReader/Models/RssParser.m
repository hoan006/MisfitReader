//
//  RssParser.m
//  MisfitReader
//
//  Created by hoan.nguyen on 8/31/12.
//
//

#import "RssParser.h"
#import "RXMLElement.h"
#import "AppDelegate.h"
#import "Feed.h"
#import "Entry.h"

@implementation RssParser

+ (NSArray *)parseFeeds:(NSString *)xmlDoc
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:context];

    NSMutableArray *result = [NSMutableArray array];
    RXMLElement *rootXML = [RXMLElement elementFromXMLString:xmlDoc encoding:NSUTF8StringEncoding];
    [rootXML iterate:@"list.object" usingBlock: ^(RXMLElement *feedXML) {
        Feed *newFeed = [[Feed alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
        for (RXMLElement *element in [feedXML children:@"string"]) {
            if ([[element attribute:@"name"] isEqualToString:@"id"]) {
                newFeed.rss_url = element.text;
            } else if ([[element attribute:@"name"] isEqualToString:@"title"]) {
                newFeed.title = element.text;
            } else if ([[element attribute:@"name"] isEqualToString:@"htmlUrl"]) {
                newFeed.html_url = element.text;
            }
        }
        NSURL *url = [NSURL URLWithString:newFeed.html_url];
        NSString *faviconURL = [NSString stringWithFormat:@"%@://%@/favicon.ico", [url scheme], [url host]];
        NSData *favData = [NSData dataWithContentsOfURL:[NSURL URLWithString:faviconURL]];
        UIImage *image = [self imageWithImage:[UIImage imageWithData:favData] scaledToSize:CGSizeMake(16, 16)];
        newFeed.favicon = UIImagePNGRepresentation(image);
        [result addObject:newFeed];
    }];
    return result;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSDictionary *)parseUnreadCount:(NSString *)xmlDoc {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    RXMLElement *rootXML = [RXMLElement elementFromXMLString:xmlDoc encoding:NSUTF8StringEncoding];
    [rootXML iterate:@"list.object" usingBlock: ^(RXMLElement *objectXML) {
        NSString *feed_url = nil;
        int count = 0;
        for (RXMLElement * element in [objectXML children:@"string"]) {
            if ([[element attribute:@"name"] isEqualToString:@"id"]) {
                feed_url = element.text;
                break;
            }
        }
        for (RXMLElement * element in [objectXML children:@"number"]) {
            if ([[element attribute:@"name"] isEqualToString:@"count"]) {
                count = [element.text intValue];
                break;
            }
        }
        if (feed_url != nil && count > 0) {
            [result setValue:@(count) forKey:feed_url];
        }
    }];
    return result;
}

+ (NSArray *)parseEntries:(NSString *)xmlDoc
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:context];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

    NSMutableArray *result = [NSMutableArray array];
    RXMLElement *rootXML = [RXMLElement elementFromXMLString:xmlDoc encoding:NSUTF8StringEncoding];
    [rootXML iterate:@"entry" usingBlock: ^(RXMLElement *entryXML) {
        Entry *newEntry = [[Entry alloc] initWithEntity:entity insertIntoManagedObjectContext:nil];
        for (RXMLElement *linkElement in [entryXML children:@"link"]) {
            if ([[linkElement attribute:@"rel"] isEqualToString:@"alternate"])
                newEntry.link = [linkElement attribute:@"href"];
        }
        if (newEntry.link.length > 0)
        {
            newEntry.tag_id = [entryXML child:@"id"].text;
            newEntry.title = [entryXML child:@"title"].text;
            newEntry.published_at = [[dateFormatter dateFromString:[entryXML child:@"published"].text] timeIntervalSince1970];
            newEntry.updated_at = [[dateFormatter dateFromString:[entryXML child:@"updated"].text] timeIntervalSince1970];

            NSString *summary = [entryXML child:@"summary"].text;
            if (summary == nil) {
                summary = [entryXML child:@"content"].text;
            }
            if (summary != nil) {
                // remove iframe in the html content
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<iframe.*\\<\\/iframe>" options:0 error:nil];

                summary = [regex stringByReplacingMatchesInString:summary options:0 range:NSMakeRange(0, summary.length) withTemplate:@""];
            }
            newEntry.summary = summary;

            newEntry.is_read = newEntry.is_kept_unread = newEntry.is_starred = NO;
            for (RXMLElement *categoryXML in [entryXML children:@"category"])
            {
                if ([[categoryXML attribute:@"label"] isEqualToString:@"read"]) {
                    newEntry.is_read = YES;
                } else if ([[categoryXML attribute:@"label"] isEqualToString:@"kept-unread"]) {
                    newEntry.is_kept_unread = YES;
                } else if ([[categoryXML attribute:@"label"] isEqualToString:@"starred"]) {
                    newEntry.is_starred = YES;
                }
            }

            [result addObject:newEntry];
        }
    }];
    return result;
}

@end
