//
//  RssParser.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/31/12.
//
//

#import <Foundation/Foundation.h>

@interface RssParser : NSObject
+ (NSArray *)parseFeeds:(NSString *)xmlDoc;
+ (NSDictionary *)parseUnreadCount:(NSString *)xmlDoc;
+ (NSArray *)parseEntries:(NSString *)xmlDoc;
@end
