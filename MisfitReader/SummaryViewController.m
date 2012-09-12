//
//  SummaryViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import "SummaryViewController.h"
#import "UIApplication_AppDimensions.h"
#import "Feed.h"
#import "Entry.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    // additional positioning when being pushed from landscape mode
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        CGRect topFrame = self.topBar.frame;
        CGRect bottomFrame = self.bottomBar.frame;
        topFrame.size = bottomFrame.size = self.navigationController.navigationBar.frame.size;
        bottomFrame.origin.y = [UIApplication currentSize].width - bottomFrame.size.height;
        self.topBar.frame = topFrame;
        self.bottomBar.frame = bottomFrame;
    }

    // set html content
    self.contentWebView.scrollView.bounces = NO;
    self.contentWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, self.bottomBar.frame.size.height, 0);
    [self.contentWebView loadHTMLString:[self contentHTML] baseURL:nil];

    // add gesture recogizer for title
}

- (void)popToPreviousController
{
    [self.navigationController popViewControllerAnimated:YES];
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

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

static const NSString * kWebViewFontFamily = @"helvetica";
- (NSString *)contentHTML
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"hh:mm";
    NSString *displayDate = [dateFormatter stringFromDate:self.entry.updated_at];

    int imgMaxWidth = UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 464 : 304;
    int fontSize = 17;
    
    NSString *result = [NSString stringWithFormat:@"<html> \n"
            "<head> \n"
            "<style type=\"text/css\"> \n"
            "body {font-family: \"%@\"; font-size: %dpx; background-color: #F4F2E6} \n"
            "#header {width: 100%%; text-align: center;} \n"
            "#title {font-weight: bold;} \n"
            "#sub {font-size: %dpx;} \n"
            "img {max-width: %dpx; height: auto} \n"
            "</style> \n"
            "</head> \n"
            "<body> \n"
            "<div id='toolbar-space' style='min-height:%dpx; clear: both;'></div> \n"
            "<div id='header'> \n"
            "<div id='sub'>%@</div> \n"
            "<div id='title'>%@</div> \n"
            "<div id='sub'>%@</div> \n"
            "</div> \n"
            "<hr/> \n"
            "<div id='content'>%@</div> \n"
            "</html>",
            kWebViewFontFamily, fontSize, fontSize - 3, imgMaxWidth, (int)self.topBar.frame.size.height,
            displayDate, self.entry.title, self.entry.feed.title, self.entry.summary];
    return result;
}
@end
