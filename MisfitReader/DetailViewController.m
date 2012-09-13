//
//  DetailViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import "Feed.h"
#import "Entry.h"
#import "DetailViewController.h"
#import "NSString_StrippingHTML.h"
#import "DetailCell.h"
#import "SummaryViewController.h"
#import "UIBarButtonItem_ImageButton.h"
#import "FeedInfoViewController.h"

@interface DetailViewController ()
@end

@implementation DetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.filteredFeed.title;
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackToSubscriptions.png"] style:UIBarButtonItemStyleBordered target:nil action:nil];
    backButtonItem.tintColor = [UIColor darkGrayColor];
    self.navigationItem.backBarButtonItem = backButtonItem;
    
    if (self.filteredFeed) {
        // draw favicon on the button background
        UIImage *background = [UIImage imageNamed:@"button.png"];
        UIImage *favicon = [UIImage imageWithData:self.filteredFeed.favicon];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem barItemWithImage:favicon backgroundImage:background target:self action:@selector(showFeedInfo:)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell"];
    if (cell == nil) {
        // Load the top-level objects from the custom cell XIB.
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"DetailCell" owner:self options:nil];
        // Grab a pointer to the first object (presumably the custom cell, as that's all the XIB should contain).
        cell = [topLevelObjects objectAtIndex:0];
        
        // force cell to resize width
        CGRect frame = cell.frame;
        frame.size.width = self.tableView.frame.size.width;
        cell.frame = frame;
    }
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
    [self performSegueWithIdentifier:@"showSummary" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showSummary"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Entry *entry = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        SummaryViewController *summarylViewController = [segue destinationViewController];
        summarylViewController.entry = entry;
        summarylViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"showFeedInfo"]) {
        FeedInfoViewController *feedInfoViewController = [segue destinationViewController];
        feedInfoViewController.feed = self.filteredFeed;
    }
}

NSIndexPath *currentPath = nil;
- (Entry *)nextEntry
{
    if (currentPath == nil) {
        currentPath = [self.tableView indexPathForSelectedRow];
    }
    if (currentPath.row >= [self tableView:self.tableView numberOfRowsInSection:currentPath.section] - 1) {
        return nil;
    }
    NSIndexPath *nextPath = [NSIndexPath indexPathForRow:currentPath.row+1 inSection:currentPath.section];
    return [self.fetchedResultsController objectAtIndexPath:nextPath];
}

- (Entry *)previousEntry
{
    if (currentPath == nil) {
        currentPath = [self.tableView indexPathForSelectedRow];
    }
    if (currentPath.row <= 0) {
        return nil;
    }
    NSIndexPath *previousPath = [NSIndexPath indexPathForRow:currentPath.row-1 inSection:currentPath.section];
    return [self.fetchedResultsController objectAtIndexPath:previousPath];
}

- (void)shiftIndexPathBackOrForward:(BOOL)forward
{
    if (currentPath == nil) {
        currentPath = [self.tableView indexPathForSelectedRow];
    }
    currentPath = [NSIndexPath indexPathForRow:currentPath.row + (forward ? 1 : -1) inSection:currentPath.section];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    // Set the batch size to a suitable number.
    // [fetchRequest setFetchBatchSize:20];

    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updated_at" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];

    // set filter
    if (self.filteredFeed) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self.feed == %@)", self.filteredFeed];
        [fetchRequest setPredicate:predicate];
    }

    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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

 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
     // In the simplest, most efficient, case, reload the table view.
     [self.tableView reloadData];
 }

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Entry *entry = [self.fetchedResultsController objectAtIndexPath:indexPath];
    DetailCell *detailCell = (DetailCell *)cell;
    detailCell.feedIcon.image = [UIImage imageWithData:entry.feed.favicon];
    detailCell.feedTitle.text = entry.feed.title;
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm";
    detailCell.entryTime.text = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:entry.updated_at]];
    detailCell.entryTitle.text = entry.title;

    // configure category, title, summary position & height
    CGSize labelSize = [detailCell.entryTitle.text sizeWithFont:detailCell.entryTitle.font];
    CGRect titleFrame = detailCell.entryTitle.frame;
    CGRect summaryFrame = detailCell.entrySummary.frame;
    CGRect categoryFrame = detailCell.categoryView.frame;

    if (labelSize.width > detailCell.entryTitle.frame.size.width) {
        titleFrame.size.height = 40;
        summaryFrame.origin.y = 40;
        summaryFrame.size.height = 20;
        categoryFrame.origin.y = 42;
    } else {
        titleFrame.size.height = 20;
        summaryFrame.origin.y = 20;
        summaryFrame.size.height = 40;
        categoryFrame.origin.y = 22;
    }
    detailCell.entryTitle.frame = titleFrame;
    detailCell.entrySummary.frame = summaryFrame;

    // configure category width & show/hide buttons
    int numberOfVisibleButtons = 0;
    if (entry.is_kept_unread || !entry.is_read) {
        numberOfVisibleButtons++;
        detailCell.unreadButton.hidden = NO;
    } else {
        detailCell.unreadButton.hidden = YES;
    }
    if (entry.is_starred) {
        numberOfVisibleButtons++;
        detailCell.starredButton.hidden = NO;
    } else {
        detailCell.starredButton.hidden = YES;
    }

    categoryFrame.size.width = 16 * numberOfVisibleButtons;
    detailCell.categoryView.frame = categoryFrame;

    // add padding space for summary text (for category buttons)
    if (numberOfVisibleButtons > 0) {
        NSString *paddingSpace = @" ";
        for (int i = 0; i < numberOfVisibleButtons; i++) {
            paddingSpace = [paddingSpace stringByAppendingString:@"    "];
        }
        detailCell.entrySummary.text = [paddingSpace stringByAppendingString:[entry.summary stringByStrippingHTML]];
    } else {
        detailCell.entrySummary.text = [entry.summary stringByStrippingHTML];
    }

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}

- (IBAction)showFeedInfo:(id)sender {
    [self performSegueWithIdentifier:@"showFeedInfo" sender:self];
}

@end
