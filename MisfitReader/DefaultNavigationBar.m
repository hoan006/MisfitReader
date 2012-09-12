//
//  MisfitNavigationBar.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/10/12.
//
//

#import "DefaultNavigationBar.h"

@implementation DefaultNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [[UIColor scrollViewTexturedBackgroundColor] setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat[8]){0.0f, 0.0f, 0.0f, 0.4f, 0.0f, 0.0f, 0.0f, 0.8f},
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
