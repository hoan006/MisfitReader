//
//  MasterViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "Feed.h"
#import "RXMLElement.h"
#import "MasterCell.h"

@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.navigationItem.title = [RssFeeder instance].email;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ᐸ" style:UIBarButtonItemStyleBordered target:nil action:nil];
    self.navigationController.toolbarHidden = NO;
    [RssFeeder instance].delegate = self;

    [self updateSubscriptionList:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchedResultsController fetchedObjects].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MasterCell"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
    else if ([[segue identifier] isEqualToString:@"openSubscription"]) {
        ((AddSubscriptionViewController *)[segue destinationViewController]).delegate = self;
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    // Set the batch size to a suitable number.
    // [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithData:[object valueForKey:@"favicon"]];
    cell.textLabel.text = [[object valueForKey:@"title"] description];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [(NSSet *)[object valueForKey:@"entries"] count]];
}

- (IBAction)openSubscriptionView:(id)sender
{
    [self performSegueWithIdentifier:@"openSubscription" sender: self];
}

- (void)shouldAddNewFeed:(NSString *)feedURL
{
    [[RssFeeder instance] subscribe:3 url:feedURL];
}

- (void)subscribeSuccess
{
    NSLog(@"*** MasterView: SUBSCRIBE SUCCESS");
    [self updateSubscriptionList:nil];
}

- (void)subscribeFailure:(NSError *)error
{
    NSLog(@"*** MasterVIew: SUSCRIBE FAILURE");
    [self showUnknownError];
}

- (IBAction)updateSubscriptionList:(id)sender
{
    //[[RssFeeder instance] listSubscription:3];

    NSArray *feeds = self.fetchedResultsController.fetchedObjects;
    if (feeds.count > 0) {
        feedingIndex = 0;
        [self listEntriesAtIndex:feedingIndex];
    }
}

- (void)listSubscriptionSuccess:(NSArray *)result
{
    NSLog(@"*** MasterView: UPDATE SUBSCRIPTION LIST SUCCESS");
    NSArray *feeds = self.fetchedResultsController.fetchedObjects;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // sync with local storage - add/rename feeds
        for (Feed *feed in result) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rss_url MATCHES %@", feed.rss_url];
            NSArray *filteredArray = [feeds filteredArrayUsingPredicate:predicate];
            if ([filteredArray count] == 0) {
                [self.managedObjectContext insertObject:feed];
            } else {
                ((Feed *)[filteredArray objectAtIndex:0]).title = feed.title;
            }
        }

        // sync with local storage - remove feeds
        for (Feed *feed in feeds) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rss_url MATCHES %@", feed.rss_url];
            NSArray *filteredArray = [result filteredArrayUsingPredicate:predicate];
            if ([filteredArray count] == 0) {
                [self.managedObjectContext deleteObject:feed];
            }
        }
        [self.managedObjectContext save:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });

        // fetch entries for each feed
        if (feeds.count > 0) {
            feedingIndex = 0;
            [self listEntriesAtIndex:feedingIndex];
        }
    });
}

- (void)listSubscriptionFailure:(NSError *)error
{
    NSLog(@"*** MasterView: UPDATE SUBSCRIPTION LIST FAILURE");
    [self showUnknownError];
}


int feedingIndex;

- (void)listEntriesAtIndex:(int)index
{
    NSArray *feeds = self.fetchedResultsController.fetchedObjects;
    if (index < feeds.count) {
        Feed *feed = [feeds objectAtIndex:index];
        [[RssFeeder instance] listEntries:3 feed:feed];
    }
}

- (void)listEntriesSuccess:(Feed *)feed xml:(NSString *)xmlDoc
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"*** MasterView: LIST ENTRIES SUCCESS - %@", feed.title);
        RXMLElement *rootXML = [RXMLElement elementFromXMLString:xmlDoc encoding:NSUTF8StringEncoding];
        int entryCount = [rootXML children:@"entry"].count;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateEntriesCount:entryCount];
            [self listEntriesAtIndex:++feedingIndex];
        });
    });
}

- (void)updateEntriesCount:(int)count
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:feedingIndex inSection:0];
    MasterCell *cell = (MasterCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", count];
}

- (void)listEntriesFailure:(Feed *)feed error:(NSError *)error
{
    NSLog(@"*** MasterView: LIST ENTRIES FAILURE - %@", feed.title);
    [self listEntriesAtIndex:++feedingIndex];
}

- (void)showUnknownError
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Something's wrong. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
