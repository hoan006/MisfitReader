//
//  AccountViewController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/14/12.
//
//

#import "AccountViewController.h"
#import "RssFeeder.h"
#import "BlockAlertView.h"
#import "AppDelegate.h"
#import "AccountSetting.h"

@interface AccountViewController ()

@end

@implementation AccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// hide the default toolbar
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.removeAccountCell.hidden = [RssFeeder instance].email == nil;
    if ([RssFeeder instance].email == nil)
    {
        [self.navigationItem setHidesBackButton:YES animated:NO];
    }
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    } else {
        [self touchDone:nil];
    }
    return YES;
}

UIActivityIndicatorView *activityIndicator;
- (IBAction)touchDone:(id)sender
{
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationItem setRightBarButtonItem:barButton];
    [activityIndicator startAnimating];
    [self performSelector:@selector(authenticateEmail) withObject:nil afterDelay:0.01];
}

- (void)authenticateEmail
{
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    [[RssFeeder instance] authenticateEmail:username password:password
                                    success:^(NSString *authValue){
                                        [activityIndicator stopAnimating];
                                        [self saveEmail:username password:password];
                                        [self.delegate authenticateSuccess];
                                        [self.navigationController popViewControllerAnimated:YES];
                                    } failure:^{
                                        [activityIndicator stopAnimating];
                                        BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Login Failed"
                                                                                       message:@"The email or password you entered is not correct"];
                                        [alert setCancelButtonWithTitle:@"OK" block:nil];
                                        [alert show];
                                        [self.navigationItem setRightBarButtonItem:self.doneButtonItem];
                                    }];
}

- (void)saveEmail:(NSString *)email password:(NSString *)password
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AccountSetting" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSError *e;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&e];
    if (result.count == 0)
    {
        AccountSetting *account = [NSEntityDescription insertNewObjectForEntityForName:@"AccountSetting"
                                                                inManagedObjectContext:context];
        account.email = email;
        account.password = password;
    } else {
        AccountSetting *account = [result objectAtIndex:0];
        account.email = email;
        account.password = password;
    }
    [context save:nil];
}

- (IBAction)removeAccount:(id)sender
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Warning"
                                                   message:@"Remove account will delete all of MisfitReader's data. Are you sure to proceed?"];
    [alert setDestructiveButtonWithTitle:@"Proceed" block:^{
        [self deleteAllData];
        self.usernameField.text = self.passwordField.text = @"";
        self.removeAccountCell.hidden = YES;
    }];
    [alert setCancelButtonWithTitle:@"Nevermind" block:nil];
    [alert show];
}

- (void)deleteAllData
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    [self deleteAllObjects:@"Feed" inContext:context];
    [self deleteAllObjects:@"AccountSetting" inContext:context];
    [self.delegate removeAccountDone];
}

- (void)deleteAllObjects:(NSString *) entityDescription inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *items = [context executeFetchRequest:fetchRequest error:&error];


    for (NSManagedObject *managedObject in items) {
        [context deleteObject:managedObject];
    }
    if (![context save:&error]) {
        NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
}

@end
