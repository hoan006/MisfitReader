//
//  DefaultNavigationController.m
//  MisfitReader
//
//  Created by hoan.nguyen on 9/10/12.
//
//

#import "DefaultNavigationController.h"
#import <QuartzCore/QuartzCore.h>

@interface DefaultNavigationController ()

@end

@implementation DefaultNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self roundNavigationBarCorners];
//    [self roundToolbarCorners];
}

//- (void)roundNavigationBarCorners
//{
//    CALayer *capa = self.navigationBar.layer;
//
//    CGRect bounds = capa.bounds;
//    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
//                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
//                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
//
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = bounds;
//    maskLayer.path = maskPath.CGPath;
//
//    [capa addSublayer:maskLayer];
//    capa.mask = maskLayer;
//}
//
//- (void)roundToolbarCorners
//{
//    CALayer *capa = self.toolbar.layer;
//    CGRect bounds = capa.bounds;
//    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
//                                                   byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
//                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
//
//    CAShapeLayer *maskLayer = [CAShapeLayer layer];
//    maskLayer.frame = bounds;
//    maskLayer.path = maskPath.CGPath;
//
//    [capa addSublayer:maskLayer];
//    capa.mask = maskLayer;
//}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
