//
//  LoginViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "IPMessagingManager.h"

@interface LoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.nameTextField becomeFirstResponder];
}

- (IBAction)loginTapped:(id)sender {
    if (self.nameTextField.text && [self.nameTextField.text length] > 0) {
        [[IPMessagingManager sharedManager] loginWithIdentity:self.nameTextField.text];
        [[IPMessagingManager sharedManager] presentRootViewController];
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
