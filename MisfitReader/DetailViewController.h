//
//  DetailViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>
#import "SummaryViewController.h"
@class Feed;

@interface DetailViewController : UITableViewController<NSFetchedResultsControllerDelegate, SummaryViewControllerDelegate>

@property (strong, nonatomic) Feed* filteredFeed;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)showFeedInfo:(id)sender;
@end
