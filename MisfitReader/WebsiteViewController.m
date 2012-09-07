//
//  WebsiteViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/6/12.
//
//

#import "WebsiteViewController.h"
#import "Feed.h"

@interface WebsiteViewController ()

@end

@implementation WebsiteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

UIActivityIndicatorView *activityIndicator;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.title = self.feed.title;
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationItem setRightBarButtonItem:barButton];

    NSURL *url = [NSURL URLWithString:self.feed.html_url];
    [self.webview loadRequest:[NSURLRequest requestWithURL:url]];
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

- (IBAction)pageRefresh:(id)sender
{
    [self.webview reload];
}

- (IBAction)pageStop:(id)sender
{
    [self.webview stopLoading];
    [self webViewDidFinishLoad:self.webview];
}

- (void)toggleButtons:(UIBarButtonItem *)buttonToRemove and:(UIBarButtonItem *)buttonToInsert
{
    NSMutableArray *toolbarButtons = [self.toolbarItems mutableCopy];
    [toolbarButtons removeObject:buttonToRemove];
    if (![toolbarButtons containsObject:buttonToInsert]) {
        [toolbarButtons insertObject:buttonToInsert atIndex:0];
    }
    [self setToolbarItems:toolbarButtons animated:NO];
}

- (IBAction)pageGoBack:(id)sender
{
    [self.webview goBack];
}

- (IBAction)pageGoForward:(id)sender
{
    [self.webview goForward];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [activityIndicator startAnimating];
    [self toggleButtons:self.refreshButton and:self.stopButton];
    self.goBackButton.enabled = NO;
    self.goForwardButton.enabled = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [activityIndicator stopAnimating];
    [self toggleButtons:self.stopButton and:self.refreshButton];
    if (webView.canGoBack) self.goBackButton.enabled = YES;
    if (webView.canGoForward) self.goForwardButton.enabled = YES;
}

@end
