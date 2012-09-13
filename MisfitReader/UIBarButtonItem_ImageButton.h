//
//  UIBarButtonItem_ImageButton.h
//  MisfitReader
//
//  Created by hoan.nguyen on 9/5/12.
//
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (ImageButton)

+ (UIBarButtonItem*)barItemWithImage:(UIImage*)image backgroundImage:(UIImage *)backgroundImage target:(id)target action:(SEL)action;

@end

@implementation UIBarButtonItem (ImageButton)

+ (UIBarButtonItem*)barItemWithImage:(UIImage*)image backgroundImage:(UIImage *)backgroundImage target:(id)target action:(SEL)action{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(2,2,16,16)];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    UIView *buttonWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    if (backgroundImage != nil) {
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        [buttonWrapper addSubview:backgroundView];
    }
    [buttonWrapper addSubview:button];

    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonWrapper];
    return buttonItem;
}
@end
