//
//  AccountViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/14/12.
//
//

#import <UIKit/UIKit.h>

@protocol AccountViewControllerDelegate
- (void)authenticateSuccess;
- (void)removeAccountDone;
@end

@interface AccountViewController : UITableViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButtonItem;
@property (strong, nonatomic) IBOutlet UITableViewCell *removeAccountCell;

@property (weak, nonatomic) id<AccountViewControllerDelegate> delegate;

- (IBAction)touchDone:(id)sender;
- (IBAction)removeAccount:(id)sender;

@end
