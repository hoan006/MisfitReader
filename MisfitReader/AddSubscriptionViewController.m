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

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(statusBarDidChangeFrame:)
     name:UIApplicationDidChangeStatusBarFrameNotification
     object:nil];

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
    NSLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    NSError *e;
    NSDictionary* jsonObjects = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
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

#define DegreesToRadians(degrees) (degrees * M_PI / 180)
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation {

    switch (orientation) {

        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation(-DegreesToRadians(90));

        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation(DegreesToRadians(90));

        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation(DegreesToRadians(180));

        case UIInterfaceOrientationPortrait:
        default:
            return CGAffineTransformMakeRotation(DegreesToRadians(0));
    }
}

BlockAlertView *alert;
- (void)alertInvalidFeed
{
    alert = [BlockAlertView alertWithTitle:@"Nothing Found"
                                                   message:@"MisfitReader couldn't find a feed at the that location."];
    [alert setCancelButtonWithTitle:@"OK" block:nil];
    [alert show];

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [alert.view setTransform:[self transformForOrientation:orientation]];
}

- (void)statusBarDidChangeFrame:(NSNotification *)notification
{
    if (alert != nil) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        [alert.view setTransform:[self transformForOrientation:orientation]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.delegate shouldAddNewFeed:self.feedURL];
}

@end