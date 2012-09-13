//
//  WebsiteViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/6/12.
//
//

#import <UIKit/UIKit.h>
@class Feed;

@interface WebsiteViewController : UIViewController<UIWebViewDelegate>

@property (strong, nonatomic) NSString *htmlUrl;
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *goBackButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *goForwardButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *actionButton;

- (IBAction)pageRefresh:(id)sender;
- (IBAction)pageStop:(id)sender;
- (IBAction)pageGoBack:(id)sender;
- (IBAction)pageGoForward:(id)sender;

@end
