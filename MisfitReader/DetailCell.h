//
//  DetailCell.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/4/12.
//
//

#import <UIKit/UIKit.h>

@interface DetailCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *feedIcon;
@property (weak, nonatomic) IBOutlet UILabel *feedTitle;
@property (weak, nonatomic) IBOutlet UILabel *entryTime;
@property (weak, nonatomic) IBOutlet UILabel *entryTitle;
@property (weak, nonatomic) IBOutlet UILabel *entrySummary;

@property (strong, nonatomic) IBOutlet UIView *categoryView;
@property (strong, nonatomic) IBOutlet UIButton *unreadButton;
@property (strong, nonatomic) IBOutlet UIButton *starredButton;

@end
