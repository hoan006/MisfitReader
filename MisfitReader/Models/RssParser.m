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
            newEntry.title = [entryXML child:@"title"].text;
            newEntry.published_at = [dateFormatter dateFromString:[entryXML child:@"published"].text];
            newEntry.updated_at = [dateFormatter dateFromString:[entryXML child:@"updated"].text];
            newEntry.summary = [entryXML child:@"summary"].text;
            [result addObject:newEntry];
        }
    }];
    return result;
}

@end
