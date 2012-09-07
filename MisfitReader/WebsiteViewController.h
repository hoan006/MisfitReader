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

@property (strong, nonatomic) Feed *feed;
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *stopButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goBackButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goForwardButton;

- (IBAction)pageRefresh:(id)sender;
- (IBAction)pageStop:(id)sender;
- (IBAction)pageGoBack:(id)sender;
- (IBAction)pageGoForward:(id)sender;

@end
