//
//  Entry.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/13/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Feed;

@interface Entry : NSManagedObject

@property (nonatomic, retain) NSString * tag_id;
@property (nonatomic, retain) NSString * link;
@property (nonatomic) NSTimeInterval published_at;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * title;
@property (nonatomic) NSTimeInterval updated_at;
@property (nonatomic) BOOL is_read;
@property (nonatomic) BOOL is_starred;
@property (nonatomic) BOOL is_kept_unread;
@property (nonatomic, retain) Feed *feed;

@end
