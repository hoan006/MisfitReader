//
//  AddSubscriptionViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>

@protocol AddSubscriptionDelegate <NSObject>

@optional
- (void)shouldAddNewFeed:(NSString *)feedURL;

@end

@interface AddSubscriptionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) UITextField IBOutlet *feedInput;
@property (weak, nonatomic) UIButton IBOutlet *addButton;
@property (strong, nonatomic) NSString *feedURL;

@property (nonatomic, weak) id<AddSubscriptionDelegate> delegate;

- (IBAction)closeView:(id)sender;
- (IBAction)feedInputDidEnd:(id)sender;
- (IBAction)addTapped:(id)sender;
@end
