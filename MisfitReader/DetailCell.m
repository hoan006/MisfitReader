//
//  DetailCell.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/4/12.
//
//

#import "DetailCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation DetailCell

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

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.categoryView.layer.cornerRadius = 2;
    self.categoryView.clipsToBounds = YES;
}

@end
