//
//  Feed.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/3/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Entry;

@interface Feed : NSManagedObject

@property (nonatomic, retain) NSString * html_url;
@property (nonatomic, retain) NSString * rss_url;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSData * favicon;
@property (nonatomic, retain) NSSet *entries;
@end

@interface Feed (CoreDataGeneratedAccessors)

- (void)addEntriesObject:(Entry *)value;
- (void)removeEntriesObject:(Entry *)value;
- (void)addEntries:(NSSet *)values;
- (void)removeEntries:(NSSet *)values;

@end
