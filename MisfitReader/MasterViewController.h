//
//  MasterViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>
#import "AddSubscriptionViewController.h"
#import "RssFeeder.h"

@class DetailViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, AddSubscriptionDelegate, RssFeederDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *addSubscriptionButton;
- (IBAction)openSubscriptionView:(id)sender;
- (IBAction)updateSubscriptionList:(id)sender;

@end
