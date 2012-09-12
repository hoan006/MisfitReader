//
//  SummaryViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import <UIKit/UIKit.h>

@class Entry;

@interface SummaryViewController : UIViewController

@property (strong, nonatomic) Entry *entry;
@property (strong, nonatomic) IBOutlet UIView *topBar;
@property (strong, nonatomic) IBOutlet UIView *bottomBar;

@property (strong, nonatomic) IBOutlet UIWebView *contentWebView;

- (IBAction)goBack:(id)sender;
@end
