//
//  PopupView.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/13/12.
//
//

#import <UIKit/UIKit.h>

@interface PopupView : UIView

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text;
- (void)popupInSuperview:(UIView *)superview;

@end
