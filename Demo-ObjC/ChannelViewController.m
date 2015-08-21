//
//  ChannelViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ChannelViewController.h"
#import "MessageTableViewCell.h"

@interface ChannelViewController () <UITableViewDataSource, UITableViewDelegate, TMChannelDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableOrderedSet *messages;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAdjustmentConstraint;

@property (weak, nonatomic) IBOutlet UIView *toastView;
@property (weak, nonatomic) IBOutlet UILabel *toastViewLabel;
@end

@implementation ChannelViewController

#pragma mark - View lifecycle methods

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    self.messages = [[NSMutableOrderedSet alloc] init];
}

- (void)displayToastWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.toastViewLabel.text = message;
        self.toastView.alpha = 0.0f;
        self.toastView.hidden = NO;
        
        [UIView animateWithDuration:1.25f delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.toastView.alpha = 1.0f;
                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:1.25f delay:1.0f
                                                 options:UIViewAnimationOptionBeginFromCurrentState
                                              animations:^{
                                                  self.toastView.alpha = 0.0f;
                                              } completion:^(BOOL finished) {
                                                  self.toastView.hidden = YES;
                                              }];
                         }];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88.0f;

    self.toastView.layer.cornerRadius = 5.0f;
    self.toastView.alpha = 0.0f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.channel) {
        self.channel.delegate = self;
        [self loadMessages];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:self.view.window];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:self.view.window];
        
        [self.messageInput becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.channel) {
        self.channel.delegate = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)setChannel:(TMChannel *)channel {
    _channel = channel;
    self.channel.delegate = self;

    [self loadMessages];
}

- (IBAction)performAction:(id)sender {
    UIAlertController *actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Change Friendly Name"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self changeFriendlyName];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Change Topic"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self changeTopic];
                                                   }]];
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"List Members"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       TMMembers *members = self.channel.members;
                                                       // TODO: display in UI
                                                       NSLog(@"@@@@@ members (%ld): %@", (long)members.allObjects.count, members.allObjects);
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Invite Member"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self inviteMember];
                                                   }]];
    
    
    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Leave"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self.channel leaveWithCompletion:^(TMResultEnum result) {
                                                           // TODO: let user know completion result
                                                           if (result == TMResultSuccess) {
                                                               [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
                                                           }
                                                       }];
                                                   }]];

    [actionsSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil]];
    
    [self presentViewController:actionsSheet
                       animated:YES
                     completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"message"];
    TMMessage *message = self.messages[indexPath.row];
    
    cell.authorLabel.text = message.author;
    cell.dateLabel.text = message.timestamp;
    cell.bodyLabel.text = message.body;
    [cell layoutIfNeeded];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length == 0) {
        [self.view endEditing:YES];
    } else {
        TMMessage *message = [self.channel.messages createMessageWithBody:textField.text];
        textField.text = @"";
        [self.channel.messages sendMessage:message
                                completion:^(TMResultEnum result) {
                                    if (result == TMResultFailure) {
                                        // TODO: let user know result was failure
                                    }
                                }];
    }
    return YES;
}

#pragma mark - Internal methods

- (void)changeFriendlyName {
    NSString *title = @"Friendly Name";
    NSString *placeholder = @"Friendly Name";
    NSString *initialValue = [self.channel friendlyName];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        if (!newValue || newValue.length == 0) {
            return;
        }

        [self.channel setFriendlyName:newValue
                           completion:^(TMResultEnum result) {
                               if (result == TMResultSuccess) {
                                   [weakSelf displayToastWithMessage:@"Friendly name changed."];
                               } else {
                                   [weakSelf displayToastWithMessage:@"Friendly name could not be changed."];
                               }
                           }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)changeTopic {
    NSString *title = @"Topic";
    NSString *placeholder = @"Topic";
    NSString *initialValue = [[self.channel attributes] objectForKey:@"topic"];
    NSString *actionTitle = @"Set";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        NSMutableDictionary *attributes = [self.channel.attributes mutableCopy];
        if (!attributes) {
            attributes = [NSMutableDictionary dictionary];
        }
        attributes[@"topic"] = newValue;
        [self.channel setAttributes:attributes
                         completion:^(TMResultEnum result) {
                             if (result == TMResultSuccess) {
                                 [weakSelf displayToastWithMessage:@"Topic changed."];
                             } else {
                                 [weakSelf displayToastWithMessage:@"Topic could not be changed."];
                             }
                         }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)inviteMember {
    NSString *title = @"Invite";
    NSString *placeholder = @"User To Invite";
    NSString *initialValue = @"";
    NSString *actionTitle = @"Invite";
    
    __weak __typeof(self) weakSelf = self;
    void (^action)(NSString *) = ^void(NSString *newValue) {
        if (!newValue || newValue.length == 0) {
            return;
        }
        
        [self.channel.members inviteByIdentity:newValue
                                    completion:^(TMResultEnum result) {
                                        if (result == TMResultSuccess) {
                                            [weakSelf displayToastWithMessage:@"User invited."];
                                        } else {
                                            [weakSelf displayToastWithMessage:@"User could not be invited."];
                                        }
                                    }];
    };
    
    [self promptUserWithTitle:title
                  placeholder:placeholder
                 initialValue:initialValue
                  actionTitle:actionTitle
                       action:action];
}

- (void)promptUserWithTitle:(NSString *)title
                placeholder:(NSString *)placeholder
               initialValue:(NSString *)initialValue
                actionTitle:(NSString *)actionTitle
                     action:(void (^)(NSString *))action {
    UIAlertController *dialog = [UIAlertController alertControllerWithTitle:title
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [dialog addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = placeholder;
        textField.text = initialValue ? : @"";
    }];
    
    [dialog addAction:[UIAlertAction actionWithTitle:actionTitle
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *alertAction) {
                                                 UITextField *textField = dialog.textFields[0];
                                                 NSString *newValue = textField.text;
                                                 
                                                 action(newValue);
                                             }]];
    
    [dialog addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                               style:UIAlertActionStyleCancel
                                             handler:nil]];
    
    [self presentViewController:dialog
                       animated:YES
                     completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGFloat keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    self.keyboardAdjustmentConstraint.constant = keyboardHeight;
    [self.view setNeedsLayout];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToBottomMessage];
    });
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardAdjustmentConstraint.constant = 0;
    [self.view setNeedsLayout];
}

- (void)loadMessages {
    [self.messages removeAllObjects];
    [self addMessages:self.channel.messages.allObjects];
}

- (void)addMessages:(NSArray /*<TMMessage *>*/*)messages {
    [self.messages addObjectsFromArray:messages];
    [self sortMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.messages.count > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self scrollToBottomMessage];
            });
        }
    });
}

- (void)scrollToBottomMessage {
    if (self.messages.count == 0) {
        return;
    }
    
    NSIndexPath *bottomMessageIndex = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:bottomMessageIndex atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

- (void)sortMessages {
    [self.messages sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                      ascending:YES]]];
}

#pragma mark - TMChannelDelegate

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelChanged:(TMChannel *)channel {
    [self displayToastWithMessage:[NSString stringWithFormat:@"Channel attributes changed."]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channelDeleted:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (channel == self.channel) {
            [self performSegueWithIdentifier:@"returnToChannels" sender:nil];
        }
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channel:(TMChannel *)channel memberJoined:(TMMember *)member {
    [self displayToastWithMessage:[NSString stringWithFormat:@"%@ joined the channel.", member.identity]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channel:(TMChannel *)channel memberChanged:(TMMember *)member {

}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channel:(TMChannel *)channel memberLeft:(TMMember *)member {
    [self displayToastWithMessage:[NSString stringWithFormat:@"%@ left the channel.", member.identity]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client channel:(TMChannel *)channel messageAdded:(TMMessage *)message {
    [self addMessages:@[message]];
}

@end
