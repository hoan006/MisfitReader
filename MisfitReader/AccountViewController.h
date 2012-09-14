//
//  AccountViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/14/12.
//
//

#import <UIKit/UIKit.h>

@protocol AccountViewControllerDelegate

@optional
- (void)authenticateSuccess;

@end

@interface AccountViewController : UITableViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButtonItem;

@property (weak, nonatomic) id<AccountViewControllerDelegate> delegate;

- (IBAction)touchCancel:(id)sender;
- (IBAction)touchDone:(id)sender;

@end
