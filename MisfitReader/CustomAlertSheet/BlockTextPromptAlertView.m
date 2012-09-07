//
//  BlockTextPromptAlertView.m
//  BlockAlertsDemo
//
//  Created by Barrett Jacobsen on 2/13/12.
//  Copyright (c) 2012 Barrett Jacobsen. All rights reserved.
//

#import "BlockTextPromptAlertView.h"

#define kTextBoxHeight      31
#define kTextBoxSpacing     5
#define kTextBoxHorizontalMargin 12

#define kKeyboardResizeBounce         20

@interface BlockTextPromptAlertView()
@property(nonatomic, copy) TextFieldReturnCallBack callBack;
@end

@implementation BlockTextPromptAlertView
@synthesize textField, callBack;



+ (BlockTextPromptAlertView *)promptWithTitle:(NSString *)title message:(NSString *)message defaultText:(NSString*)defaultText {
    return [self promptWithTitle:title message:message defaultText:defaultText block:nil];
}

+ (BlockTextPromptAlertView *)promptWithTitle:(NSString *)title message:(NSString *)message defaultText:(NSString*)defaultText block:(TextFieldReturnCallBack)block {
    return [[[BlockTextPromptAlertView alloc] initWithTitle:title message:message defaultText:defaultText block:block] autorelease];
}

+ (BlockTextPromptAlertView *)promptWithTitle:(NSString *)title message:(NSString *)message textField:(out UITextField**)textField {
    return [self promptWithTitle:title message:message textField:textField block:nil];
}


+ (BlockTextPromptAlertView *)promptWithTitle:(NSString *)title message:(NSString *)message textField:(out UITextField**)textField block:(TextFieldReturnCallBack) block{
    BlockTextPromptAlertView *prompt = [[[BlockTextPromptAlertView alloc] initWithTitle:title message:message defaultText:nil block:block] autorelease];
    
    *textField = prompt.textField;
    
    return prompt;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message defaultText:(NSString*)defaultText block: (TextFieldReturnCallBack) block {
    
    self = [super initWithTitle:title message:message];
    
    if (self) {
        UITextField *theTextField = [[[UITextField alloc] initWithFrame:CGRectMake(kTextBoxHorizontalMargin, _height, _view.bounds.size.width - kTextBoxHorizontalMargin * 2, kTextBoxHeight)] autorelease]; 
        
        [theTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [theTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [theTextField setBorderStyle:UITextBorderStyleRoundedRect];
        [theTextField setTextAlignment:UITextAlignmentCenter];
        [theTextField setClearButtonMode:UITextFieldViewModeAlways];
        
        if (defaultText)
            theTextField.text = defaultText;
        
        if(block){
            theTextField.delegate = self;
        }
        
        [_view addSubview:theTextField];
        
        self.textField = theTextField;
        
        _height += kTextBoxHeight + kTextBoxSpacing;
        
        self.callBack = block;
    }
    
    return self;
}

- (void)show {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [super show];

    [[NSNotificationCenter defaultCenter] addObserver:textField selector:@selector(becomeFirstResponder) name:@"AlertViewFinishedAnimations" object:nil];
    originalFrame = _view.frame;
    originalFrame.origin.y -= 20; // extra UITextField takes 40 height
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:textField];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

CGRect originalFrame;
BOOL showingAnimated = NO;

- (void)keyboardWillShow:(NSNotification *)notification {
    NSLog(@"keyboard show");
    CGRect newFrame = [self frameAboveKeyboard:notification];
    if (showingAnimated) {
        [self animateToNewFrame:newFrame];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSLog(@"keyboard hide");
    _view.frame = originalFrame;
}

- (void)statusBarDidChangeFrame:(NSNotification *)notification
{
    NSLog(@"status change frame");
    if (originalFrame.origin.x != _view.frame.origin.x) {
        _view.frame = originalFrame;
    }
    [self transformView];
    originalFrame = _view.frame;
}

- (CGRect)frameAboveKeyboard:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    __block CGRect frame = _view.frame;

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationPortrait && frame.origin.y + frame.size.height > screenHeight - keyboardSize.height)
    {
        frame.origin.y = screenHeight - keyboardSize.height - frame.size.height;
        if (frame.origin.y < 0) frame.origin.y = 0;
        showingAnimated = YES;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft && frame.origin.x + frame.size.height > screenWidth - keyboardSize.width) {
        frame.origin.x = screenWidth - keyboardSize.width - frame.size.width;
        if (frame.origin.x < 0) frame.origin.x = 0;
        showingAnimated = YES;
    } else if (orientation == UIInterfaceOrientationLandscapeRight && frame.origin.x < keyboardSize.width) {
        frame.origin.x = screenWidth;
        if (frame.origin.x + frame.size.width > screenWidth)
            frame.origin.x = screenWidth - frame.size.width;
        showingAnimated = YES;
    }
    return frame;
}

- (void)animateToNewFrame:(CGRect)frame
{
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseOut animations:^{
        _view.frame = frame;
    } completion:nil];
    _view.frame = frame;
}

- (void)setAllowableCharacters:(NSString*)accepted {
    unacceptedInput = [[NSCharacterSet characterSetWithCharactersInString:accepted] invertedSet];
    self.textField.delegate = self;
}

- (void)setMaxLength:(NSInteger)max {
    maxLength = max;
    self.textField.delegate = self;
}

-(BOOL)textFieldShouldReturn:(UITextField *)_textField{
    if(callBack){
        return callBack(self);
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSUInteger newLength = [self.textField.text length] + [string length] - range.length;
    
    if (maxLength > 0 && newLength > maxLength)
        return NO;
    
    if (!unacceptedInput)
        return YES;
    
    if ([[string componentsSeparatedByCharactersInSet:unacceptedInput] count] > 1)
        return NO;
    else 
        return YES;
}

- (void)dealloc
{
    self.callBack = nil;
    [super dealloc];
}

@end
