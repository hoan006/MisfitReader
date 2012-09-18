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
#import "TrapezoidView.h"
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
BOOL interceptLinks;
TrapezoidView *trapezoid;
BOOL inTransition;

- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    context = [appDelegate managedObjectContext];

    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackToSubscriptions.png"] style:UIBarButtonItemStyleBordered target:nil action:nil];
    backButtonItem.tintColor = [UIColor scrollViewTexturedBackgroundColor];
    self.navigationItem.backBarButtonItem = backButtonItem;
    self.contentWebView.scrollView.delegate = self;

    trapezoid = [[[NSBundle mainBundle] loadNibNamed:@"TrapezoidView" owner:self options:nil] objectAtIndex:0];
    trapezoid.hidden = YES;
    [self.view addSubview:trapezoid];
}

- (void)viewDidAppear:(BOOL)animated {
    [self resizeToolbars];
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
    [UIView animateWithDuration:duration animations:^{
        [self resizeToolbars];
    }];
}

- (void)resizeToolbars
{
    CGRect topFrame = self.topBar.frame;
    CGRect bottomFrame = self.bottomBar.frame;
    topFrame.size = bottomFrame.size = self.navigationController.navigationBar.frame.size;
    bottomFrame.origin.y = [UIApplication currentSize].height - bottomFrame.size.height;
    self.topBar.frame = topFrame;
    self.bottomBar.frame = bottomFrame;
    self.contentWebView.scrollView.contentInset = UIEdgeInsetsMake(topFrame.size.height, 0, bottomFrame.size.height, 0);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self resizeToolbars];
    [self displayReadEntryAndConfigBottomButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    inTransition = NO;
    self.contentWebView.scrollView.bounces = YES;
    
    // update hidden button height
    NSString * jsResult = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('splitter').offsetTop"];
    CGRect frame = self.hiddenButton.frame;
    frame.size.height = [jsResult intValue];
    self.hiddenButton.frame = frame;
    [self updateHiddenButtonPosition];
    self.hiddenButton.hidden = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (interceptLinks) {
        browsingURL = request.URL.absoluteString;
        [self performSegueWithIdentifier:@"showEntry" sender:nil];
        return NO;
    }
    else {
        self.hiddenButton.hidden = YES;
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
        [self updateHiddenButtonPosition];
        self.hiddenButton.hidden = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateHiddenButtonPosition];
    self.hiddenButton.hidden = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // reveal next entry?
    if (scrollView.contentOffset.y > 0)
    {
        float height = scrollView.contentOffset.y + [UIApplication currentSize].height - scrollView.contentSize.height - scrollView.contentInset.bottom;
        if (height > 0 && !inTransition && nextEntry != nil)
        {
            CGRect frame = trapezoid.frame;
            frame.size.height = height;
            frame.origin.y = self.bottomBar.frame.origin.y - height;
            trapezoid.frame = frame;
            trapezoid.titleLabel.text = nextEntry.title;
            trapezoid.feedLabel.text = nextEntry.feed.title;
            trapezoid.alignTop = YES;
            trapezoid.hidden = NO;
        } else {
            trapezoid.hidden = YES;
        }
    }
    // reveal previous entry?
    else {
        float height = scrollView.contentOffset.y + scrollView.contentInset.top;
        if (height < 0 && !inTransition && previousEntry != nil)
        {
            CGRect frame = trapezoid.frame;
            frame.size.height = -height;
            frame.origin.y = self.topBar.frame.size.height;
            trapezoid.frame = frame;
            trapezoid.titleLabel.text = previousEntry.title;
            trapezoid.feedLabel.text = previousEntry.feed.title;
            trapezoid.alignTop = NO;
            trapezoid.hidden = NO;
        } else {
            trapezoid.hidden = YES;
        }

    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // go to next entry?
    if (scrollView.contentOffset.y > 0)
    {
        float height = scrollView.contentOffset.y + [UIApplication currentSize].height - scrollView.contentSize.height - scrollView.contentInset.bottom;
        if (height > 80 && nextEntry != nil)
        {
            trapezoid.hidden = YES;
            inTransition = YES;
            self.contentWebView.scrollView.bounces = NO;
            [self touchUpInsideNextButton:nil];
        }
    }
    // go to previous entry?
    else {
        float height = scrollView.contentOffset.y + scrollView.contentInset.top;
        if (height < -80 && previousEntry != nil)
        {
            trapezoid.hidden = YES;
            inTransition = YES;
            self.contentWebView.scrollView.bounces = NO;
            [self touchUpInsidePreviousButton:nil];
        }
    }
}

- (void)updateHiddenButtonPosition
{
    UIScrollView *scrollView = self.contentWebView.scrollView;
    CGRect frame = self.hiddenButton.frame;
    frame.origin.y = scrollView != nil ? -scrollView.contentOffset.y : 0;
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
            "</style> \n"
            "</head> \n"
            "<body> \n"
            "<div id='header'> \n"
            "  <div id='sub'>%@</div> \n"
            "  <div id='title'>%@</div> \n"
            "  <div id='sub'>%@</div> \n"
            "</div> \n"
            "<hr id='splitter'/> \n"
            "<div id='content'>%@</div> \n"
            "</html>",
            kWebViewFontFamily, fontSize, fontSize - 3, imgMaxWidth,
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
    transition.subtype = kCATransitionFromTop;
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
    transition.subtype = kCATransitionFromBottom;
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
