//
//  SummaryViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import <UIKit/UIKit.h>
#import "RssFeeder.h"
@class Entry;
#import "PopupView.h"

@protocol SummaryViewControllerDelegate
@optional
- (Entry *)nextEntry;
- (Entry *)previousEntry;
- (void)shiftIndexPathBackOrForward:(BOOL)forward;
@end

@interface SummaryViewController : UIViewController<UIScrollViewDelegate, UIWebViewDelegate, RssFeederDelegate>

@property (strong, nonatomic) Entry *entry;
@property (weak, nonatomic) id<SummaryViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIView *topBar;
@property (strong, nonatomic) IBOutlet UIView *bottomBar;
@property (strong, nonatomic) IBOutlet UIView *hiddenButton;

@property (strong, nonatomic) IBOutlet UIWebView *contentWebView;
@property (strong, nonatomic) IBOutlet PopupView *popupView;

@property (strong, nonatomic) IBOutlet UIButton *readButton;
@property (strong, nonatomic) IBOutlet UIButton *starButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *previousButton;

- (IBAction)goBack:(id)sender;
- (IBAction)touchDownHiddenButton:(id)sender;
- (IBAction)touchUpInsideHiddenButton:(id)sender;
- (IBAction)touchUpOutsideHiddenButton:(id)sender;

- (IBAction)touchUpInsideReadButton:(id)sender;
- (IBAction)touchUpInsideStarButton:(id)sender;
- (IBAction)touchUpInsideNextButton:(id)sender;
- (IBAction)touchUpInsidePreviousButton:(id)sender;

@end
