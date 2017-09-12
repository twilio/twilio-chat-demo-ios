//
//  LoginViewController.m
//  Twilio Chat Demo
//
//  Copyright (c) 2017 Twilio, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "ChatManager.h"
#import "DemoHelpers.h"

@interface LoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[ChatManager sharedManager] hasIdentity]) {
        self.nameTextField.text = [[ChatManager sharedManager] storedIdentity];
        [self loginTapped:nil];
    } else {
        [self.nameTextField becomeFirstResponder];
    }
}

- (IBAction)loginTapped:(id)sender {
    NSString *identity = self.nameTextField.text;
    if (identity && [identity length] > 0) {
        [self.nameTextField resignFirstResponder];
        UIView *toastView = [DemoHelpers displayMessage:@"Connecting..."
                                                 inView:self.view];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[ChatManager sharedManager] loginWithIdentity:identity completion:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (success) {
                        [[ChatManager sharedManager] presentRootViewController];
                    } else {
                        [DemoHelpers displayToastWithMessage:@"Connection Failed"
                                                      inView:self.view];
 
                        [UIView animateWithDuration:1.25f delay:0.0f
                                            options:UIViewAnimationOptionBeginFromCurrentState
                                         animations:^{
                                             toastView.alpha = 0.0f;
                                         } completion:^(BOOL finished) {
                                             toastView.hidden = YES;
                                             [toastView removeFromSuperview];
                                             
                                             [self.nameTextField becomeFirstResponder];
                                         }];
                    }
                });
            }];
        });
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self.nameTextField.text length] > 0) {
        [self loginTapped:nil];
        return YES;
    }
    
    return NO;
}

@end
