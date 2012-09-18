//
//  TrapezoidView.m
//  TestTransform
//
//  Created by hoan.nguyen on 9/17/12.
//  Copyright (c) 2012 hoan.nguyen. All rights reserved.
//

#import "TrapezoidView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TrapezoidView

float maxHeight = 100;
float maxPadding = 20;
float offsetY = 0;

- (void)drawRect:(CGRect)rect
{
    float width = rect.size.width;
    float height = rect.size.height;
    offsetY = 0;

    if (height > maxHeight)
    {
        if (!self.alignTop) {
            offsetY = height - maxHeight;
        }
        height = maxHeight;
    }

    float ratio = (maxHeight - height) / maxHeight;
    float padding = (height == maxHeight ? 0 : maxPadding - 60.0 / sqrt(maxHeight - height));

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // fill gradient color
    CGContextSaveGState(context);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat[8]){0.0f, 0.0f, 0.0f, 0.3 * ratio, 0.0f, 0.0f, 0.0f, 0.0},
     (const CGFloat[2]){0.0f,1.0f},
     2);
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(0.5 * width, offsetY),
                                CGPointMake(0.5 * width, offsetY + 0.5 * height),
                                0);
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(0.5 * width, offsetY + 0.5 * height),
                                CGPointMake(0.5 * width, offsetY + height),
                                0);
    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(context);

    // fill two side paddings
    CGContextSetFillColorWithColor(context, [UIColor darkGrayColor].CGColor);
    CGContextMoveToPoint(context, 0.0f, offsetY);
    CGContextAddLineToPoint(context, padding, offsetY + 0.5 * height);
    CGContextAddLineToPoint(context, 0.0f, offsetY + height);
    CGContextAddLineToPoint(context, 0.0f, offsetY);
    CGContextMoveToPoint(context, width, offsetY);
    CGContextAddLineToPoint(context, width - padding, offsetY + 0.5 * height);
    CGContextAddLineToPoint(context, width, offsetY + height);
    CGContextAddLineToPoint(context, width, offsetY);
    CGContextFillPath(context);

    // transform 2 labels
    self.titleLabel.frame = CGRectMake(20, offsetY + 0.3 * height - padding * ratio, width - 40, 0.2 * height + padding * ratio * 2);
    CATransform3D t = self.titleLabel.layer.transform;
    t.m24 = 0.005 * ratio; t.m22 = 1 - ratio;
    self.titleLabel.layer.transform = t;

    self.feedLabel.frame = CGRectMake(20, offsetY + 0.5 * height - padding * ratio, width - 40, 0.15 * height + padding * ratio * 2);
    CATransform3D u = self.titleLabel.layer.transform;
    u.m24 = -0.005 * ratio; u.m22 = 1 - ratio;
    self.feedLabel.layer.transform = u;
}

@end
