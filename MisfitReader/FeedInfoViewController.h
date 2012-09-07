//
//  FeedInfoViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import <UIKit/UIKit.h>
#import "RssFeeder.h"
@class Feed;

@interface FeedInfoViewController : UITableViewController<RssFeederDelegate>

@property (strong, nonatomic) Feed *feed;
@property (weak, nonatomic) IBOutlet UITableViewCell *openWebPageCell;

- (IBAction)renameSubscription:(id)sender;
- (IBAction)unsubscribe:(id)sender;
- (IBAction)newFolder:(id)sender;

@end
