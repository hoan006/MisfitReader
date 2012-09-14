//
//  SummaryViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import "SummaryViewController.h"
#import "WebsiteViewController.h"
#import "UIApplication_AppDimensions.h"
#import "NSDate_PrettyPrint.h"
#import "Feed.h"
#import "Entry.h"
#import "constants.h"
#import "AppDelegate.h"
#import "PopupView.h"
#import <QuartzCore/QuartzCore.h>

@interface SummaryViewController ()

@end

@implementation SummaryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// hide the default navigation bar and toolbar
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

NSManagedObjectContext *context;
bool interceptLinks;
- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    context = [appDelegate managedObjectContext];

    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackToSubscriptions.png"] style:UIBarButtonItemStyleBordered target:nil action:nil];
    backButtonItem.tintColor = [UIColor scrollViewTexturedBackgroundColor];
    self.navigationItem.backBarButtonItem = backButtonItem;

    // additional positioning when being pushed from landscape mode
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        CGRect topFrame = self.topBar.frame;
        CGRect bottomFrame = self.bottomBar.frame;
        topFrame.size = bottomFrame.size = self.navigationController.navigationBar.frame.size;
        bottomFrame.origin.y = [UIApplication currentSize].width - bottomFrame.size.height;
        self.topBar.frame = topFrame;
        self.bottomBar.frame = bottomFrame;
    }

    // configure webview
    self.contentWebView.scrollView.bounces = NO;
    self.contentWebView.scrollView.delegate = self;

    // update entry feed to 'read' & configure buttom buttons
    [self displayReadEntryAndConfigBottomButtons];
}

- (void)popToPreviousController
{
    [self.navigationController popViewControllerAnimated:YES];
}

Entry *nextEntry, *previousEntry;
- (void)configureBottomBarButtons
{
    nextEntry = [self.delegate nextEntry];
    previousEntry = [self.delegate previousEntry];
    self.nextButton.enabled = (nextEntry != nil);
    self.previousButton.enabled = (previousEntry != nil);

    [self.readButton setImage:[UIImage imageNamed:(self.entry.is_kept_unread ? @"ButtonUnread.png" : @"ButtonRead.png")] forState:UIControlStateNormal];
    [self.starButton setImage:[UIImage imageNamed:(self.entry.is_starred ? @"ButtonStarred.png" : @"ButtonUnstarred.png")] forState:UIControlStateNormal];
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

// handle resizing "custom" toolbars
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect topFrame = self.topBar.frame;
    CGRect bottomFrame = self.bottomBar.frame;

    topFrame.size = bottomFrame.size = self.navigationController.navigationBar.frame.size;
    bottomFrame.origin.y = [UIApplication currentSize].height - bottomFrame.size.height;

    [UIView animateWithDuration:duration animations:^{
        self.topBar.frame = topFrame;
        self.bottomBar.frame = bottomFrame;
    }];

    // update web view
    self.contentWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, self.bottomBar.frame.size.height, 0);
    interceptLinks = NO;
    [self.contentWebView loadHTMLString:[self contentHTML] baseURL:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    BOOL show = (toInterfaceOrientation == UIInterfaceOrientationPortrait ||
                 toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    [[UIApplication sharedApplication] setStatusBarHidden:!show withAnimation:UIStatusBarAnimationNone];
}

- (void)viewDidAppear:(BOOL)animated {
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated];
    }
    else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString * jsResult = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('splitter').offsetTop"];
    CGRect frame = self.hiddenButton.frame;
    frame.size.height = [jsResult intValue] - self.topBar.frame.size.height;
    self.hiddenButton.frame = frame;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (interceptLinks) {
        browsingURL = request.URL.absoluteString;
        [self performSegueWithIdentifier:@"showEntry" sender:nil];
        return NO;
    }
    //No need to intercept the initial request to fill the WebView
    else {
        interceptLinks = TRUE;
        return YES;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.hiddenButton.hidden = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self updateHiddenButtonPosition:scrollView];
        self.hiddenButton.hidden = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateHiddenButtonPosition:scrollView];
    self.hiddenButton.hidden = NO;
}

- (void)updateHiddenButtonPosition:(UIScrollView *)scrollView
{
    CGRect frame = self.hiddenButton.frame;
    frame.origin.y = self.topBar.frame.size.height - scrollView.contentOffset.y;
    self.hiddenButton.frame = frame;
}

- (IBAction)goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)touchDownHiddenButton:(id)sender
{
    [self.hiddenButton setBackgroundColor:UIColorFromRGBWithAlpha(0x000000, 0.1)];
}

- (IBAction)touchUpInsideHiddenButton:(id)sender
{
    [self.hiddenButton setBackgroundColor:UIColorFromRGBWithAlpha(0x000000, 0.0)];
    browsingURL = self.entry.link;
    [self performSegueWithIdentifier:@"showEntry" sender:nil];
}

- (IBAction)touchUpOutsideHiddenButton:(id)sender
{
    [self.hiddenButton setBackgroundColor:UIColorFromRGBWithAlpha(0x000000, 0.0)];
}

NSString *browsingURL = nil;
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showEntry"]) {
        WebsiteViewController *website = [segue destinationViewController];
        website.htmlUrl = browsingURL;
    }
}

static const NSString * kWebViewFontFamily = @"helvetica";
- (NSString *)contentHTML
{
    NSString *displayDate = [[NSDate dateWithTimeIntervalSince1970:self.entry.updated_at] prettyFormatWithTime];
    int imgMaxWidth = [UIApplication currentSize].width - 16;
    int fontSize = 17;
    
    NSString *result = [NSString stringWithFormat:@"<html> \n"
            "<head> \n"
            "<style type=\"text/css\"> \n"
            "body {font-family: \"%@\"; font-size: %dpx; background-color: #F4F2E6} \n"
            "#header {width: 100%%; text-align: center;} \n"
            "#title {font-weight: bold;} \n"
            "#sub {font-size: %dpx; color: #A5A5A5} \n"
            "img {max-width: %dpx; height: auto;} \n"
            "#padding-space {min-height:%dpx; clear:both;} \n"
            "</style> \n"
            "</head> \n"
            "<body> \n"
            "<div id='padding-space'></div> \n"
            "<div id='header'> \n"
            "  <div id='sub'>%@</div> \n"
            "  <div id='title'>%@</div> \n"
            "  <div id='sub'>%@</div> \n"
            "</div> \n"
            "<hr id='splitter'/> \n"
            "<div id='content'>%@</div> \n"
            "<div id='padding-space'></div> \n"
            "</html>",
            kWebViewFontFamily, fontSize, fontSize - 3, imgMaxWidth, (int)self.topBar.frame.size.height,
            displayDate, self.entry.title, self.entry.feed.title, self.entry.summary];
    return result;
}

- (void)displayReadEntryAndConfigBottomButtons
{
    if (self.entry.is_kept_unread || !self.entry.is_read) {
        self.entry.is_kept_unread = NO;
        self.entry.is_read = YES;
        [context save:nil];
        [[RssFeeder instance] readEntry:3 entry:self.entry status:YES delegate:self];
    }

    interceptLinks = NO;
    [self.contentWebView loadHTMLString:[self contentHTML] baseURL:nil];

    [self configureBottomBarButtons];
}

- (IBAction)touchUpInsideReadButton:(id)sender
{
    self.entry.is_kept_unread = !self.entry.is_kept_unread;
    [context save:nil];
    NSString *newState = self.entry.is_kept_unread ? @"Unread" : @"Read";
    UIImage *stateImage = [UIImage imageNamed:(self.entry.is_kept_unread ? @"ButtonUnread.png" : @"ButtonRead.png")];
    [self.readButton setImage:stateImage forState:UIControlStateNormal];
    PopupView *popup = [[PopupView alloc] initWithFrame:CGRectMake([UIApplication currentSize].width / 2 - 36, [UIApplication currentSize].height / 2 - 36, 72, 72) image:stateImage text:newState];
    [popup popupInSuperview:self.view];

    // update to server
    [[RssFeeder instance] readEntry:3 entry:self.entry status:!self.entry.is_kept_unread delegate:self];
}

- (IBAction)touchUpInsideStarButton:(id)sender
{
    self.entry.is_starred = !self.entry.is_starred;
    [context save:nil];
    NSString *newState = self.entry.is_starred ? @"Starred" : @"Unstarred";
    UIImage *stateImage = [UIImage imageNamed:(self.entry.is_starred ? @"ButtonStarred.png" : @"ButtonUnstarred.png")];
    [self.starButton setImage:[UIImage imageNamed:(self.entry.is_starred ? @"ButtonStarred.png" : @"ButtonUnstarred.png")] forState:UIControlStateNormal];
    PopupView *popup = [[PopupView alloc] initWithFrame:CGRectMake([UIApplication currentSize].width / 2 - 36, [UIApplication currentSize].height / 2 - 36, 72, 72) image:stateImage text:newState];
    [popup popupInSuperview:self.view];

    // update to server
    [[RssFeeder instance] starEntry:3 entry:self.entry status:self.entry.is_starred delegate:self];
}

- (IBAction)touchUpInsideNextButton:(id)sender
{
    self.entry = [self.delegate nextEntry];
    [self.delegate shiftIndexPathBackOrForward:YES];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromBottom;
    [self.contentWebView.layer addAnimation:transition forKey:nil];

    [self displayReadEntryAndConfigBottomButtons];
}

- (IBAction)touchUpInsidePreviousButton:(id)sender
{
    self.entry = [self.delegate previousEntry];
    [self.delegate shiftIndexPathBackOrForward:NO];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromTop;
    [self.contentWebView.layer addAnimation:transition forKey:nil];

    [self displayReadEntryAndConfigBottomButtons];
}

- (void)readEntrySuccess:(Entry *)entry
{
    NSLog(@"*** Summary View - (tag) Read/Unread entry success");
}

- (void)readEntryFailure:(Entry *)entry error:(NSError *)error
{
    NSLog(@"*** Summary View - (tag) Read/Unread entry failure");
}

- (void)starEntrySuccess:(Entry *)entry
{
    NSLog(@"*** Summary View - (tag) Star/Unstar entry success");
}

- (void)starEntryFailure:(Entry *)entry error:(NSError *)error
{
    NSLog(@"*** Summary View - (tag) Star/Unstar entry failure");
}

@end
