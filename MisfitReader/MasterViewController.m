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
#import "Entry.h"
#import "RXMLElement.h"
#import "MasterCell.h"

@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@property (strong, nonatomic) NSDictionary *unreadCountDict;
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

UIActivityIndicatorView *activityIndicator = nil;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = [RssFeeder instance].email;
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackToSubscriptions.png"] style:UIBarButtonItemStyleBordered target:nil action:nil];
    backButtonItem.tintColor = [UIColor scrollViewTexturedBackgroundColor];
    self.navigationItem.backBarButtonItem = backButtonItem;
    [self.refreshButton setBackButtonBackgroundImage:[UIImage imageNamed:@"ButtonBrowserLoad-landscape.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    // indicator spinner
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];

    if ([RssFeeder instance].email != nil)
    {
        [self updateSubscriptionList:nil];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
        self.refreshButton.enabled = NO;
        [self performSegueWithIdentifier:@"editAccount" sender:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)authenticateSuccess
{
    [[RssFeeder instance] loadFromCoreData];
    [self viewDidLoad];
}

- (void)removeAccountDone
{
    [[RssFeeder instance] loadFromCoreData];
    self.navigationItem.title = nil;
    [self.navigationItem setRightBarButtonItem:nil];
    self.refreshButton.enabled = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Feed *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        DetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.filteredFeed = object;
        detailViewController.managedObjectContext = self.managedObjectContext;
    }
    else if ([[segue identifier] isEqualToString:@"openSubscription"]) {
        ((AddSubscriptionViewController *)[segue destinationViewController]).delegate = self;
    } else if ([[segue identifier] isEqualToString:@"editAccount"]) {
        ((AccountViewController *)[segue destinationViewController]).delegate = self;
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

 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithData:[object valueForKey:@"favicon"]];
    cell.textLabel.text = [[object valueForKey:@"title"] description];
    int count = 0;
    for (Entry *entry in [object valueForKey:@"entries"]) {
        if (entry.is_kept_unread || !entry.is_read) {
            count++;
        }
    }
    cell.detailTextLabel.text = count > 0 ? [NSString stringWithFormat:@"%d", count] : nil;
}

- (IBAction)openSubscriptionView:(id)sender
{
    [self performSegueWithIdentifier:@"openSubscription" sender: self];
}

- (void)shouldAddNewFeed:(NSString *)feedURL
{
    [[RssFeeder instance] subscribe:3 url:feedURL delegate:self];
}

- (void)subscribeSuccess
{
    NSLog(@"*** MasterView: SUBSCRIBE SUCCESS");
    [self updateSubscriptionList:nil];
}

- (void)subscribeFailure:(NSError *)error
{
    NSLog(@"*** MasterVIew: SUSCRIBE FAILURE");
    [activityIndicator stopAnimating];
    [self showUnknownError];
}


- (IBAction)updateSubscriptionList:(id)sender
{
    UIBarButtonItem *spinnerBarButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationItem setRightBarButtonItem:spinnerBarButton];
    [activityIndicator startAnimating];
    self.refreshButton.enabled = NO;

    RssFeeder *feeder = [RssFeeder instance];
    feeder.beginningTimestamp = [self beginningTimestampToQuery];
    [feeder listSubscription:3 delegate:self];
}

int feedingIndex;
- (void)listSubscriptionSuccess:(NSArray *)result
{
    NSLog(@"*** MasterView: UPDATE SUBSCRIPTION LIST SUCCESS");
    NSArray *feeds = self.fetchedResultsController.fetchedObjects;

    // sync with local storage - add/rename feeds
    for (Feed *feed in result) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rss_url == %@", feed.rss_url];
        NSArray *filteredArray = [feeds filteredArrayUsingPredicate:predicate];
        if ([filteredArray count] == 0) {
            [self.managedObjectContext insertObject:feed];
        } else {
            ((Feed *)[filteredArray objectAtIndex:0]).title = feed.title;
        }
    }

    // sync with local storage - remove feeds
    for (Feed *feed in feeds) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rss_url == %@", feed.rss_url];
        NSArray *filteredArray = [result filteredArrayUsingPredicate:predicate];
        if ([filteredArray count] == 0) {
            [self.managedObjectContext deleteObject:feed];
        }
    }

    NSError *e;
    [self.managedObjectContext save:&e];
    if (e) NSLog(@"DATA CORE ERROR: %@", e);

    [self.tableView reloadData];
    [[RssFeeder instance] listUnreadCount:3 delegate:self];
}

- (void)listUnreadCountSuccess:(NSDictionary *)result
{
    NSLog(@"*** MasterView: UNREAD COUNT SUCCESS");
    self.unreadCountDict = result;

    // fetch entries for each feed
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        feedingIndex = 0;
        [self listEntriesAtIndex:feedingIndex];
    } else {
        [activityIndicator stopAnimating];
        self.refreshButton.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.addSubscriptionButton];
        [self updateBeginningTimestampToQuery];
    }
}

- (void)listUnreadCountFailure:(NSError *)error
{
    NSLog(@"*** MasterView: UNREAD COUNT FAILURE");
    [activityIndicator stopAnimating];
    [self showUnknownError];
}

- (void)listSubscriptionFailure:(NSError *)error
{
    NSLog(@"*** MasterView: UPDATE SUBSCRIPTION LIST FAILURE");
    [activityIndicator stopAnimating];
    self.refreshButton.enabled = YES;
    [self showUnknownError];
}

- (void)listEntriesAtIndex:(int)index
{
    Feed *feed = [[self.fetchedResultsController fetchedObjects] objectAtIndex:index];
    id object = [self.unreadCountDict objectForKey:feed.rss_url];
    int unreadCount = object == nil ? 0 : [object integerValue];
    [[RssFeeder instance] listEntries:3 feed:feed unreadCount:unreadCount delegate:self];
}

- (void)listEntriesSuccess:(Feed *)feed result:(NSArray *)entries
{
    NSLog(@"*** MasterView: LIST ENTRIES SUCCESS - %@ - %i", feed.title, entries.count);
    // store to Core Data

    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *localEntries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) NSLog(@"DATA CORE ERROR: %@", error);

    // sync with local storage - add/edit entries
    for (Entry *entry in entries) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"link == %@", entry.link];
        NSArray *filteredArray = [localEntries filteredArrayUsingPredicate:predicate];
        if ([filteredArray count] == 0) {
            Entry *entryToInsert = [NSEntityDescription insertNewObjectForEntityForName:@"Entry" inManagedObjectContext:context];
            NSArray *attKeys = [[entity attributesByName] allKeys];
            NSDictionary *attributes = [entry dictionaryWithValuesForKeys:attKeys];
            [entryToInsert setValuesForKeysWithDictionary:attributes];
            entryToInsert.feed = feed;
        } else {
            Entry *entryToUpdate = [filteredArray objectAtIndex:0];
            entryToUpdate.title = entry.title;
            entryToUpdate.updated_at = entry.updated_at;
            entryToUpdate.summary = entry.summary;
        }
    }

    NSError *e;
    [self.managedObjectContext save:&e];
    if (e) NSLog(@"DATA CORE ERROR: %@", e);

    [self.tableView reloadData];
    if (++feedingIndex < [self.fetchedResultsController fetchedObjects].count) {
        [self listEntriesAtIndex:feedingIndex];
    } else {
        [activityIndicator stopAnimating];
        self.refreshButton.enabled = YES;
        [self.navigationItem setRightBarButtonItem:self.addSubscriptionButton];
        [self updateBeginningTimestampToQuery];
    }
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

NSDate *beginningTimestamp = nil;
- (NSDate *)beginningTimestampToQuery
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDate *date = [prefs objectForKey:@"LastUpdate"];
    if (date == nil || ![date isKindOfClass:[NSDate class]])
    {
        date = [[NSDate date] dateByAddingTimeInterval: -86400.0];
    }
    NSLog(@"*** MasterView - LAST UPDATE: %@", date);
    beginningTimestamp = [NSDate date];
    return date;
}

- (void)updateBeginningTimestampToQuery
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if (beginningTimestamp != nil) {
        [prefs setObject:beginningTimestamp forKey:@"LastUpdate"];
    }
}

@end
