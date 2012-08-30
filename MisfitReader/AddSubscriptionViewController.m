//
//  AddSubscriptionViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import "AddSubscriptionViewController.h"

#import "constants.h"

#import "AFHTTPRequestOperation.h"

@interface AddSubscriptionViewController ()

@end

@implementation AddSubscriptionViewController

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
     selector:@selector(feedInputTextChanged:)
     name:UITextFieldTextDidChangeNotification
     object:_feedInput];
    
    // change User-Agent
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:kCURL_USER_AGENT, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)closeView:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)feedInputTextChanged:(NSNotification *)notification
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
    NSData *jsonData = [NSData dataWithContentsOfURL:googleFeedURL];
    NSError *e;
    NSDictionary* jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
    if ([[jsonObjects objectForKey:@"responseStatus"] integerValue] == 200)
    {
        self.feedURL = [[jsonObjects objectForKey:@"responseData"] objectForKey:@"url"];
        [self closeView:nil];
    } else {
        [self alertInvalidFeed];
    }
}

- (void)alertInvalidFeed
{
    NSLog(@"Invalid Feed");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.delegate shouldAddNewFeed:self.feedURL];
}

@end