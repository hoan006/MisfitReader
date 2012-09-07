//
//  AddSubscriptionViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import "constants.h"
#import "AddSubscriptionViewController.h"
#import "AFHTTPRequestOperation.h"
#import "BlockAlertView.h"
#import "BlockBackground.h"

@interface AddSubscriptionViewController ()

@end

@implementation AddSubscriptionViewController
@synthesize navigationBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(feedInputDidChangeText:)
     name:UITextFieldTextDidChangeNotification
     object:_feedInput];

    // change User-Agent
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:kCURL_USER_AGENT, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

- (void)viewDidUnload
{
    [self setNavigationBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation  duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:orientation duration:duration];
    CGRect frame = self.navigationBar.frame;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        frame.size.height = 44;
    } else {
        frame.size.height = 32;
    }
    self.navigationBar.frame = frame;
}

- (IBAction)closeView:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)feedInputDidChangeText:(NSNotification *)notification
{
    if ([_feedInput.text length] > 0) {
        _addButton.hidden = FALSE;
    } else {
        _addButton.hidden = TRUE;
    }
}

- (IBAction)feedInputDidEnd:(id)sender
{
    [_feedInput resignFirstResponder];
    if ([_feedInput.text length] > 0) {
        [self findFeedURL];
    }
}

- (IBAction)addTapped:(id)sender
{
    [_feedInput resignFirstResponder];
    [self findFeedURL];
}

UIActivityIndicatorView *activityIndicator;
- (void)findFeedURL
{
    NSURL *url = [NSURL URLWithString:_feedInput.text];
    if ([url scheme] == nil) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:_feedInput.text]];
    }
    if ([url host] == nil) {
        [self alertInvalidFeed];
        return;
    }
    if ([[url host] rangeOfString:@"."].location == NSNotFound)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@.com", url.absoluteString]];
    }
    NSURL *googleFeedURL = [NSURL URLWithString:[kGOOGLE_FEED_API_SERVICE stringByAppendingString:[url absoluteString]]];

    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationBar.topItem setRightBarButtonItem:barButton];
    [activityIndicator startAnimating];
    [self performSelector:@selector(extractFeedFromURL:) withObject:googleFeedURL afterDelay:0.01];
}

- (void)extractFeedFromURL:(NSURL *)url
{
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    NSError *e;
    NSDictionary* jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
    [activityIndicator stopAnimating];
    
    if ([[jsonObjects objectForKey:@"responseStatus"] integerValue] == 200)
    {
        NSString *newFeedURL = [[jsonObjects objectForKey:@"responseData"] objectForKey:@"url"];
        if ([newFeedURL length] > 0)
        {
            self.feedURL = newFeedURL;
            [self closeView:nil];
            return;
        }
    }
    [self alertInvalidFeed];
}

- (void)alertInvalidFeed
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Nothing Found"
                                                   message:@"MisfitReader couldn't find a feed at the that location."];
    [alert setCancelButtonWithTitle:@"OK" block:nil];
    [alert show];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.feedURL != nil) {
        [self.delegate shouldAddNewFeed:self.feedURL];
    }
}

@end