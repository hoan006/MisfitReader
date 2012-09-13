//
//  PopupView.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/13/12.
//
//

#import "PopupView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage_NegativeImage.h"

@implementation PopupView

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.alpha = 0.95;
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height - 30, frame.size.width, 30)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:11];
        label.text = text;
        [self addSubview:label];

        CGRect imageRect = CGRectMake((frame.size.width - image.size.width) / 2,
                                      (frame.size.height - image.size.height) / 2 - 5,
                                      image.size.width, image.size.height);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageRect];
        [imageView setImage:[image negativeImage]];
        [self addSubview:imageView];
    }
    return self;
}

- (void)popupInSuperview:(UIView *)superview
{
    [superview addSubview:self];
    self.alpha = 0;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         self.alpha = 1;
                     }completion:^(BOOL finished){
                         [UIView animateWithDuration:0.1
                                               delay:0.5
                                             options: UIViewAnimationCurveEaseOut
                                          animations:^{
                                              self.alpha = 0;
                                          }completion:^(BOOL finished){
                                              [self removeFromSuperview];
                                          }
                          ];
                     }];
}

- (void)drawRect:(CGRect)rect
{
    // Fill the background color
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [[UIColor darkGrayColor] setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat[8]){0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.8f},
     (const CGFloat[2]){0.0f,1.0f},
     2);
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(self.bounds)),
                                CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)),
                                0);

    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(context);
}

@end
