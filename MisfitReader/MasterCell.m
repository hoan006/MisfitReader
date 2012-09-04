//
//  MasterCell.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/4/12.
//
//

#import "MasterCell.h"
#import "UIApplication_AppDimensions.h"

@implementation MasterCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect textFrame = self.textLabel.frame;
    textFrame.size.width = [UIApplication currentSize].width - 90;
    self.textLabel.frame = textFrame;
    CGRect detailFrame = self.detailTextLabel.frame;
    detailFrame.origin.x = [UIApplication currentSize].width - 60;
    detailFrame.size.width = 35;
    self.detailTextLabel.frame = detailFrame;
}

@end
