//
//  DetailViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>
#import "SummaryViewController.h"
#import "RssFeeder.h"
@class Feed;

@interface DetailViewController : UITableViewController<NSFetchedResultsControllerDelegate, SummaryViewControllerDelegate, RssFeederDelegate>

@property (strong, nonatomic) Feed* filteredFeed;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *readAllButtonItem;

- (IBAction)showFeedInfo:(id)sender;
- (IBAction)touchReadAll:(id)sender;
@end
