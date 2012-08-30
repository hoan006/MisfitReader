//
//  MasterViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>
#import "AddSubscriptionViewController.h"

@class DetailViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, AddSubscriptionDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)openSubscriptionView:(id)sender;

@end
