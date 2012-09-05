//
//  DetailViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>
#import "Feed.h"

@interface DetailViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Feed* filteredFeed;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
