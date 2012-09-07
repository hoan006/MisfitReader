//
//  FeedInfoViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import "Feed.h"
#import "FeedInfoViewController.h"
#import "WebsiteViewController.h"
#import "BlockAlertView.h"
#import "BlockTextPromptAlertView.h"
#import "MasterViewController.h"

@interface FeedInfoViewController ()

@end

@implementation FeedInfoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.openWebPageCell.imageView.image = [UIImage imageWithData:self.feed.favicon];
    self.openWebPageCell.textLabel.text = self.feed.title;
    NSURL *feedURL = [NSURL URLWithString:self.feed.html_url];
    self.openWebPageCell.detailTextLabel.text = [feedURL host];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 1)
        return 2;
    else
        return 1;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell"];
//    
//    // Configure the cell...
//    
//    return cell;
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showWebsite"]) {
        WebsiteViewController *websiteViewController = [segue destinationViewController];
        websiteViewController.feed = self.feed;
    }
}

- (IBAction)newFolder:(id)sender
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:nil message:@"To be implemented"];
    [alert setCancelButtonWithTitle:@"OK" block:nil];
    [alert show];
}

- (IBAction)renameSubscription:(id)sender
{
    BlockTextPromptAlertView *alert = [BlockTextPromptAlertView promptWithTitle:nil message:@"What would you like to call this subscription?" defaultText:self.feed.title block:^(BlockTextPromptAlertView *alert) {
        [alert.textField resignFirstResponder];
        return YES;
    }];

    [alert setCancelButtonWithTitle:@"Cancel" block:nil];
    [alert addButtonWithTitle:@"Rename" block:^{
        [[RssFeeder instance] renameSubscription:3 feed:self.feed newName:((BlockTextPromptAlertView *)alert).textField.text delegate:self];
    }];
    [alert show];
}

- (IBAction)unsubscribe:(id)sender
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:nil message:@"Are you sure you want to unsubscribe?"];
    [alert setDestructiveButtonWithTitle:@"Unsubscribe" block:^{
        [[RssFeeder instance] unsubscribe:3 feed:self.feed delegate:self];
    }];
    [alert setCancelButtonWithTitle:@"Nevermind" block:nil];
    [alert show];
}

- (void)renameSubscriptionSuccess:(Feed *)feed
{
    NSLog(@"*** FEED INFO - RENAME SUCCESS");
    [self popToMasterView];
}

- (void)renameSubscriptionFailure:(Feed *)feed error:(NSError *)error
{
    NSLog(@"*** FEED INFO - RENAME ERROR");
}

- (void)unsubscribeSuccess:(Feed *)feed
{
    NSLog(@"*** FEED INFO - UNSUBSCRIBE SUCCESS");
    [self popToMasterView];
}
- (void)unsubscribeFailure:(Feed *)feed error:(NSError *)error
{
    NSLog(@"*** FEED INFO - UNSUBSCRIBE ERROR");
}

- (void)popToMasterView
{
    for (id controller in [self.navigationController viewControllers])
    {
        if ([controller isKindOfClass:[MasterViewController class]]) {
            MasterViewController *master = (MasterViewController *)controller;
            [self.navigationController popToViewController:master animated:YES];
            [master updateSubscriptionList:nil];
            return;
        }
    }
}

@end
