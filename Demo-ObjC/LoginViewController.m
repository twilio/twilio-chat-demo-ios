//
//  LoginViewController.m
//  Twilio Chat Demo
//
//  Copyright (c) 2011-2016 Twilio. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "ChatManager.h"

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
        [[ChatManager sharedManager] loginWithIdentity:self.nameTextField.text];
        [[ChatManager sharedManager] presentRootViewController];
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
