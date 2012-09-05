//
//  Entry.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Feed;

@interface Entry : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSDate * published_at;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) Feed *feed;

@end
