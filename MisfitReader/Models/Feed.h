//
//  Feed.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Feed : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * html_url;
@property (nonatomic, retain) NSString * rss_url;
@property (nonatomic, retain) NSSet *entries;
@end

@interface Feed (CoreDataGeneratedAccessors)

- (void)addEntriesObject:(NSManagedObject *)value;
- (void)removeEntriesObject:(NSManagedObject *)value;
- (void)addEntries:(NSSet *)values;
- (void)removeEntries:(NSSet *)values;

@end
