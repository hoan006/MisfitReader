//
//  TrapezoidView.h
//  TestTransform
//
//  Created by hoan.nguyen on 9/17/12.
//  Copyright (c) 2012 hoan.nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrapezoidView : UIView

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *feedLabel;
@property (nonatomic) BOOL alignTop;

@end
