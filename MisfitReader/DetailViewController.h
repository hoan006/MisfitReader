//
//  DetailViewController.h
//  MisfitReader
//
//  Created by hoan.nguyen on 8/29/12.
//
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
